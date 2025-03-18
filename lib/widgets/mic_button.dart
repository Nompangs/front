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

        final result = await _geminiService.analyzeUserInput(_recognizedText);

        if (result["is_event"] == false) {
          _showPopup("❌ This is not an event", "Please try again.");
        } else {
          Map<String, dynamic> event = result["event"];
          widget.onEventDetected(event); // 일정 감지 시 콜백 실행

          String formattedEvent = _formatEvent(event);
          widget.onSpeechResult(formattedEvent); // 이벤트가 감지된 경우만 전달
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

  // Converts event JSON to "Date - Time - Task" format
  String _formatEvent(Map<String, dynamic> event) {
    try {
      final String title = event["title"] ?? "Untitled Task";
      final DateTime startTime = DateTime.parse(event["start"]);
      final String formattedDate = _formatDate(startTime);
      final String formattedTime = _formatTime(startTime);

      return "$formattedDate - $formattedTime - $title";
    } catch (e) {
      print("❌ Error formatting event: $e");
      return "⚠️ Unable to process event";
    }
  }

  // Formats date (Today, Tomorrow, or YYYY-MM-DD)
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "Today";
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1) {
      return "Tomorrow";
    } else {
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    }
  }

  // Formats time (HH:MM)
  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Show a popup message when input is not an event
  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
