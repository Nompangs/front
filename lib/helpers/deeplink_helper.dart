import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/services/character_manager.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/api_service.dart';

class DeepLinkHelper {
  static Future<Map<String, dynamic>?> processCharacterData(
    String uuid,
  ) async {
    final platform = defaultTargetPlatform.name;
    final apiService = ApiService();

    try {
      final profile = await apiService.loadProfile(uuid);

      final characterProfileMap = profile.toMap();

      characterProfileMap['personalityTags'] = profile.aiPersonalityProfile?.coreValues.isNotEmpty == true
          ? profile.aiPersonalityProfile!.coreValues
          : ['친구'];

      print('[DeepLinkHelper][$platform] 프로필 로드 및 데이터 변환 성공 (uuid: $uuid)');
      return characterProfileMap;

    } catch (e, s) {
      print('[DeepLinkHelper][$platform] 데이터 처리 중 오류: $e');
      print('[DeepLinkHelper][$platform] Stacktrace: $s');
      return null;
    }
  }

  static bool _isValidCharacterData(Map<String, dynamic> data) {
    final isValid =
        data.containsKey('name') &&
        data.containsKey('tags') &&
        data.containsKey('personaId') &&
        data['name'] is String &&
        data['tags'] is List &&
        data['personaId'] is String;

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
