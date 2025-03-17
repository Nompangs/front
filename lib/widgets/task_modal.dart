import 'package:flutter/material.dart';

class TaskModal extends StatefulWidget {
  final String taskText;
  final Function(String) onTaskUpdated; // Task 업데이트 콜백
  final Function() onTaskSaved; // Task 저장 후 실행할 콜백

  TaskModal({
    required this.taskText,
    required this.onTaskUpdated,
    required this.onTaskSaved,
  });

  @override
  _TaskModalState createState() => _TaskModalState();
}

class _TaskModalState extends State<TaskModal> {
  String _selectedTask = "";

  @override
  void initState() {
    super.initState();
    _selectedTask = widget.taskText; // 초기 Task 설정
  }

  void _updateTask(String newTask) {
    setState(() {
      _selectedTask = newTask; // 선택한 Task로 변경
    });
    widget.onTaskUpdated(newTask); // HomeScreen에도 업데이트
  }

  void _saveTask() {
    print("✅ Task Saved: $_selectedTask");
    Navigator.pop(context); // 모달 닫기
    widget.onTaskSaved(); // Task 저장 후 이동 실행
  }

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
            child: Text(_selectedTask, style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 10),
          Text(
            "AI Summary: This task is related to your schedule and has high priority.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
            ),
            child: Center(
              child: Text("Save Task", style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(height: 20),

          // ✅ "AI Suggested Task" 섹션 복구 ✅
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

  // ✅ 클릭 시 Task 변경 기능 추가 ✅
  Widget _buildTaskItem(String task) {
    return GestureDetector(
      onTap: () {
        _updateTask(task);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _selectedTask == task ? Colors.purpleAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          task,
          style: TextStyle(
            color: _selectedTask == task ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
