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
  late MobileScannerController controller;
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

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
    
    setState(() { _isProcessing = true; });

    try {
      // QR 코드로 읽은 문자열(code)이 바로 uuid라고 가정합니다.
      // 만약 URL 형태라면 파싱이 필요합니다. 
      // 예: final uuid = Uri.parse(code).queryParameters['id'];
      final String uuid = code; 

      final PersonalityProfile profile = await _apiService.loadProfile(uuid);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // ChatScreen에 profile 객체 하나만 전달합니다.
            builder: (context) => ChatScreen(profile: profile),
          ),
        );
      }
    } catch (e) {
      print('🚨 QR 스캔 처리 실패: $e');
      if (mounted) {
        _showError('프로필을 불러오는데 실패했습니다.');
        setState(() {
          _isProcessing = false; // 에러 발생 시 스캔 재개를 위해 상태 복원
        });
      }
    } 
    // 성공적으로 네비게이션하면 이 화면은 dispose되므로 finally 블록은 불필요.
  }

  void _showError(String message) {
    if (!mounted) return;
    print('[QRScannerScreen_showError][${defaultTargetPlatform.name}] 오류: $message');
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
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final String scannedCode = barcodes.first.rawValue!;
                      // 스캔이 완료되면 즉시 처리 상태로 변경하여 중복 스캔 방지
                      setState(() {
                        _isProcessing = true;
                      });
                      _handleQRCode(scannedCode.trim());
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
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          SizedBox(height: 16),
                          Text('QR 코드 처리 중...', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              '캐릭터 QR 코드를 스캔해주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}