import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'chat_text_screen.dart'; // ChatTextScreen으로 돌아가기 위해 임포트
import 'package:lottie/lottie.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';

class ChatSpeakerScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> characterProfile;

  const ChatSpeakerScreen({
    super.key,
    required this.conversationId,
    required this.characterProfile,
  });

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .initializeChat(widget.conversationId, widget.characterProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return _ChatSpeakerScreenContent(
          provider: provider,
          characterProfile: widget.characterProfile,
        );
      },
    );
  }
}

class _ChatSpeakerScreenContent extends StatelessWidget {
  final ChatProvider provider;
  final Map<String, dynamic> characterProfile;

  const _ChatSpeakerScreenContent({
    required this.provider,
    required this.characterProfile,
  });

  @override
  Widget build(BuildContext context) {
    final characterName = provider.characterName;
    
    ImageProvider displayImageProvider;
    final photoBase64 = characterProfile['photoBase64'] as String?;
    final userPhotoPath = characterProfile['userPhotoPath'] as String?;
    final imageUrl = characterProfile['imageUrl'] as String?;

    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final imageBytes = base64Decode(photoBase64);
        displayImageProvider = MemoryImage(imageBytes);
      } catch (e) {
        debugPrint("Base64 디코딩 실패, 폴백 이미지 사용: $e");
        displayImageProvider = const AssetImage('assets/logo.png');
      }
    } else if (userPhotoPath != null && userPhotoPath.isNotEmpty && File(userPhotoPath).existsSync()) {
      displayImageProvider = FileImage(File(userPhotoPath));
    } else if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      displayImageProvider = NetworkImage(imageUrl);
    } else {
      final placeholderIndex = Random().nextInt(19) + 1;
      displayImageProvider = AssetImage(
        'assets/ui_assets/object_png/obj ($placeholderIndex).png',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                _TopBar(
                  characterName: characterName,
                  onTextModePressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatTextScreen(
                          conversationId: provider.conversationId!,
                          characterProfile: characterProfile,
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: _Visualizer(
                      isListening: provider.isListening,
                      isSpeaking: provider.isSpeaking,
                      imageProvider: displayImageProvider,
                    ),
                  ),
                ),
                _BottomMicButton(
                  isListening: provider.isListening,
                  onPressed: () {
                    if (provider.isListening) {
                      provider.stopAudioStreaming();
                    } else {
                      provider.startAudioStreaming();
                    }
                    },
                  ),
              ],
            ),
            if (provider.isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      SizedBox(height: 16),
                      Text("음성을 처리하는 중...", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String characterName;
  final VoidCallback onTextModePressed;

  const _TopBar({required this.characterName, required this.onTextModePressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(characterName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: onTextModePressed,
          ),
        ],
      ),
    );
  }
}

class _Visualizer extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final ImageProvider imageProvider;

  const _Visualizer({
    required this.isListening,
    required this.isSpeaking,
    required this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isListening || isSpeaking)
          Lottie.asset(
            'assets/ui_assets/speaking_animation.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          )
        else
          CircleAvatar(
            backgroundImage: imageProvider,
            radius: 100,
          ),
        const SizedBox(height: 24),
        Text(
          isListening ? "듣고 있어요..." : (isSpeaking ? "말하는 중..." : "마이크를 눌러 대화를 시작하세요"),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

class _BottomMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _BottomMicButton({required this.isListening, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: IconButton(
        icon: Icon(
          isListening ? Icons.mic_off : Icons.mic,
          color: isListening ? Colors.red : Colors.blue,
        ),
        iconSize: 64,
        onPressed: onPressed,
      ),
    );
  }
}

// 이퀄라이저 위젯 (시각적 요소, 기능은 동일)
class WhiteEqualizerBars extends StatelessWidget {
  final double soundLevel;
  const WhiteEqualizerBars({Key? key, required this.soundLevel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 간단한 시각적 표현
    return SizedBox(
      height: 50,
      width: 100,
      child: Center(
        child:
            soundLevel > 0.1
                ? const Icon(Icons.graphic_eq, color: Colors.white, size: 40)
                : const Icon(Icons.mic_none, color: Colors.white70, size: 40),
      ),
    );
  }
}
