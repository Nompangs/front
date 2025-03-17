import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mic_button.dart';
import 'task_priority_screen.dart';
import 'task_category_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? tasks;

  HomeScreen({this.tasks});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.tasks != null) {
      _tasks = List.from(widget.tasks!);
    }
  }

  void _addTask(String taskText) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskPriorityScreen(
              taskText: taskText,
              onPrioritySelected: (taskText, priority) {
                _moveToCategoryScreen(taskText, priority);
              },
            ),
      ),
    );
  }

  void _moveToCategoryScreen(String taskText, int priority) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskCategoryScreen(
              taskText: taskText,
              priority: priority,
              onCategorySelected: (taskText, priority, category) {
                _saveTask(taskText, priority, category);
              },
            ),
      ),
    );
  }

  void _saveTask(String taskText, int priority, String category) {
    setState(() {
      _tasks.add({
        "text": taskText,
        "priority": priority,
        "category": category,
      });
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(tasks: _tasks)),
      (route) => false,
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
      body:
          _tasks.isEmpty
              ? _buildEmptyScreen()
              : TaskListScreen(tasks: _tasks), // 📌 코드 스플리팅 적용
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(onSpeechResult: _addTask),
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
            'Speak and add tasks!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
