import 'package:flutter/material.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;

  TaskListScreen({required this.tasks});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
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
                itemCount: widget.tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskItem(widget.tasks[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, int index) {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TaskEditScreen(
                    initialText: task["text"],
                    initialPriority: task["priority"],
                    initialCategory: task["category"],
                    onSave: (updatedText, updatedPriority, updatedCategory) {
                      setState(() {
                        widget.tasks[index]["text"] = updatedText;
                        widget.tasks[index]["priority"] = updatedPriority;
                        widget.tasks[index]["category"] = updatedCategory;
                      });
                    },
                    onDelete: () {
                      setState(() {
                        widget.tasks.removeAt(index);
                      });
                    },
                  ),
            ),
          );
        },
      ),
    );
  }
}
