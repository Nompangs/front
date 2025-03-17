import 'package:flutter/material.dart';
import 'task_category_screen.dart';

class TaskPriorityScreen extends StatefulWidget {
  final String taskText;
  final Function(String, int) onPrioritySelected;

  TaskPriorityScreen({
    required this.taskText,
    required this.onPrioritySelected,
  });

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
                      widget.onPrioritySelected(
                        widget.taskText,
                        _selectedPriority,
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
