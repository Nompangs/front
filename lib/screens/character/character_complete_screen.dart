import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/services/character_manager.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/rendering.dart';

class CharacterCompleteScreen extends StatefulWidget {
  final String characterName;
  final List<String> personalityTags;
  final String greeting;

  const CharacterCompleteScreen({
    Key? key,
    required this.characterName,
    required this.personalityTags,
    required this.greeting,
  }) : super(key: key);

  @override
  State<CharacterCompleteScreen> createState() => _CharacterCompleteScreenState();
}

class _CharacterCompleteScreenState extends State<CharacterCompleteScreen> {
  final GlobalKey _qrKey = GlobalKey();
  String? _qrUuid;
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
      final uuid = result['uuid'] as String;
      final message = result['message'] as String?;
      
      // 🎯 간소화 정보 로깅
      if (message != null) {
        print('✅ $message');
      }
      
      if (mounted) setState(() => _qrUuid = uuid);
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

  String get _qrData => _qrUuid != null ? 'nompangs://character?id=$_qrUuid' : '';

  Future<void> _shareQRCode() async {
    if (_qrUuid == null) return;
    final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: '${widget.characterName} 캐릭터의 QR 코드입니다.');
  }

  @override
  Widget build(BuildContext context) {
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
                child: _qrUuid != null
                    ? QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 200,
                      )
                    : SizedBox(
                        width: 200,
                        height: 200,
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox.shrink(),
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
                    'personaId': _qrUuid, // QR 생성 시 받은 ID
                  };

                  Navigator.pushNamed(
                    context,
                    '/chat/$_qrUuid',
                    arguments: characterData,
                  );
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
