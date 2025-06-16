import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:nompangs/services/character_manager.dart';
import 'package:flutter/rendering.dart';

class CharacterCompleteScreen extends StatefulWidget {
  final String characterName;
  final List<String> personalityTags;
  final String greeting;

  const CharacterCompleteScreen({
    super.key,
    required this.characterName,
    required this.personalityTags,
    required this.greeting,
  });

  @override
  State<CharacterCompleteScreen> createState() => _CharacterCompleteScreenState();
}

class _CharacterCompleteScreenState extends State<CharacterCompleteScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? _qrImageData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _createQrProfile();
  }

  Future<void> _createQrProfile() async {
    if (_loading) return;
    setState(() => _loading = true);
    final data = {
      'personalityProfile': {
        'aiPersonalityProfile': {
          'name': widget.characterName,
          'personalityTraits': widget.personalityTags,
          'summary': widget.greeting,
        },
        'photoAnalysis': {},
        'lifeStory': {},
        'humorMatrix': {},
        'attractiveFlaws': [],
        'contradictions': [],
        'communicationStyle': {},
        'structuredPrompt': widget.greeting,
      }
    };
    try {
      final result = await CharacterManager.instance.saveCharacterForQR(data);
      final qrUrl = result['qrUrl'] as String?;
      
      if (mounted) {
        setState(() {
          _qrImageData = qrUrl;
        });
      }
    } catch (e) {
      print('QR 생성 실패: $e');
      if (mounted) {
        String message = 'QR 생성 실패';
        final match = RegExp(r'(\d{3})').firstMatch(e.toString());
        if (match != null) {
          message = 'QR 생성 실패 (HTTP ${match.group(1)})';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareQRCode() async {
    if (_qrImageData == null) return;
    final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '${widget.characterName} 캐릭터의 QR 코드입니다.');
  }

  // Base64 데이터를 이미지 바이트로 변환하는 헬퍼 함수
  Uint8List? _decodeQrImage(String? base64String) {
    if (base64String == null || !base64String.startsWith('data:image')) {
      return null;
    }
    final uri = Uri.parse(base64String);
    return uri.data?.contentAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final qrBytes = _decodeQrImage(_qrImageData);

    return Scaffold(
      appBar: AppBar(title: const Text('캐릭터 완성')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.characterName,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              RepaintBoundary(
                key: _qrKey,
                child: qrBytes != null
                    ? Image.memory(
                        qrBytes,
                        width: 200,
                        height: 200,
                      )
                    : SizedBox(
                        width: 200,
                        height: 200,
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : const Center(child: Text("QR 생성 실패")),
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _shareQRCode,
                icon: const Icon(Icons.share),
                label: const Text('QR 공유'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final characterData = {
                    'characterName': widget.characterName,
                    'characterHandle': '@User_${DateTime.now().millisecondsSinceEpoch}',
                    'personalityTags': widget.personalityTags,
                    'greeting': widget.greeting,
                  };

                  // UUID를 모르므로 채팅 화면으로 바로 이동하는 기능은 수정이 필요합니다.
                  // 우선은 비활성화하거나 홈으로 이동하도록 처리합니다.
                  // For now, let's just pop the screen
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.chat),
                label: const Text('지금 바로 대화해요'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
