import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  Function(String)? _onResult;

  bool get isListening => _speechToText.isListening;
  bool get isNotListening => !_speechToText.isListening;
  bool get isAvailable => _speechEnabled;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    try {
      var microphoneStatus = await Permission.microphone.status;

      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();

        if (!microphoneStatus.isGranted) {
          debugPrint('Microphone permission denied: $microphoneStatus');

          // Check if we need to open settings
          if (microphoneStatus.isPermanentlyDenied) {
            debugPrint('Permission permanently denied. Opening settings...');
            await openAppSettings();
          }
          return false;
        }
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech error: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
        debugLogging: true,
      );

      if (!_speechEnabled) {
        debugPrint('Speech recognition not available on this device');
      }

      return _speechEnabled;
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ru-RU',
  }) async {
    if (!_speechEnabled) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Speech recognition not available');
        return;
      }
    }

    _onResult = onResult;
    _lastWords = '';

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
    _lastWords = '';
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _onResult?.call(_lastWords);

    if (result.finalResult) {
      debugPrint('Final result: $_lastWords');
    }
  }

  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_speechEnabled) {
      await initialize();
    }
    return await _speechToText.locales();
  }

  Future<bool> isLocaleAvailable(String localeId) async {
    final locales = await getAvailableLocales();
    return locales.any((locale) => locale.localeId == localeId);
  }
}
