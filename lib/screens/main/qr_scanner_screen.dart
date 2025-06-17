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

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChangeNotifierProvider(
                  create:
                      (_) => ChatProvider(
                        uuid: uuid,
                        characterName:
                            profile.aiPersonalityProfile?.name ?? '이름 없음',
                        characterHandle:
                            '@${profile.aiPersonalityProfile?.name?.toLowerCase().replaceAll(' ', '') ?? 'unknown'}',
                        personalityTags:
                            profile.aiPersonalityProfile?.coreValues ??
                            ['친구같은'],
                        greeting: profile.greeting,
                      ),
                  child: const ChatTextScreen(),
                ),
          ),
        );
        // 채팅방에서 돌아왔을 때만 다시 스캔 가능
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
