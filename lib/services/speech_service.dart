import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  Function(String, bool)? onResult; // (인식된 텍스트, 최종 결과 여부)
  Function(bool)? onListeningChange;

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("STT 상태: $status");
        if (status == "done" || status == "notListening") {
          // "notListening"도 고려
          onListeningChange?.call(false);
        }
      },
      onError: (error) {
        print("STT 오류: $error");
        onListeningChange?.call(false);
      },
    );

    if (available) {
      print("마이크 활성화됨 - 한국어 인식 시도");
      onListeningChange?.call(true);

      _speech.listen(
        onResult: (result) {
          print("인식된 단어: ${result.recognizedWords}");
          onResult?.call(result.recognizedWords, result.finalResult);
        },
        localeId: "ko_KR",
        // listenFor: Duration(seconds: 30), // 최대 인식 시간
        // pauseFor: Duration(seconds: 3),   // 말 멈춤 감지 시간
        // partialResults: true,            // 부분 결과 수신 여부
        // cancelOnError: true,             // 오류 발생 시 자동 중지
        // listenMode: stt.ListenMode.confirmation, // 확인 모드 등
      );
    } else {
      print("STT를 사용할 수 없음. 권한을 확인하거나 초기화에 실패했습니다.");
      onListeningChange?.call(false);
    }
  }

  void stopListening() {
    print("마이크 종료 중.");
    _speech.stop();
    onListeningChange?.call(false);
  }

  // 앱 종료 또는 위젯 dispose 시 호출하여 리소스 정리
  void dispose() {
    _speech.cancel(); // 진행 중인 인식 취소
    // _speech.destroy(); // SpeechToText 인스턴스 자체를 완전히 해제 (필요하다면)
    print("SpeechService disposed");
  }
}
