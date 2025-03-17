import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        centerTitle: true,
        title: Text(
          'Index',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/profile.jpg'), // 프로필 이미지
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/task_image.png', width: 250), // 중앙 이미지
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900], // 하단 네비게이션 바 배경
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Index', true),
            _buildNavItem(Icons.calendar_today, 'Calendar', false),
            SizedBox(width: 50), // 마이크 버튼 자리 확보
            _buildNavItem(Icons.timer, 'Focus', false),
            _buildNavItem(Icons.person, 'Profile', false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        child: Icon(Icons.mic, color: Colors.white, size: 28),
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.white : Colors.white60),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
