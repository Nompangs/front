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
      // --- uitgebreide logging START ---
      print('--- [API 상세 로그 시작] ---');
      print('1. 요청 URL: $url');

      // 1. 요청 데이터 확인
      print('2. 전송될 데이터 (가공 전):');
      print('   - generatedProfile: $generatedProfile');
      print('   - userInput: $userInput');

      // 2. 최종 요청 본문 확인
      final requestBody = jsonEncode({
        'generatedProfile': generatedProfile,
        'userInput': userInput,
      });
      print('3. 최종 요청 본문 (JSON 인코딩 후): $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // 3. 서버의 순수 응답 확인
      print('4. 서버 응답 (가공 전):');
      print('   - Status Code: ${response.statusCode}');
      print('   - Headers: ${response.headers}');
      print('   - Raw Body: ${response.body}');
      print('--- [API 상세 로그 종료] ---');
      // --- uitgebreide logging EINDE ---

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
    final url = Uri.parse('$_baseUrl/getProfile/$uuid');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return PersonalityProfile.fromMap(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load profile from server.');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server.');
    }
  }
} 