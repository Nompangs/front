import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/character_manager.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;
  String? _lastScannedCode; // 중복 스캔 방지용

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    print('[QRScannerScreen][${defaultTargetPlatform.name}] initState');
  }

  @override
  void dispose() {
    print('[QRScannerScreen][${defaultTargetPlatform.name}] dispose');
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String code) async {
    if (!mounted || _isProcessing) return;

    // 중복 스캔 방지
    if (_lastScannedCode == code) {
      print('[QRScannerScreen] 중복 스캔 무시: $code');
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    try {
      // QR 코드로 읽은 문자열(code)이 바로 uuid라고 가정합니다.
      final String uuid = code.trim();
      debugPrint('🔍 QR 스캔된 UUID: $uuid');

      if (uuid.isEmpty) {
        throw const CharacterManagerException('INVALID_UUID', '빈 QR 코드입니다');
      }

      // UUID 형식 간단 검증 (36자 길이와 하이픈 위치)
      if (!_isValidUUIDFormat(uuid)) {
        throw const CharacterManagerException(
          'INVALID_UUID',
          '올바르지 않은 QR 코드 형식입니다',
        );
      }

      // 서버에서 캐릭터 데이터 로드
      final data = await CharacterManager.instance.loadCharacterFromServer(
        uuid,
      );

      if (data == null) {
        throw const CharacterManagerException(
          'PROFILE_NOT_FOUND',
          '캐릭터 데이터를 찾을 수 없습니다',
        );
      }

      // 🎯 로드된 데이터 상세 확인
      debugPrint('🔍 서버에서 로드된 데이터 확인:');
      debugPrint('   - 성공 여부: ${data['success']}');
      debugPrint('   - 이름: ${data['name']}');
      debugPrint('   - 버전: ${data['version']}');

      // personalityProfile 구조 검증
      if (!data.containsKey('personalityProfile')) {
        throw const CharacterManagerException(
          'INVALID_RESPONSE',
          'PersonalityProfile 데이터가 없습니다',
        );
      }

      final personalityProfileData =
          data['personalityProfile'] as Map<String, dynamic>;
      debugPrint(
        '   - PersonalityProfile 키: ${personalityProfileData.keys.toList()}',
      );

      final profile = PersonalityProfile.fromMap(personalityProfileData);

      // 🎯 PersonalityProfile 변환 결과 확인
      debugPrint('🔍 PersonalityProfile 변환 결과:');
      debugPrint('   - 매력적 결함 개수: ${profile.attractiveFlaws.length}');
      debugPrint('   - 모순적 특성 개수: ${profile.contradictions.length}');
      debugPrint('   - AI 프로필 이름: ${profile.aiPersonalityProfile?.name}');
      debugPrint('   - UUID: ${profile.uuid}');

      if (mounted) {
        // 성공적으로 로드되었음을 사용자에게 피드백
        _showSuccess(
          '${profile.aiPersonalityProfile?.name ?? '캐릭터'}와 연결되었습니다!',
        );

        await Future.delayed(const Duration(milliseconds: 500)); // 피드백 시간

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(profile: profile)),
        );
      }
    } on CharacterManagerException catch (e) {
      print('🚨 CharacterManagerException: ${e.code} - ${e.message}');
      if (mounted) {
        _showError(e.userFriendlyMessage, e.code);
        _resetScanning();
      }
    } catch (e) {
      print('🚨 예상치 못한 QR 스캔 오류: $e');
      if (mounted) {
        _showError('예상치 못한 오류가 발생했습니다', 'UNEXPECTED_ERROR');
        _resetScanning();
      }
    }
  }

  bool _isValidUUIDFormat(String uuid) {
    // UUID v4 형식: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (36자)
    if (uuid.length != 36) return false;
    if (uuid[8] != '-' || uuid[13] != '-' || uuid[18] != '-' || uuid[23] != '-')
      return false;

    // 기본적인 16진수 문자 검증
    final cleanUuid = uuid.replaceAll('-', '');
    return RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(cleanUuid);
  }

  void _resetScanning() {
    setState(() {
      _isProcessing = false;
      _lastScannedCode = null;
    });
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    print(
      '[QRScannerScreen_showSuccess][${defaultTargetPlatform.name}] 성공: $message',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message, String errorCode) {
    if (!mounted) return;
    print(
      '[QRScannerScreen_showError][${defaultTargetPlatform.name}] $errorCode: $message',
    );

    // 에러 유형에 따른 아이콘 선택
    IconData errorIcon;
    Color backgroundColor;

    switch (errorCode) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_FAILED':
        errorIcon = Icons.wifi_off;
        backgroundColor = Colors.orange;
        break;
      case 'PROFILE_NOT_FOUND':
        errorIcon = Icons.search_off;
        backgroundColor = Colors.blue;
        break;
      case 'INVALID_UUID':
        errorIcon = Icons.qr_code_scanner;
        backgroundColor = Colors.purple;
        break;
      case 'TIMEOUT':
        errorIcon = Icons.access_time;
        backgroundColor = Colors.amber;
        break;
      case 'SERVER_ERROR':
      case 'SERVICE_UNAVAILABLE':
        errorIcon = Icons.cloud_off;
        backgroundColor = Colors.red;
        break;
      default:
        errorIcon = Icons.error;
        backgroundColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(errorIcon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '다시 시도',
          textColor: Colors.white,
          onPressed: _resetScanning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('QR 코드 스캔', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (!mounted || _isProcessing) {
                      return;
                    }
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final String scannedCode = barcodes.first.rawValue!;
                      _handleQRCode(scannedCode.trim());
                    }
                  },
                ),
                // 스캔 영역 표시
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isProcessing ? Colors.blue : Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // 처리 중 오버레이
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'QR 코드 처리 중...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  _isProcessing ? '캐릭터 정보를 불러오는 중...' : '캐릭터 QR 코드를 스캔해주세요',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (_isProcessing) const SizedBox(height: 8),
                if (_isProcessing)
                  const Text(
                    '잠시만 기다려주세요',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
