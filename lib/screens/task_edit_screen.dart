import 'package:flutter/material.dart';
import 'task_priority_screen.dart';
import 'task_category_screen.dart';

class TaskEditScreen extends StatefulWidget {
  final String initialText;
  final int initialPriority;
  final String initialCategory;
  final Function(String, int, String) onSave;
  final Function onDelete;

  TaskEditScreen({
    required this.initialText,
    required this.initialPriority,
    required this.initialCategory,
    required this.onSave,
    required this.onDelete,
  });

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _textController;
  late int _selectedPriority;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedPriority = widget.initialPriority;
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _navigateToPrioritySelection() async {
    int? priority = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskPriorityScreen(
              taskText: _textController.text,
              onPrioritySelected: (text, priority) {
                Navigator.pop(context, priority);
              },
            ),
      ),
    );

    if (priority != null) {
      setState(() {
        _selectedPriority = priority;
      });
    }
  }

  void _navigateToCategorySelection() async {
    String? category = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TaskCategoryScreen(
              taskText: _textController.text,
              priority: _selectedPriority,
              onCategorySelected: (text, priority, category) {
                Navigator.pop(context, category);
              },
            ),
      ),
    );

    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Task"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: "Task Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text("Priority: $_selectedPriority"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _navigateToPrioritySelection,
            ),
            Divider(),
            ListTile(
              title: Text("Category: $_selectedCategory"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _navigateToCategorySelection,
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(
                    _textController.text,
                    _selectedPriority,
                    _selectedCategory,
                  );
                  Navigator.pop(context);
                },
                child: Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
