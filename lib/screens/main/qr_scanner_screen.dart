import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/api_service.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:provider/provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });
    print('✅ [QR 스캔] 스캔된 원본 데이터: $code');

    try {
      String? parsedUuid;
      if (code.startsWith('nompangs://')) {
        final uri = Uri.parse(code);
        parsedUuid = uri.queryParameters['id'];
        print('✅ [QR 스캔] "nompangs://" 스킴 발견, 파싱된 ID: $parsedUuid');
      } else if (code.startsWith('http')) {
        final uri = Uri.parse(code);
        parsedUuid = uri.queryParameters['id'] ?? uri.queryParameters['roomId'];
        print('✅ [QR 스캔] "http" 스킴 발견, 파싱된 ID: $parsedUuid');
      } else {
        parsedUuid = code;
        print('✅ [QR 스캔] 스킴 없음, 코드를 ID로 사용: $parsedUuid');
      }

      if (parsedUuid == null || parsedUuid.isEmpty) {
        print('🚨 [QR 스캔] 유효한 ID를 파싱하지 못했습니다.');
        throw Exception('QR 코드에서 유효한 ID를 찾을 수 없습니다.');
      }

      final String uuid = parsedUuid;
      print('✅ [QR 스캔] 최종 ID 확정: $uuid. 이제 프로필을 로드합니다.');

      final PersonalityProfile profile = await _apiService.loadProfile(uuid);

      // 프로필 데이터 검증 및 보완
      if (profile.aiPersonalityProfile == null) {
        print('🚨 [QR 스캔] 프로필에 AI 페르소나 정보가 없습니다. 기본값을 사용합니다.');
        throw Exception('프로필 정보가 올바르지 않습니다.');
      }

      final aiProfile = profile.aiPersonalityProfile!;
      final characterName =
          aiProfile.name.isNotEmpty ? aiProfile.name : '이름 없음';
      final characterHandle =
          '@${characterName.toLowerCase().replaceAll(' ', '')}';
      final personalityTags =
          aiProfile.coreValues.isNotEmpty ? aiProfile.coreValues : ['친근한'];
      final greeting = profile.greeting ?? '안녕하세요! 반가워요.';

      print('✅ [QR 스캔] 프로필 데이터 검증 완료:');
      print('   - 이름: $characterName');
      print('   - 핸들: $characterHandle');
      print('   - 성격 태그: $personalityTags');
      print('   - 인사말: $greeting');

      if (mounted) {
        // 프로필 정보를 기반으로 ChatProvider 생성 및 채팅 화면으로 이동
        final characterProfile = {
          'uuid': uuid,
          'greeting': greeting,
          'communicationPrompt': '사용자에게 친절하고 상냥하게 응답해주세요.',
          'initialUserMessage': '친구와 대화하고 싶어.',
          'aiPersonalityProfile': aiProfile,
          'photoAnalysis': {},
          'attractiveFlaws': [],
          'contradictions': [],
          'userInput': {
            'warmth': 5,
            'introversion': 5,
            'competence': 5,
            'humorStyle': '기본',
          },
        };

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => ChatProvider(
                characterProfile: characterProfile,
              ),
              child: const ChatTextScreen(),
            ),
          ),
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      print('🚨 [QR 스캔] 처리 중 에러 발생: $e');
      if (mounted) {
        _showError('프로필을 불러오는데 실패했습니다. QR코드가 올바른지 확인해주세요.');
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    print('🚨 [QR 스캔] 에러 메시지 표시: $message');
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
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleQRCode(barcodes.first.rawValue!);
              }
            },
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }
}
