import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:fllama/io/fllama_bindings_generated.dart';
import 'package:fllama/fllama_io.dart';
import 'package:fllama/fllama_universal.dart';

// Inner workings - No need for direct access, hence private
class _IsolateTranslateRequest {
  final int id;
  final FllamaTranslateRequest request;

  _IsolateTranslateRequest(this.id, this.request);
}

class _IsolateTranslateResponse {
  final int id;
  final String? result;

  _IsolateTranslateResponse(this.id, this.result);
}

int _nextTranslateRequestId = 0; // Unique ID for each request
final Map<int, Completer<String?>> _isolateTranslateRequests =
    <int, Completer<String?>>{};

Future<SendPort> _helperTranslateIsolateSendPort = (() async {
  final completer = Completer<SendPort>();
  final receivePort = ReceivePort();

  await Isolate.spawn(_fllamaTranslateIsolate, receivePort.sendPort);

  receivePort.listen((dynamic data) {
    if (data is SendPort) {
      completer.complete(data);
    } else if (data is _IsolateTranslateResponse) {
      final Completer<String?>? requestCompleter =
          _isolateTranslateRequests.remove(data.id);

      if (requestCompleter == null) {
        // ignore: avoid_print
        print(
            '[fllama] fllama_io_translate ERROR: No completer found for request ID: ${data.id}');
        return;
      }
      requestCompleter.complete(data.result);
    } else {
      // ignore: avoid_print
      print(
          '[fllama] fllama_io_translate ERROR: Unexpected data from isolate: $data');
    }
  });

  return completer.future;
}());

/// Runs one encoder-decoder translation and returns the output text, or null
/// when the native side refused the call (unreadable model, a decoder-only
/// model where a seq2seq one is required, input longer than one batch).
///
/// Runs on a dedicated helper isolate: the native call is synchronous and a
/// sentence takes tens to hundreds of milliseconds, which must not land on
/// the UI thread. Calls are serialised native-side; the first call on a
/// model path pays its load, later calls reuse the cached model.
Future<String?> fllamaTranslate(FllamaTranslateRequest request) async {
  final SendPort helperIsolateSendPort = await _helperTranslateIsolateSendPort;

  final requestId = _nextTranslateRequestId++;
  final isolateRequest = _IsolateTranslateRequest(requestId, request);

  final completer = Completer<String?>();
  _isolateTranslateRequests[requestId] = completer;
  helperIsolateSendPort.send(isolateRequest);
  return completer.future;
}

// Background isolate entry function for translation
void _fllamaTranslateIsolate(SendPort mainIsolateSendPort) {
  final helperReceivePort = ReceivePort();
  mainIsolateSendPort.send(helperReceivePort.sendPort);

  helperReceivePort.listen((dynamic data) {
    if (data is _IsolateTranslateRequest) {
      final request = _toNativeTranslateRequest(data.request);

      final Pointer<Char> answer =
          fllamaBindings.fllama_translate(request.ref);
      final String? result = answer == nullptr
          ? null
          : answer.cast<Utf8>().toDartString();
      if (answer != nullptr) {
        fllamaBindings.fllama_translate_free(answer);
      }
      mainIsolateSendPort.send(_IsolateTranslateResponse(data.id, result));

      // Clean-up allocated memory
      calloc.free(request.ref.input);
      calloc.free(request.ref.model_path);
      calloc.free(request);
    }
  });
}

Pointer<fllama_translate_request> _toNativeTranslateRequest(
    FllamaTranslateRequest dartRequest) {
  final nativeRequest = calloc<fllama_translate_request>();

  nativeRequest.ref.input = dartRequest.input.toNativeUtf8().cast<Char>();
  nativeRequest.ref.model_path =
      dartRequest.modelPath.toNativeUtf8().cast<Char>();
  nativeRequest.ref.max_tokens = dartRequest.maxTokens;
  nativeRequest.ref.num_threads = dartRequest.numThreads;

  return nativeRequest;
}
