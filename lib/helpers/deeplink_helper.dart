import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:nompangs/services/character_manager.dart';

class DeepLinkHelper {
  static Future<Map<String, dynamic>?> processCharacterData(
    String encodedData,
  ) async {
    final String platform = defaultTargetPlatform.name;
    try {
      final decodedData = utf8.decode(base64Url.decode(encodedData));
      final characterData = jsonDecode(decodedData) as Map<String, dynamic>;

      if (!_isValidCharacterData(characterData)) {
        print(
          '[DeepLinkHelper][$platform] processCharacterData: 유효하지 않은 캐릭터 데이터 형식.',
        );
        return null;
      }

      final personaId = await CharacterManager.instance.handleCharacterFromQR(
        characterData,
      );
      print(
        '[DeepLinkHelper][$platform] Firebase에 캐릭터 저장 완료. personaId: $personaId',
      );

      return {
        'characterName': characterData['name'] as String,
        'personalityTags': List<String>.from(characterData['tags'] as List),
        'greeting': characterData['greeting'] as String?,
        'personaId': personaId,
      };
    } catch (e, s) {
      print(
        '[DeepLinkHelper][$platform] processCharacterData: 딥링크 데이터 처리 중 오류: $e',
      );
      print('[DeepLinkHelper][$platform] Stacktrace: $s');
      return null;
    }
  }

  static bool _isValidCharacterData(Map<String, dynamic> data) {
    final isValid =
        data.containsKey('name') &&
        data.containsKey('tags') &&
        data['name'] is String &&
        data['tags'] is List;

    return isValid;
  }

  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    print(
      '[DeepLinkHelper][${defaultTargetPlatform.name}] showError: 오류 메시지: $message',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
