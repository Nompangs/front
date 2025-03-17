import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mic_button.dart';
import '../widgets/task_modal.dart';
import 'task_priority_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _taskText = "";
  bool _isModalVisible = false; // 중복 실행 방지
  bool _isTaskSaved = false; // Task 저장 여부 확인

  void _updateTask(String newText) {
    setState(() {
      _taskText = newText;
      _isTaskSaved = false;
    });

    if (!_isModalVisible) {
      _showTaskModal();
    }
  }

  void _showTaskModal() {
    setState(() {
      _isModalVisible = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => TaskModal(
            taskText: _taskText,
            onTaskUpdated: (updatedTask) {
              setState(() {
                _taskText = updatedTask; // Task 변경 반영
              });
            },
            onTaskSaved: _moveToPriorityScreen,
          ),
    ).then((_) {
      setState(() {
        _isModalVisible = false;
      });
    });
  }

  void _moveToPriorityScreen() {
    setState(() {
      _isTaskSaved = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskPriorityScreen(taskText: _taskText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            'Speak and add tasks!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(onSpeechResult: _updateTask),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
