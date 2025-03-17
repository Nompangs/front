import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/gpt_service.dart';

class MicButton extends StatefulWidget {
  final Function(String) onSpeechResult;

  MicButton({required this.onSpeechResult});

  @override
  _MicButtonState createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  final SpeechService _speechService = SpeechService();
  final GPTService _gptService = GPTService();
  bool _isListening = false;
  String _recognizedText = ""; // 음성 인식된 텍스트 저장

  @override
  void initState() {
    super.initState();
    _speechService.onResult = (text, finalResult) async {
      setState(() {
        _recognizedText = text;
      });

      if (finalResult) {
        print("음성 입력 완료: $_recognizedText"); // 로그 출력
        widget.onSpeechResult("GPT 처리 중..."); // GPT 처리 중 표시
        String gptResponse = await _gptService.sendToGPT(
          _recognizedText,
        ); // GPT 호출
        widget.onSpeechResult(gptResponse); // GPT 응답을 화면에 표시
      }
    };

    _speechService.onListeningChange = (listening) {
      setState(() => _isListening = listening);
    };
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stopListening();
    } else {
      _speechService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _isListening ? Colors.redAccent : Colors.purpleAccent,
      child: Icon(Icons.mic, color: Colors.white, size: 28),
      onPressed: _toggleListening,
    );
  }
}
