import 'package:flutter/material.dart';

class TaskCategoryScreen extends StatefulWidget {
  final String taskText;
  final int priority;
  final Function(String, int, String) onCategorySelected;

  TaskCategoryScreen({
    required this.taskText,
    required this.priority,
    required this.onCategorySelected,
  });

  @override
  _TaskCategoryScreenState createState() => _TaskCategoryScreenState();
}

class _TaskCategoryScreenState extends State<TaskCategoryScreen> {
  String _selectedCategory = "Work";

  final List<Map<String, dynamic>> _categories = [
    {"name": "Grocery", "color": Colors.green, "icon": Icons.shopping_cart},
    {"name": "Work", "color": Colors.orange, "icon": Icons.work},
    {"name": "Sport", "color": Colors.lightBlue, "icon": Icons.fitness_center},
    {"name": "University", "color": Colors.blue, "icon": Icons.school},
  ];

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

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
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose Category",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _categories.map((category) {
                      return GestureDetector(
                        onTap: () => _selectCategory(category["name"]),
                        child: Container(
                          width: 80,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: category["color"],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(category["icon"], color: Colors.white),
                              SizedBox(height: 5),
                              Text(
                                category["name"],
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.onCategorySelected(
                    widget.taskText,
                    widget.priority,
                    _selectedCategory,
                  );
                },
                child: Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
