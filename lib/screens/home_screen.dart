import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isListening = false;
  String _text = "Press the mic to start talking...";
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _initializeSTT();
  }

  // STT 초기화
  void _initializeSTT() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("STT Status: $status");
        if (status == "done") {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        print("STT Error: $error");
        setState(() {
          _isListening = false;
          _text = "Error: Speech recognition failed.";
        });
      },
    );

    if (!available) {
      setState(() {
        _text = "STT를 사용할 수 없습니다.";
      });
    }
  }

  // 마이크 버튼 클릭 시 음성 인식 시작
  void _toggleListening() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize();

        if (available) {
          setState(() {
            _isListening = true;
            _text = "Listening..."; // STT 시작 시 메시지 표시
          });

          _speech.listen(
            onResult: (result) {
              setState(() {
                _text = result.recognizedWords; // 실시간 업데이트
              });

              if (result.finalResult) {
                _speech.stop();
                _sendToGPT(_text);
              }
            },
          );
        } else {
          setState(() {
            _text = "STT를 사용할 수 없습니다.";
          });
        }
      } catch (e) {
        setState(() {
          _text = "Error: $e";
        });
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }
  }

  // GPT API 호출
  Future<void> _sendToGPT(String inputText) async {
    setState(() {
      _text = "Processing your request..."; // 로딩 메시지 표시
    });

    final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    final String apiUrl = "https://api.openai.com/v1/chat/completions";

    if (apiKey.isEmpty) {
      setState(() {
        _text = "Error: API Key is missing.";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": inputText},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String gptResponse = responseData['choices'][0]['message']['content'];
        setState(() {
          _text = gptResponse;
        });
      } else {
        setState(() {
          _text = "GPT 응답 오류: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _text = "네트워크 오류 발생: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {},
            ),
            centerTitle: true,
            title: Text(
              'Index',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            actions: [
              CircleAvatar(backgroundImage: AssetImage('assets/profile.png')),
              SizedBox(width: 16),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/task_image.png', width: 250),
              SizedBox(height: 20),
              Text(
                'What do you want to do today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _text,
                style: TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.grey[900],
            shape: CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Index', true),
                _buildNavItem(Icons.calendar_today, 'Calendar', false),
                SizedBox(width: 50),
                _buildNavItem(Icons.timer, 'Focus', false),
                _buildNavItem(Icons.person, 'Profile', false),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.purpleAccent,
            child: Icon(Icons.mic, color: Colors.white, size: 28),
            onPressed: _toggleListening,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.white : Colors.white60),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
