import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  Function(String, bool)? onResult; // (인식된 텍스트, 최종 결과 여부)
  Function(bool)? onListeningChange;

  Future<void> startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("STT 상태: $status"); // 터미널 로그 출력
        if (status == "done") {
          onListeningChange?.call(false);
        }
      },
      onError: (error) {
        print("STT 오류: $error");
        onListeningChange?.call(false);
      },
    );

    if (available) {
      print("마이크 활성화됨");
      onListeningChange?.call(true);

      _speech.listen(
        onResult: (result) {
          print(
            "인식된 단어: ${result.recognizedWords} (최종: ${result.finalResult})",
          );
          onResult?.call(result.recognizedWords, result.finalResult);
        },
      );
    } else {
      print("STT를 사용할 수 없음.");
      onListeningChange?.call(false);
    }
  }

  void stopListening() {
    print("마이크 종료됨.");
    _speech.stop();
    onListeningChange?.call(false);
  }
}
