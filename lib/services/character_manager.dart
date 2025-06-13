import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/services/firebase_manager.dart';

class CharacterManager {
  static CharacterManager? _instance;
  static CharacterManager get instance => _instance ??= CharacterManager._();
  CharacterManager._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // QR에서 캐릭터 처리 (사용자-캐릭터 관계만 생성)
  Future<String> handleCharacterFromQR(String personaId) async {
    try {
      final user = await FirebaseManager.instance.getCurrentUser();
      if (user == null) throw Exception('사용자 인증 실패');
      await _createUserInteraction(personaId, user.uid);
      return personaId;
    } catch (e) {
      print("❌ 캐릭터 처리 실패: $e");
      rethrow;
    }
  }

  // QR Profile 저장
  Future<void> _saveQRProfile(String personaId, Map<String, dynamic> data, String userId) async {
    await _firestore.collection('qr_profiles').doc(personaId).set({
      'personaId': personaId,
      'name': data['name'],
      'tags': data['tags'],
      'greeting': data['greeting'] ?? '안녕하세요!',
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'totalInteractions': 0,
      'uniqueUsers': 0,
    }, SetOptions(merge: true));
  }

  // 🚀 간소화된 QR 프로필 저장 (Cloud Function 호출)
  Future<Map<String, dynamic>> saveCharacterForQR(Map<String, dynamic> data) async {
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
    final body = jsonEncode(data);
    
    // 🔍 요청 데이터 상세 로깅
    print('🔍 saveCharacterForQR 요청 시작:');
    print('   - URL: $baseUrl/createQR');
    print('   - 요청 데이터 구조:');
    print('     * personalityProfile 존재: ${data.containsKey('personalityProfile')}');
    if (data.containsKey('personalityProfile')) {
      final profile = data['personalityProfile'] as Map<String, dynamic>?;
      print('     * aiPersonalityProfile 존재: ${profile?.containsKey('aiPersonalityProfile') ?? false}');
      if (profile?.containsKey('aiPersonalityProfile') == true) {
        final aiProfile = profile!['aiPersonalityProfile'] as Map<String, dynamic>?;
        print('     * aiPersonalityProfile 내용: ${aiProfile?.keys.toList()}');
      }
    }
    print('   - 전체 데이터 키: ${data.keys.toList()}');
    print('   - 요청 바디 크기: ${body.length} bytes');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/createQR'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      // 🔍 응답 상세 로깅
      print('🔍 서버 응답:');
      print('   - 상태 코드: ${response.statusCode}');
      print('   - 응답 헤더: ${response.headers}');
      print('   - 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        print('✅ 간소화된 캐릭터 생성 완료');
        print('   - UUID: ${json['uuid']}');
        print('   - 메시지: ${json['message']}');
        
        return {
          'uuid': json['uuid'] as String,
          'qrUrl': json['qrUrl'] as String?,
          'message': json['message'] as String?,
        };
      } else {
        // 🔍 에러 상세 분석
        String errorDetails = '';
        try {
          final errorJson = jsonDecode(response.body);
          errorDetails = ' - 에러 상세: $errorJson';
        } catch (e) {
          errorDetails = ' - 응답 바디: ${response.body}';
        }
        
        print('❌ HTTP ${response.statusCode} 에러$errorDetails');
        throw Exception('Failed to create QR profile: ${response.statusCode}$errorDetails');
      }
    } catch (e) {
      print('❌ saveCharacterForQR 실패: $e');
      if (e is http.ClientException) {
        print('   - 네트워크 에러: 서버 연결 실패');
      } else if (e.toString().contains('SocketException')) {
        print('   - 소켓 에러: 서버가 실행되지 않았거나 URL이 잘못됨');
      }
      rethrow;
    }
  }

  // 사용자-캐릭터 관계 생성
  Future<void> _createUserInteraction(String personaId, String userId) async {
    final interactionId = "${userId}_$personaId";
    await _firestore.collection('user_interactions').doc(interactionId).set({
      'userId': userId,
      'personaId': personaId,
      'firstMetAt': FieldValue.serverTimestamp(),
      'lastInteractionAt': FieldValue.serverTimestamp(),
      'totalSessions': 0,
      'totalMessages': 0,
      'isFavorite': false,
    }, SetOptions(merge: true));
  }

  // 🎯 간소화된 Firebase에서 캐릭터 로드
  Future<Map<String, dynamic>?> loadCharacter(String personaId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('qr_profiles').doc(personaId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        print('✅ 캐릭터 로드 완료:');
        print('   - ID: $personaId');
        print('   - 이름: ${data['name']}');
        print('   - 버전: ${data['version'] ?? '알 수 없음'}');
        
        return data;
      }
      return null;
    } catch (e) {
      print("❌ 캐릭터 로드 실패: $e");
      return null;
    }
  }

  // 🎯 간소화된 캐릭터 로드 (서버 API 사용)
  Future<Map<String, dynamic>?> loadCharacterFromServer(String personaId) async {
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
    try {
      final response = await http.get(Uri.parse('$baseUrl/loadQR/$personaId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        
        print('✅ 서버에서 캐릭터 로드 완료:');
        print('   - ID: $personaId');
        print('   - 이름: ${data['name']}');
        print('   - 버전: ${data['version'] ?? '알 수 없음'}');
        
        return data;
      } else if (response.statusCode == 404) {
        print('❌ 캐릭터를 찾을 수 없음: $personaId');
        return null;
      } else {
        throw Exception('Failed to load character: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ loadCharacterFromServer 실패: $e');
      return null;
    }
  }

  // 🎯 캐릭터 기본 정보 확인
  Map<String, dynamic> getCharacterInfo(Map<String, dynamic> characterData) {
    return {
      'name': characterData['name'] ?? '이름 없음',
      'objectType': characterData['objectType'] ?? '알 수 없는 사물',
      'version': characterData['version'] ?? '알 수 없음',
      'personalityTraits': characterData['personalityTraits'] ?? [],
      'summary': characterData['summary'] ?? '',
    };
  }
}