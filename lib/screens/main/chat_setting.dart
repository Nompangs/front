// lib/chat_setting.dart

import 'package:flutter/material.dart';

class ChatSettingScreen extends StatelessWidget {
  const ChatSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.purple),
              title: const Text('Voice'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Voice 설정 화면으로 이동 (필요 시 구현)
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text('Language'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Language 설정 화면으로 이동 (필요 시 구현)
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.orange),
              title: const Text('Publicity'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Publicity 설정 화면으로 이동 (필요 시 구현)
              },
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // 전체 텍스트 정리 기능 (필요 시 구현)
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: Text(
                'Clean up the full text',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
