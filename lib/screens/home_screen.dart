import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mic_button.dart';
import '../widgets/task_modal.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _taskText = "";
  bool _taskGenerated = false;
  bool _isModalVisible = false; // 모달이 실행 중인지 확인하는 변수

  void _updateTask(String newText) {
    setState(() {
      _taskText = newText;
      _taskGenerated = true;
    });

    // 모달이 이미 실행 중이면 다시 띄우지 않음
    if (!_isModalVisible) {
      _showTaskModal();
    }
  }

  void _showTaskModal() {
    setState(() {
      _isModalVisible = true; // 모달 실행 상태 업데이트
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TaskModal(taskText: _taskText),
    ).then((_) {
      // 모달이 닫히면 실행 상태 초기화
      setState(() {
        _isModalVisible = false;
      });
    });
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
