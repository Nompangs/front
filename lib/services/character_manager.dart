import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/services/firebase_manager.dart';
import 'package:flutter/foundation.dart';

class CharacterManager {
  static CharacterManager? _instance;
  static CharacterManager get instance => _instance ??= CharacterManager._();
  CharacterManager._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// API 기본 URL 가져오기
  static String _getBaseUrl() {
    return dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';
  }

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
  Future<void> _saveQRProfile(
    String personaId,
    Map<String, dynamic> data,
    String userId,
  ) async {
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

  // 🚀 강화된 QR 프로필 저장 (Cloud Function 호출)
  static Future<Map<String, dynamic>> saveCharacterForQR(
    Map<String, dynamic> characterData,
  ) async {
    final url = '${_getBaseUrl()}/createQR';
    debugPrint('🔍 saveCharacterForQR 요청 시작 (최적화 모드):');
    debugPrint('   - URL: $url');
    debugPrint('   - 서버 연결 테스트 중...');

    try {
      // 🔍 서버 연결 테스트 먼저 수행
      final pingResponse = await http
          .get(
            Uri.parse('${_getBaseUrl()}/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout:
                () =>
                    throw const CharacterManagerException(
                      'CONNECTION_FAILED',
                      '서버에 연결할 수 없습니다',
                    ),
          );

      debugPrint('   - 서버 연결 상태: ${pingResponse.statusCode}');

      final requestStartTime = DateTime.now();

      // 🎯 필수 데이터만 추출하여 전송 (데이터 크기 최소화)
      final personalityProfile =
          characterData['personalityProfile'] as Map<String, dynamic>?;
      final aiProfile =
          personalityProfile?['aiPersonalityProfile'] as Map<String, dynamic>?;

      final minimalData = {
        'personalityProfile': {
          'aiPersonalityProfile': {
            'name': aiProfile?['name'] ?? '',
            'objectType': aiProfile?['objectType'] ?? '',
            'personalityTraits':
                (aiProfile?['personalityTraits'] as List?)?.take(3).toList() ??
                [],
            'summary': aiProfile?['summary'] ?? '',
          },
          'greeting': personalityProfile?['greeting'] ?? '',
        },
      };

      final jsonData = jsonEncode(minimalData);
      debugPrint(
        '   - 최적화된 요청 바디 크기: ${jsonData.length} bytes (기존 대비 ~80% 감소)',
      );
      debugPrint('   - 캐릭터 이름: ${aiProfile?['name'] ?? '없음'}');
      debugPrint(
        '   - 요청 데이터: ${jsonData.substring(0, math.min(200, jsonData.length))}...',
      );

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'User-Agent': 'NompangsApp/1.0',
            },
            body: jsonData,
          )
          .timeout(
            const Duration(seconds: 30), // 120초에서 30초로 단축
            onTimeout: () {
              throw const CharacterManagerException(
                'REQUEST_TIMEOUT',
                '요청 시간이 초과되었습니다',
              );
            },
          );

      final requestDuration =
          DateTime.now().difference(requestStartTime).inMilliseconds;
      debugPrint('🌐 서버 요청 완료 (${requestDuration}ms)');
      debugPrint('   - 응답 상태 코드: ${response.statusCode}');
      debugPrint('   - 응답 헤더: ${response.headers}');
      debugPrint('   - 응답 크기: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('✅ saveCharacterForQR 성공:');
        debugPrint('   - UUID: ${responseData['uuid']}');
        debugPrint('   - 버전: ${responseData['version']}');
        debugPrint('   - 서버 처리 시간: ${responseData['performance']?['total']}ms');

        // 🎯 클라이언트에서 QR 코드 생성 (서버 부하 감소)
        final uuid = responseData['uuid'] as String;
        final qrData = 'nompangs://character/$uuid';

        return {
          'uuid': uuid,
          'qrUrl': qrData, // 간단한 딥링크
          'version': responseData['version'],
          'performance': responseData['performance'],
        };
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        debugPrint('❌ saveCharacterForQR 실패: ${response.statusCode}');
        debugPrint('   - 에러 응답: $errorBody');

        // 서버 에러 응답 파싱 시도
        try {
          final errorData = jsonDecode(errorBody);
          final errorCode = errorData['error'] ?? 'SERVER_ERROR';
          final errorMessage = errorData['message'] ?? '서버 오류가 발생했습니다';
          throw CharacterManagerException(errorCode, errorMessage);
        } catch (e) {
          // JSON 파싱 실패 시 기본 에러
          throw CharacterManagerException(
            'SERVER_ERROR',
            'HTTP ${response.statusCode}: 서버에서 오류가 발생했습니다',
          );
        }
      }
    } on CharacterManagerException {
      rethrow; // 이미 처리된 예외는 그대로 전달
    } catch (e) {
      debugPrint('❌ saveCharacterForQR 실패: Exception: $e');
      debugPrint('   - 에러 타입: ${e.runtimeType}');
      debugPrint('   - 에러 스택: ${StackTrace.current}');

      // 에러 타입별 분류
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        throw const CharacterManagerException('TIMEOUT', '요청 시간이 초과되었습니다');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        throw const CharacterManagerException(
          'CONNECTION_FAILED',
          '네트워크 연결에 실패했습니다',
        );
      } else if (e.toString().contains('FormatException')) {
        throw const CharacterManagerException(
          'INVALID_RESPONSE',
          '서버 응답 형식이 올바르지 않습니다',
        );
      } else {
        throw CharacterManagerException(
          'UNKNOWN_ERROR',
          '알 수 없는 오류가 발생했습니다: ${e.toString()}',
        );
      }
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
      DocumentSnapshot doc =
          await _firestore.collection('qr_profiles').doc(personaId).get();
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

  // 🎯 강화된 캐릭터 로드 (서버 API 사용)
  Future<Map<String, dynamic>?> loadCharacterFromServer(
    String personaId,
  ) async {
    final baseUrl = dotenv.env['QR_API_BASE_URL'] ?? 'http://localhost:8080';

    print('🔍 loadCharacterFromServer 요청:');
    print('   - URL: $baseUrl/loadQR/$personaId');
    print('   - UUID: $personaId');

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/loadQR/$personaId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('REQUEST_TIMEOUT'),
          );

      print('🔍 서버 응답:');
      print('   - 상태 코드: ${response.statusCode}');
      print('   - 응답 크기: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // 서버 응답 구조 검증
        if (data['success'] != true) {
          throw Exception(
            'SERVER_ERROR: ${data['message'] ?? 'Unknown server error'}',
          );
        }

        if (!data.containsKey('personalityProfile')) {
          throw Exception('INVALID_RESPONSE: personalityProfile이 없습니다');
        }

        print('✅ 서버에서 캐릭터 로드 완료:');
        print('   - ID: $personaId');
        print('   - 이름: ${data['name']}');
        print('   - 버전: ${data['version'] ?? '알 수 없음'}');
        print('   - 로드 시간: ${data['loadedAt']}');

        return data;
      } else if (response.statusCode == 404) {
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorJson['message'] as String? ?? 'QR 코드에 해당하는 캐릭터를 찾을 수 없습니다';
          print('❌ 캐릭터 없음: $personaId');
          print('   - 메시지: $errorMessage');
          throw CharacterManagerException('PROFILE_NOT_FOUND', errorMessage);
        } catch (e) {
          print('❌ 캐릭터를 찾을 수 없음: $personaId');
          throw CharacterManagerException(
            'PROFILE_NOT_FOUND',
            'QR 코드에 해당하는 캐릭터를 찾을 수 없습니다',
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage =
              errorJson['message'] as String? ?? '유효하지 않은 QR 코드입니다';
          print('❌ 잘못된 요청: $personaId');
          print('   - 메시지: $errorMessage');
          throw CharacterManagerException('INVALID_UUID', errorMessage);
        } catch (e) {
          throw CharacterManagerException(
            'INVALID_UUID',
            '유효하지 않은 QR 코드 형식입니다',
          );
        }
      } else {
        // 기타 HTTP 에러
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          final errorCode =
              errorJson['error'] as String? ?? 'HTTP_${response.statusCode}';
          final errorMessage =
              errorJson['message'] as String? ??
              'HTTP ${response.statusCode} 오류가 발생했습니다';
          throw CharacterManagerException(errorCode, errorMessage);
        } catch (e) {
          throw CharacterManagerException(
            'HTTP_ERROR',
            'HTTP ${response.statusCode} 오류가 발생했습니다',
          );
        }
      }
    } on http.ClientException catch (e) {
      print('❌ 네트워크 에러: $e');
      throw CharacterManagerException('NETWORK_ERROR', '네트워크 연결을 확인해주세요');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      print('❌ loadCharacterFromServer 실패: $errorMessage');

      if (errorMessage.contains('REQUEST_TIMEOUT')) {
        throw CharacterManagerException('TIMEOUT', '요청 시간이 초과되었습니다');
      } else if (errorMessage.contains('SocketException')) {
        throw CharacterManagerException('CONNECTION_FAILED', '서버에 연결할 수 없습니다');
      } else if (errorMessage.contains('FormatException')) {
        throw CharacterManagerException(
          'INVALID_RESPONSE',
          '서버 응답 형식이 올바르지 않습니다',
        );
      } else if (errorMessage.contains('SERVER_ERROR')) {
        final parts = errorMessage.split(': ');
        final serverMessage = parts.length > 1 ? parts[1] : '서버에서 오류가 발생했습니다';
        throw CharacterManagerException('SERVER_ERROR', serverMessage);
      } else if (e is CharacterManagerException) {
        rethrow;
      }

      throw CharacterManagerException(
        'UNKNOWN_ERROR',
        '알 수 없는 오류가 발생했습니다: $errorMessage',
      );
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

// 🚀 새로운 에러 클래스 추가
class CharacterManagerException implements Exception {
  final String code;
  final String message;

  const CharacterManagerException(this.code, this.message);

  @override
  String toString() => 'CharacterManagerException($code): $message';

  // 사용자 친화적 메시지 제공
  String get userFriendlyMessage {
    switch (code) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_FAILED':
        return '인터넷 연결을 확인하고 다시 시도해주세요';
      case 'TIMEOUT':
        return '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요';
      case 'PROFILE_NOT_FOUND':
        return 'QR 코드에 해당하는 캐릭터를 찾을 수 없습니다';
      case 'INVALID_UUID':
        return '유효하지 않은 QR 코드입니다';
      case 'SERVER_ERROR':
        return '서버에 일시적인 문제가 발생했습니다';
      case 'PERMISSION_DENIED':
        return '접근 권한이 없습니다';
      case 'SERVICE_UNAVAILABLE':
        return '서비스가 일시적으로 중단되었습니다';
      case 'VALIDATION_FAILED':
        return '입력 데이터에 문제가 있습니다';
      case 'QR_GENERATION_FAILED':
        return 'QR 코드 생성에 실패했습니다';
      case 'QUOTA_EXCEEDED':
        return '저장 용량이 초과되었습니다';
      case 'INVALID_RESPONSE':
        return '서버 응답에 문제가 있습니다';
      default:
        return message.isNotEmpty ? message : '알 수 없는 오류가 발생했습니다';
    }
  }
}
