import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mic_button.dart';
import 'task_priority_screen.dart';
import 'task_category_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  HomeScreen({this.tasks = const []});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks); // 기존 Task 리스트 유지
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
      body: _tasks.isEmpty ? _buildEmptyScreen() : _buildTaskListScreen(),
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

  Widget _buildTaskListScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              hintText: "Search for your task...",
              hintStyle: TextStyle(color: Colors.white60),
              prefixIcon: Icon(Icons.search, color: Colors.white60),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                var task = _tasks[index];
                return Card(
                  color: Colors.grey[900],
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(
                      task["text"],
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "🔥 Priority: ${task["priority"]}",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    trailing: Chip(
                      label: Text(
                        task["category"],
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
