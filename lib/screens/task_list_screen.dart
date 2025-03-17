import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  TaskListScreen({required this.tasks});

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(), // iOS 스타일 스크롤 반응 적용
              child: Column(
                children: tasks.map((task) => _buildTaskItem(task)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(task["text"], style: TextStyle(color: Colors.white)),
        subtitle: Text(
          "🔥 Priority: ${task["priority"]}",
          style: TextStyle(color: Colors.redAccent),
        ),
        trailing: Chip(
          label: Text(task["category"], style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueAccent,
        ),
      ),
    );
  }
}
