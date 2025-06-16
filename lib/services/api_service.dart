import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 패키지 임포트
import 'package:http/http.dart' as http;
import '../models/personality_profile.dart';

class ApiService {
  // .env 파일에서 QR_API_BASE_URL을 불러옵니다.
  // 만약 값이 없다면 안드로이드 에뮬레이터 기본 주소를 사용합니다.
  final String _baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://10.0.2.2:8080';

  /// 생성된 페르소나 프로필과 사용자 원본 입력값을 서버로 전송하고 QR 코드 URL을 받아옵니다.
  ///
  /// @param generatedProfile 최종 생성된 프로필 Map.
  /// @param userInput 온보딩 과정에서 사용자가 입력한 값들의 Map.
  /// @return 서버 응답 Map (qrUrl 포함).
  Future<Map<String, dynamic>> createQrProfile({
    required Map<String, dynamic> generatedProfile,
    required Map<String, dynamic> userInput,
  }) async {
    final url = Uri.parse('$_baseUrl/createQR');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // 서버의 새로운 API 규격에 맞게 generatedProfile과 userInput을 전송
        body: jsonEncode({
          'generatedProfile': generatedProfile,
          'userInput': userInput,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ API: 새 프로필 생성 및 QR 요청 성공');
        return jsonDecode(response.body);
      } else {
        print('🚨 API Error: ${response.statusCode}');
        print('🚨 Response Body: ${response.body}');
        throw Exception('Failed to create QR profile on server.');
      }
    } catch (e) {
      print('🚨 API Exception: $e');
      throw Exception('Failed to connect to the server.');
    }
  }

  /// UUID를 이용해 서버에서 페르소나 프로필 전체를 불러옵니다.
  ///
  /// @param uuid 페르소나의 고유 ID.
  /// @return `PersonalityProfile` 객체.
  Future<PersonalityProfile> loadProfile(String uuid) async {
    final url = Uri.parse('$_baseUrl/loadQR/$uuid');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('✅ API: 프로필 로드 성공');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // 서버에서 전체 데이터를 받지만, UI에서는 generatedProfile 부분만 사용하므로 해당 부분만 파싱
        if (data.containsKey('generatedProfile')) {
           return PersonalityProfile.fromMap(data['generatedProfile'] as Map<String, dynamic>);
        }
       
        // 호환성을 위해 기존 포맷도 지원
        return PersonalityProfile.fromMap(data);
      } else {
        print('🚨 API Error: ${response.statusCode}');
        print('🚨 Response Body: ${response.body}');
        throw Exception('Failed to load profile from server.');
      }
    } catch (e) {
      print('🚨 API Exception: $e');
      throw Exception('Failed to connect to the server.');
    }
  }
} 