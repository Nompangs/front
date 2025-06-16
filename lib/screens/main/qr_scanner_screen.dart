import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/api_service.dart';

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

    // QR 코드가 감지되면 다시 스캔하지 않도록 즉시 처리 중 상태로 설정
    setState(() {
      _isProcessing = true;
    });
    print('✅ QR Code detected, handling with code: $code');

    try {
      String? uuid;
      // 딥링크 URL 형식인지 확인하고 파싱합니다.
      if (code.startsWith('nompangs://')) {
        final uri = Uri.parse(code);
        uuid = uri.queryParameters['id'];
      } else {
        // URL 형식이 아니라면, 코드가 UUID 자체라고 가정합니다.
        uuid = code;
      }

      if (uuid == null) {
        throw Exception('QR 코드에서 유효한 ID를 찾을 수 없습니다.');
      }

      final PersonalityProfile profile = await _apiService.loadProfile(uuid);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(profile: profile),
          ),
        );
      }
    } catch (e) {
      print('🚨 QR 스캔 처리 실패: $e');
      if (mounted) {
        _showError('프로필을 불러오는데 실패했습니다.');
        // 에러 발생 시 스캔 재개를 위해 상태 복원
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'QR 코드 스캔',
          style: TextStyle(color: Colors.white),
        ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 16),
                    Text('QR 코드 처리 중...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}