import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nompangs/services/character_manager.dart';
import 'package:nompangs/utils/persona_utils.dart';

class DeepLinkHelper {
  // 딥링크 캐릭터 데이터 처리
  static Future<Map<String, dynamic>?> processCharacterData(String encodedData) async {
    try {
      final decodedData = utf8.decode(base64Url.decode(encodedData));
      final characterData = jsonDecode(decodedData);

      if (!_isValidCharacterData(characterData)) {
        return null;
      }

      // Firebase에 저장
      final personaId = await CharacterManager.instance.handleCharacterFromQR(characterData);

      // 채팅 화면용 데이터 반환
      return {
        'characterName': characterData['name'],
        'personalityTags': List<String>.from(characterData['tags']),
        'greeting': characterData['greeting'],
        'personaId': personaId,
      };
    } catch (e) {
      print('딥링크 처리 오류: $e');
      return null;
    }
  }

  // 캐릭터 데이터 유효성 검증
  static bool _isValidCharacterData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
        data.containsKey('tags') &&
        data['name'] is String &&
        data['tags'] is List;
  }

  // 에러 메시지 표시
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}