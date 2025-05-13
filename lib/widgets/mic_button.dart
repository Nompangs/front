import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/gemini_service.dart';
import 'dart:convert';

class MicButton extends StatefulWidget {
  final Function(String) onSpeechResult;
  final Function(Map<String, dynamic>) onEventDetected; // 일정 감지 시 콜백 추가

  MicButton({required this.onSpeechResult, required this.onEventDetected});

  @override
  _MicButtonState createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  final SpeechService _speechService = SpeechService();
  final GeminiService _geminiService = GeminiService();
  bool _isListening = false;
  String _recognizedText = "";

  @override
  void initState() {
    super.initState();
    _speechService.onResult = (text, finalResult) async {
      setState(() {
        _recognizedText = text;
      });

      if (finalResult) {
        print("🎤 Speech input completed: $_recognizedText");
        // Call the callback to pass the recognized text to the parent
        if (_recognizedText.isNotEmpty) {
          widget.onSpeechResult(_recognizedText);
        }
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
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _isListening ? Colors.redAccent : Colors.purpleAccent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.mic, color: Colors.white, size: 28),
        onPressed: _toggleListening,
      ),
    );
  }

}
