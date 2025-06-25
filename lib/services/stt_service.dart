import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  
  // 콜백 함수 정의
  final Function(String text, bool isFinal) onResult;
  final Function(String error) onError;

  // 생성자에서 콜백 함수를 받음
  SttService({required this.onResult, required this.onError});

  Future<void> initialize() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => onError("STT Error: ${error.errorMsg}"),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
      if (!_speechEnabled) {
        onError("The user has denied the use of speech recognition.");
      }
      debugPrint("✅ SttService 초기화 완료: $_speechEnabled");
    } catch (e) {
      debugPrint("❌ SttService 초기화 실패: $e");
      onError("STT initialization failed: $e");
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    onResult(result.recognizedWords, result.finalResult);
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      debugPrint("⚠️ SttService가 초기화되지 않아 듣기를 시작할 수 없습니다.");
      return;
    }
    if (_speechToText.isListening) {
      debugPrint("이미 듣고 있는 중입니다.");
      return;
    }
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'ko_KR', // 한국어 설정
        listenFor: const Duration(minutes: 5), // 최대 듣기 시간
        pauseFor: const Duration(seconds: 5), // 멈춤 감지 시간
      );
      debugPrint("🎤 STT 듣기 시작...");
    } catch (e) {
      debugPrint("❌ STT 듣기 시작 실패: $e");
      onError("Failed to start listening: $e");
    }
  }

  Future<void> stopListening() async {
    if (!_speechEnabled || !_speechToText.isListening) {
      return;
    }
    try {
      await _speechToText.stop();
      debugPrint("🛑 STT 듣기 중지.");
    } catch (e) {
      debugPrint("❌ STT 듣기 중지 실패: $e");
      onError("Failed to stop listening: $e");
    }
  }

  void dispose() {
    // speech_to_text 라이브러리는 별도의 dispose 메서드를 제공하지 않지만
    // stopListening을 호출하여 리소스를 해제할 수 있습니다.
    stopListening();
  }
}
