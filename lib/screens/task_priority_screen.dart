import 'package:flutter/material.dart';
import 'task_category_screen.dart';

class TaskPriorityScreen extends StatefulWidget {
  final String taskText;

  TaskPriorityScreen({required this.taskText});

  @override
  _TaskPriorityScreenState createState() => _TaskPriorityScreenState();
}

class _TaskPriorityScreenState extends State<TaskPriorityScreen> {
  int _selectedPriority = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Task Priority",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(4, (index) {
                  int priority = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _selectedPriority == priority
                                ? Colors.purpleAccent
                                : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.flag, color: Colors.white),
                          Text(
                            "$priority",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 선택 후 "Choose Category" 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TaskCategoryScreen(
                                taskText: widget.taskText,
                                priority: _selectedPriority,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                    ),
                    child: Text("Save", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
