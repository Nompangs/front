import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:nompangs/screens/main/chat_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleQRCode(String code) {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      
      // URL 형식인지 확인
      if (code.startsWith('https://')) {
        final uri = Uri.parse(code);
        final encodedData = uri.queryParameters['data'];
        
        if (encodedData != null) {
          // URL-safe base64 디코딩 및 JSON 파싱
          final decodedData = utf8.decode(base64Url.decode(encodedData));
          
          final characterData = jsonDecode(decodedData);
          print('Parsed character data: $characterData'); // 파싱된 캐릭터 데이터 출력
          
          if (characterData.containsKey('name') && 
              characterData.containsKey('tags')) {
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  characterName: characterData['name'],
                  personalityTags: List<String>.from(characterData['tags']),
                  greeting: characterData['greeting'],
                ),
              ),
            );
            return;
          }
        }
      } else if (code.startsWith('nompangs://')) {
        // nompangs:// 스킴은 시스템이 처리하도록 함
        return;
      }
      
      // URL 형식이 아니거나 데이터가 없는 경우
      _showError('유효하지 않은 QR 코드입니다.');
      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      print('Error parsing QR code: $e'); // 디버깅을 위한 에러 출력
      _showError('QR 코드를 읽을 수 없습니다.');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
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
        title: Text(
          'QR 코드 스캔',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        final cleanCode = barcode.rawValue!.trim();
                        _handleQRCode(cleanCode);
                        break;
                      }
                    }
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.all(50),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: Text(
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
