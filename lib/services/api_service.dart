import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 패키지 임포트
import 'package:http/http.dart' as http;
import '../models/personality_profile.dart';
import 'auth_service.dart';

class ApiService {
  // .env 파일에서 QR_API_BASE_URL을 불러옵니다.
  // 만약 값이 없다면 안드로이드 에뮬레이터 기본 주소를 사용합니다.
  final String _baseUrl =
      dotenv.env['QR_API_BASE_URL'] ?? 'http://10.0.2.2:8080';
  final AuthService _authService = AuthService();

  /// 생성된 페르소나 프로필과 사용자 원본 입력값을 서버로 전송하고 QR 코드 URL을 받아옵니다.
  ///
  /// @param generatedProfile 최종 생성된 프로필 Map.
  /// @param userInput 온보딩 과정에서 사용자가 입력한 값들의 Map.
  /// @return 서버 응답 Map (qrUrl 포함).
  Future<Map<String, dynamic>> createQrProfile({
    required Map<String, dynamic> generatedProfile,
    required Map<String, dynamic> userInput,
  }) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/createQR');
    print('✅ [QR 생성 요청] API Service: createQrProfile 호출됨');
    print('   - 요청 URL: $url');
    print('   - 사용자 ID: ${_authService.currentUser?.uid}');
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
        headers: headers,
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
      } else if (response.statusCode == 401) {
        print('🚨 [QR 생성 실패] 인증 에러');
        throw Exception('Authentication required');
      } else {
        print('🚨 API Error: ${response.statusCode}');
        print('🚨 Response Body: ${response.body}');
        throw Exception('Failed to create QR profile on server.');
      }
    } catch (e) {
      print('🚨 API Exception: $e');
      print('   - 요청 URL: $url');
      throw Exception('Failed to connect to the server.');
    }
  }

  /// UUID를 이용해 서버에서 페르소나 프로필 전체를 불러옵니다.
  ///
  /// @param uuid 페르소나의 고유 ID.
  /// @return `PersonalityProfile` 객체.
  Future<PersonalityProfile> loadProfile(String uuid) async {
    final url = Uri.parse('$_baseUrl/loadQR/$uuid');
    print('✅ [QR 로드 요청] API Service: loadProfile 호출됨');
    print('   - 요청 URL: $url');
    try {
      // ---  loadProfile 상세 로깅 START ---
      print('--- [loadProfile 상세 로그 시작] ---');
      print('1. 프로필 요청 URL: $url');

      final response = await http.get(url);

      print('2. 서버 응답 (가공 전):');
      print('   - Status Code: ${response.statusCode}');
      print('   - Raw Body: ${response.body}');
      print('--- [loadProfile 상세 로그 종료] ---');
      // ---  loadProfile 상세 로깅 END ---

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // generatedProfile 내부의 aiPersonalityProfile 확인
        final hasProfile =
            data.containsKey('generatedProfile') &&
            data['generatedProfile'] != null &&
            data['generatedProfile'].containsKey('aiPersonalityProfile') &&
            data['generatedProfile']['aiPersonalityProfile'] != null;

        if (!hasProfile) {
          print('🚨 [QR 로드 실패] 필수 프로필 데이터 누락');
          throw Exception('Invalid profile data: Missing required fields');
        }

        // 응답 구조를 PersonalityProfile 형식에 맞게 변환
        final Map<String, dynamic> profileData = {
          'uuid': data['uuid'],
          'aiPersonalityProfile':
              data['generatedProfile']['aiPersonalityProfile'],
        };

        print('✅ [QR 로드 성공] 파싱된 데이터: $profileData');
        return PersonalityProfile.fromMap(profileData);
      } else {
        print(
          '🚨 [QR 로드 실패] 서버 에러: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to load profile from server.');
      }
    } catch (e) {
      print('🚨 [QR 로드 실패] API Exception: $e');
      print('   - 요청 URL: $url');
      throw Exception('Failed to connect to the server or parse profile.');
    }
  }

  /// 인증된 HTTP 요청을 보내는 헬퍼 메서드
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// 사용자가 깨운 사물들의 목록을 가져옵니다.
  Future<List<Map<String, dynamic>>> getAwokenObjects() async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/objects/awoken');
    print('✅ [사물 목록 요청] API Service: getAwokenObjects 호출됨');
    print('   - 요청 URL: $url');
    print('   - 사용자 ID: ${_authService.currentUser?.uid}');

    try {
      print('--- [getAwokenObjects 상세 로그 시작] ---');
      print('1. 사물 목록 요청 URL: $url');

      final response = await http.get(url, headers: headers);

      print('2. 서버 응답 (가공 전):');
      print('   - Status Code: ${response.statusCode}');
      print('   - Raw Body: ${response.body}');
      print('--- [getAwokenObjects 상세 로그 종료] ---');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ [사물 목록 로드 성공] 파싱된 데이터: $data');
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        print('🚨 [사물 목록 로드 실패] 인증 에러');
        throw Exception('Authentication required');
      } else {
        print('🚨 [사물 목록 로드 실패] 서버 에러: ${response.statusCode}');
        throw Exception('Failed to load awoken objects from server.');
      }
    } catch (e) {
      print('🚨 [사물 목록 로드 실패] API Exception: $e');
      print('   - 요청 URL: $url');
      throw Exception('Failed to connect to the server or parse objects.');
    }
  }

  Future<Map<String, dynamic>> getQrProfileDetail(String uuid) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('$_baseUrl/qr_profiles/$uuid');
    print('✅ [프로필 상세 요청] API Service: getQrProfileDetail 호출됨');
    print('   - 요청 URL: $url');
    try {
      final response = await http.get(url, headers: headers);
      print('   - Status Code: ${response.statusCode}');
      print('   - Raw Body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load profile detail');
      }
    } catch (e) {
      print('🚨 [프로필 상세 로드 실패] $e');
      throw Exception('Failed to connect to the server or parse detail.');
    }
  }
}
