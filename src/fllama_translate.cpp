#include "fllama_translate.h"

#include "llama.h"
#include "common.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace {

// One cached model+context, keyed by path. Translation is called per
// sentence, so reloading a ~250MB GGUF each call would dominate the run;
// with the cache the load is paid once per process (or per model swap).
// The mutex serialises whole calls: a llama_context is not thread-safe,
// and translation calls are short.
struct TranslatorState {
  std::string path;
  llama_model *model = nullptr;
  llama_context *ctx = nullptr;

  void release() {
    if (ctx != nullptr) {
      llama_free(ctx);
      ctx = nullptr;
    }
    if (model != nullptr) {
      llama_model_free(model);
      model = nullptr;
    }
    path.clear();
  }
};

std::mutex g_mutex;
TranslatorState g_state;
std::once_flag g_backend_once;

bool ensure_loaded(const char *model_path, int n_threads) {
  if (g_state.model != nullptr && g_state.path == model_path) {
    llama_set_n_threads(g_state.ctx, n_threads, n_threads);
    return true;
  }
  g_state.release();

  std::call_once(g_backend_once, [] { llama_backend_init(); });

  llama_model_params mparams = llama_model_default_params();
  mparams.n_gpu_layers = 0; // a 247M encoder-decoder is a CPU workload
  llama_model *model = llama_model_load_from_file(model_path, mparams);
  if (model == nullptr) {
    return false;
  }
  if (!llama_model_has_encoder(model)) {
    // Wrong model file: this entry point is for seq2seq models only. The
    // decoder-only path is fllama_inference.
    llama_model_free(model);
    return false;
  }

  llama_context_params cparams = llama_context_default_params();
  // HebrewBerry-class models are trained at 512; sentence-level inputs are
  // far shorter. One ubatch must hold the whole encoder input.
  cparams.n_ctx = 512;
  cparams.n_batch = 512;
  cparams.n_ubatch = 512;
  cparams.n_threads = n_threads;
  cparams.n_threads_batch = n_threads;
  llama_context *ctx = llama_init_from_model(model, cparams);
  if (ctx == nullptr) {
    llama_model_free(model);
    return false;
  }

  g_state.path = model_path;
  g_state.model = model;
  g_state.ctx = ctx;
  return true;
}

} // namespace

extern "C" {

FFI_PLUGIN_EXPORT char *
fllama_translate(struct fllama_translate_request request) {
  if (request.input == nullptr || request.model_path == nullptr) {
    return nullptr;
  }
  const int max_tokens = request.max_tokens > 0 ? request.max_tokens : 256;
  const int n_threads = request.num_threads > 0 ? request.num_threads : 4;

  std::lock_guard<std::mutex> lock(g_mutex);
  if (!ensure_loaded(request.model_path, n_threads)) {
    return nullptr;
  }
  llama_context *ctx = g_state.ctx;
  llama_model *model = g_state.model;
  const llama_vocab *vocab = llama_model_get_vocab(model);

  // Every call starts from a clean sequence; nothing carries over between
  // sentences.
  llama_memory_clear(llama_get_memory(ctx), true);

  // add_special=true appends the T5 EOS to the encoder input — the same
  // `... + ["</s>"]` the CTranslate2 reference path builds by hand.
  std::vector<llama_token> enc_tokens =
      common_tokenize(ctx, request.input, /*add_special=*/true,
                      /*parse_special=*/true);
  if (enc_tokens.empty() ||
      (int)enc_tokens.size() > (int)llama_n_batch(ctx)) {
    return nullptr;
  }
  if (llama_encode(ctx, llama_batch_get_one(enc_tokens.data(),
                                            (int)enc_tokens.size())) != 0) {
    return nullptr;
  }

  llama_token decoder_start = llama_model_decoder_start_token(model);
  if (decoder_start == LLAMA_TOKEN_NULL) {
    decoder_start = llama_vocab_bos(vocab);
  }

  // Greedy decode. The reference pipeline uses beam 4; greedy is the v1
  // trade for running inside one synchronous call, and the quality delta is
  // measured (not assumed) against the CT2 path in the app repo's bench.
  llama_sampler_chain_params sp = llama_sampler_chain_default_params();
  sp.no_perf = true;
  llama_sampler *sampler = llama_sampler_chain_init(sp);
  llama_sampler_chain_add(sampler, llama_sampler_init_greedy());

  std::vector<llama_token> out_tokens;
  llama_token cur = decoder_start;
  for (int i = 0; i < max_tokens; i++) {
    if (llama_decode(ctx, llama_batch_get_one(&cur, 1)) != 0) {
      llama_sampler_free(sampler);
      return nullptr;
    }
    cur = llama_sampler_sample(sampler, ctx, -1);
    if (llama_vocab_is_eog(vocab, cur)) {
      break;
    }
    out_tokens.push_back(cur);
  }
  llama_sampler_free(sampler);

  std::string text =
      common_detokenize(ctx, out_tokens, /*special=*/false);
  char *result = (char *)std::malloc(text.size() + 1);
  if (result == nullptr) {
    return nullptr;
  }
  std::memcpy(result, text.c_str(), text.size() + 1);
  return result;
}

FFI_PLUGIN_EXPORT void fllama_translate_free(char *result) {
  std::free(result);
}

} // extern "C"
