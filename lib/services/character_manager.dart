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
    print('✅ [캐릭터 매니저] handleCharacterFromQR 호출됨. Persona ID: $personaId');
    try {
      final user = await FirebaseManager.instance.getCurrentUser();
      if (user == null) throw Exception('사용자 인증 실패');
      print('   - 현재 사용자 UID: ${user.uid}');
      await _createUserInteraction(personaId, user.uid);
      print('   - 사용자-캐릭터 관계 생성 완료');
      return personaId;
    } catch (e) {
      print("❌ [캐릭터 매니저] handleCharacterFromQR 실패: $e");
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
    print('✅ [캐릭터 매니저] saveCharacterForQR 호출됨');
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
    final url = '$baseUrl/createQR';
    final body = jsonEncode(data);

    // 🔍 요청 데이터 상세 로깅
    print('🔍 [QR 생성 요청]');
    print('   - URL: $url');
    print('   - 전송 데이터 (일부): name=${data.dig('personalityProfile', 'aiPersonalityProfile', 'name')}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      // 🔍 응답 상세 로깅
      print('🔍 [QR 생성 응답]');
      print('   - 상태 코드: ${response.statusCode}');
      print('   - 응답 바디: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        print('✅ [캐릭터 매니저] 간소화된 캐릭터 생성 성공. UUID: ${json['uuid']}');
        
        return {
          'uuid': json['uuid'] as String,
          'qrUrl': json['qrUrl'] as String?,
          'message': json['message'] as String?,
        };
      } else {
        print('❌ [캐릭터 매니저] saveCharacterForQR 실패: HTTP ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to create QR profile: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [캐릭터 매니저] saveCharacterForQR 실패: $e');
      if (e is http.ClientException) {
        print('   - 네트워크 에러일 가능성이 높습니다. 서버($url)가 실행 중인지, 디바이스가 동일 네트워크에 있는지 확인해주세요.');
      } else if (e.toString().contains('SocketException')) {
        print('   - 소켓 에러: 서버($url)에 연결할 수 없습니다. URL이나 포트가 올바른지 확인해주세요.');
      }
      rethrow;
    }
  }

  // 사용자-캐릭터 관계 생성
  Future<void> _createUserInteraction(String personaId, String userId) async {
    final now = FieldValue.serverTimestamp();

    // 상호작용 문서에 대한 참조
    final interactionRef = _firestore
        .collection('qr_profiles')
        .doc(personaId)
        .collection('interactions')
        .doc(userId);

    // QR 프로필 문서에 대한 참조
    final qrProfileRef = _firestore.collection('qr_profiles').doc(personaId);

    return _firestore.runTransaction((transaction) async {
      final interactionSnap = await transaction.get(interactionRef);

      if (!interactionSnap.exists) {
        // 이 유저는 처음 상호작용함
        print('   - 첫 상호작용 유저($userId)입니다. 상호작용 기록을 추가하고 카운트를 증가시킵니다.');
        transaction.set(interactionRef, {
          'userId': userId,
          'firstSeenAt': now,
          'lastSeenAt': now,
          'interactionCount': 1,
        });

        // uniqueUsers와 totalInteractions 카운트 증가
        transaction.update(qrProfileRef, {
          'totalInteractions': FieldValue.increment(1),
          'uniqueUsers': FieldValue.increment(1),
        });
      } else {
        // 재상호작용 유저
        print('   - 재상호작용 유저($userId)입니다. 상호작용 기록을 업데이트합니다.');
        transaction.update(interactionRef, {
          'lastSeenAt': now,
          'interactionCount': FieldValue.increment(1),
        });

        // totalInteractions 카운트만 증가
        transaction.update(qrProfileRef, {
          'totalInteractions': FieldValue.increment(1),
        });
      }
    });
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

  // 사용자 정의 헬퍼 함수
  Future<String?> getPersonaIdFromQr(String qrData) async {
    try {
      final uri = Uri.parse(qrData);
      return uri.queryParameters['id'];
    } catch (e) {
      print("QR 데이터 파싱 실패: $e");
      return null;
    }
  }
}

// Map에서 안전하게 중첩된 값에 접근하기 위한 확장 함수
extension MapDig on Map {
  dynamic dig(String key1, String key2, String key3) {
    try {
      return this[key1][key2][key3];
    } catch (e) {
      return null;
    }
  }
}