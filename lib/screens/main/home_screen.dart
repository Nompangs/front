import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nompangs/widgets/bottom_nav_bar.dart';
import 'package:nompangs/widgets/mic_button.dart';
import 'package:nompangs/services/gemini_service.dart';
import 'package:nompangs/screens/character/character_create_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? tasks;

  HomeScreen({this.tasks});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];
  late GeminiService _geminiService;
  List<ChatMessage> _chatMessages = [];
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    if (widget.tasks != null) {
      _tasks = List.from(widget.tasks!);
    }
    _geminiService = GeminiService();
    flutterTts = FlutterTts();
    _initTts();
  }

  _initTts() async {
    await flutterTts.setLanguage("ko-KR");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _handleSpeechInput(String inputText) async {
    setState(() {
      _chatMessages.add(ChatMessage(text: inputText, isUser: true));
    });

    final response = await _geminiService.analyzeUserInput(inputText);
    if (response != null && response["response"] != null) {
      final aiResponseText = response["response"];
      setState(() {
        _chatMessages.add(ChatMessage(text: aiResponseText, isUser: false));
      });
      if (aiResponseText.isNotEmpty) {
        await flutterTts.speak(aiResponseText);
      }
    } else {
      const String errorMessage = "⚠️ 오류: 응답을 받을 수 없습니다.";
      setState(() {
        _chatMessages.add(ChatMessage(text: errorMessage, isUser: false));
      });
      await flutterTts.speak(errorMessage);
      print("⚠️ Error: Gemini response is null.");
    }
  }

  void _showResponseDialog(String response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Gemini Response"),
          content: Text(response),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Index',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterCreateScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/qr-scanner');
            },
          ),
          CircleAvatar(backgroundImage: AssetImage('assets/profile.png')),
          SizedBox(width: 16),
        ],
      ),
      body: _chatMessages.isEmpty ? _buildEmptyScreen() : _buildChatScreen(),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(
        onSpeechResult: _handleSpeechInput,
        onEventDetected: (event) {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
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
            'Speak and interact with your AI friend!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: EdgeInsets.all(16.0),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[_chatMessages.length - 1 - index];
              return _buildChatMessageBubble(message);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              setState(() {
                _chatMessages.clear();
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Clear Chat', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.0),
        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurpleAccent : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
            bottomLeft: message.isUser ? Radius.circular(20.0) : Radius.circular(0),
            bottomRight: message.isUser ? Radius.circular(0) : Radius.circular(20.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.isUser ? "You" : "AI Friend",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
