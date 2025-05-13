import 'package:flutter/material.dart';
import 'package:saydo/widgets/task_modal.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mic_button.dart';
import 'task_priority_screen.dart';
import 'task_category_screen.dart';
import 'task_list_screen.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? tasks;

  HomeScreen({this.tasks});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];
  late GeminiService _geminiService;
  String _geminiResponse = "";

  @override
  void initState() {
    super.initState();
    if (widget.tasks != null) {
      _tasks = List.from(widget.tasks!);
    }
    _geminiService = GeminiService();
  }

  void _handleSpeechInput(String inputText) async {
    final response = await _geminiService.analyzeUserInput(inputText);
    if (response != null && response["response"] != null) {
      setState(() {
        _geminiResponse = response["response"];
      });
    } else {
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
          CircleAvatar(backgroundImage: AssetImage('assets/profile.png')),
          SizedBox(width: 16),
        ],
      ),
      body: _geminiResponse.isEmpty ? _buildEmptyScreen() : _buildResponseScreen(),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(
        onSpeechResult: _handleSpeechInput, // Handles STT input
        onEventDetected: (event) {}, // Provide an empty callback
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

  Widget _buildResponseScreen() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/cat_icon.png', width: 100, height: 100, 
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.pets, size: 80, color: Colors.purpleAccent);
              }
            ),
            SizedBox(height: 20),
            Text(
              _geminiResponse,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                setState(() {
                  _geminiResponse = "";
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('Clear', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
