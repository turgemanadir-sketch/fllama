#ifndef FLLAMA_TRANSLATE_H
#define FLLAMA_TRANSLATE_H

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#else
#define EMSCRIPTEN_KEEPALIVE
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Encoder-decoder (T5/MT5) translation. fllama's chat path wraps llama.cpp's
// server_context, which has no encoder pass at all — a seq2seq GGUF loaded
// through it decodes against a null encoder state and emits garbage. This
// entry point drives llama_encode + a greedy decode loop directly, which is
// all a translation model needs.
struct fllama_translate_request {
  char *input;      // Required: source text, direction tag included
                    // (e.g. ">>heb<< Hello" / ">>eng<< שלום").
  char *model_path; // Required: T5/MT5-architecture .gguf file path.
  int max_tokens;   // Optional: max tokens to generate. <= 0 means 256.
  int num_threads;  // Optional: threads for encode+decode. <= 0 means 4.
};

// Synchronous; call from a worker isolate/thread. Returns a heap-allocated
// UTF-8 string that MUST be released with fllama_translate_free, or NULL on
// failure (unreadable model, not an encoder-decoder model, batch overflow).
// The loaded model is cached per path, so the first call pays the load and
// subsequent calls only run the ~tens-of-ms encode/decode.
EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT char *
fllama_translate(struct fllama_translate_request request);

EMSCRIPTEN_KEEPALIVE FFI_PLUGIN_EXPORT void fllama_translate_free(char *result);

#ifdef __cplusplus
}
#endif
#endif // FLLAMA_TRANSLATE_H
