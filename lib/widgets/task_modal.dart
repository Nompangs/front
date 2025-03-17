import 'package:flutter/material.dart';

class TaskModal extends StatelessWidget {
  final String taskText;

  TaskModal({required this.taskText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add Task",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(taskText, style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 10),
          Text(
            "AI Summary: This task is related to your schedule and has high priority.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              print("✅ Task Saved: $taskText");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Center(
              child: Text("Save Task", style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(height: 20),

          // "AI Suggested Task" Section
          Text(
            "AI Suggested Task",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "These tasks are recommended based on your past schedules and availability.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 10),
          _buildTaskItem("Today - 10:00 - Meeting"),
          _buildTaskItem("Today - 12:00 - Lunch with Mom"),
          _buildTaskItem("Tomorrow - 19:00 - Workout"),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String task) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(task, style: TextStyle(color: Colors.white)),
    );
  }
}
