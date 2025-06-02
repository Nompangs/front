import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/services/character_manager.dart';
import 'package:nompangs/utils/persona_utils.dart';

class CharacterCompleteScreen extends StatelessWidget {
  final String characterName;
  final List<String> personalityTags;
  final String greeting;

  const CharacterCompleteScreen({
    Key? key,
    required this.characterName,
    required this.personalityTags,
    required this.greeting,
  }) : super(key: key);

  String _generateQRData() {
    // 랜덤 roomId 생성 (예: 6자리 숫자)
    final roomId = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // 캐릭터 정보를 JSON 형식으로 변환
    final characterData = {
      'name': characterName,
      'tags': personalityTags,
      'greeting': greeting,
    };
    
    // URL에 캐릭터 정보를 URL-safe base64로 인코딩하여 추가
    final jsonString = jsonEncode(characterData);
    final encodedData = base64Url.encode(utf8.encode(jsonString));
    
    final webPageUrl = 'https://invitepage.netlify.app/?roomId=$roomId&data=$encodedData'; // 여기에 실제 웹페이지 주소를 입력
    print('Generated QR data for web: $webPageUrl');
    return webPageUrl;
  }

  Future<void> _downloadAndShareQRCode(BuildContext context) async {
    try {
      await _saveCharacterToFirebase(); // firebase에 저장

      final qrData = _generateQRData();
      print('Generated QR data: $qrData'); // 디버깅을 위한 데이터 출력
      
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/qr_code.png';
      final file = File(path);

      final imageData = await qrPainter.toImageData(200.0);
      if (imageData == null) return;

      final buffer = imageData.buffer;
      await file.writeAsBytes(
        buffer.asUint8List(imageData.offsetInBytes, imageData.lengthInBytes),
      );

      await Share.shareXFiles(
        [XFile(path)],
        text: '$characterName 캐릭터의 QR 코드입니다.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR 코드 저장 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<void> _saveCharacterToFirebase() async {
    try {
      final characterData = {
        'name': characterName,
        'tags': personalityTags,
        'greeting': greeting,
      };

      final personaId = await CharacterManager.instance.handleCharacterFromQR(characterData);
      print('✅ 캐릭터가 Firebase에 저장됨: $personaId');
    } catch (e) {
      print('❌ Firebase 저장 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('--- CharacterCompleteScreen build method called ---'); // ★ 빌드 메소드 호출 확인 로그
    print('Character Name: $characterName, Tags: $personalityTags, Greeting: $greeting'); // 전달받은 데이터 확인 로그

    // QR 데이터 생성 시도 및 로그 출력 (build 메소드 내에서 미리 호출하여 확인)
    final qrDataForCheck = _generateQRData();
    print('QR Data generated in build method for check: $qrDataForCheck');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // 캐릭터 이미지
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '😊',
                      style: TextStyle(fontSize: 100),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 캐릭터 이름
                Text(
                  characterName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // 성격 태그
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: personalityTags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                // 인사말
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
                // QR 코드
                QrImageView(
                  data: _generateQRData(),
                  version: QrVersions.auto,
                  size: 200.0,
                  // errorStateBuilder 추가 (QR 생성 오류 시 확인용)
                  errorStateBuilder: (cxt, err) {
                    print('Error generating QR Image: $err');
                    return const Center(
                      child: Text(
                        'QR 코드 생성 오류',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // QR 코드 다운로드 버튼
                ElevatedButton.icon(
                  onPressed: () => _downloadAndShareQRCode(context),
                  icon: const Icon(Icons.download),
                  label: const Text('QR 코드 다운로드'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 대화하기 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatTextScreen(
                          characterName: characterName,
                          characterHandle: '@User_${DateTime.now().millisecondsSinceEpoch}',
                          personalityTags: personalityTags,
                          greeting: greeting,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('지금 바로 대화해요'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 