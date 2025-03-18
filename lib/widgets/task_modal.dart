import 'package:flutter/material.dart';
import 'dart:convert';

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
    _selectedTask = _formatEventText(widget.taskText); // JSON 데이터를 변환하여 저장
  }

  // event JSON -> readable format
  String _formatEventText(String eventJson) {
    try {
      // Markdown 코드 블록 제거 (```json ... ```)
      eventJson =
          eventJson.replaceAll("```json", "").replaceAll("```", "").trim();

      // 일정이 아닌 경우 예외 처리
      if (!eventJson.startsWith("{")) {
        print("⚠️ Not a valid event JSON: $eventJson");
        return eventJson; // 그대로 출력
      }

      // JSON 파싱 (예외 발생 가능)
      final Map<String, dynamic> event = jsonDecode(eventJson);
      final String title = event["title"] ?? "Untitled Task";
      final DateTime startTime = DateTime.parse(event["start"]);
      final String formattedDate = _formatDate(startTime);
      final String formattedTime = _formatTime(startTime);

      return "$formattedDate - $formattedTime - $title";
    } catch (e) {
      print("❌ Error formatting event: $e");
      return "⚠️ Unable to process event"; // 오류 발생 시 안전한 메시지 반환
    }
  }

  // 보기 쉽게 오늘, 내일로 변경
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return "Today";
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1) {
      return "Tomorrow";
    } else {
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    }
  }

  // format time
  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
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
            child: Text(
              _selectedTask, // 변환된 "날짜 - 시간 - 할 일" 형식으로 표시
              style: TextStyle(color: Colors.white),
            ),
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

  // 클릭 시 Task 변경 기능 추가
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
