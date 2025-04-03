// import 'dart:ffi';
// import 'dart:io';
//
// final DynamicLibrary whisperLib = Platform.isAndroid
//     ? DynamicLibrary.open("libwhisper.so") // Android
//     : DynamicLibrary.process(); // macOS/iOS
//
// typedef WhisperTranscribeNative = Pointer<Utf8> Function(Pointer<Utf8>);
// typedef WhisperTranscribeDart = Pointer<Utf8> Function(Pointer<Utf8>);
//
// final WhisperTranscribeDart whisperTranscribe =
// whisperLib.lookupFunction<WhisperTranscribeNative, WhisperTranscribeDart>(
//     "whisper_transcribe");
