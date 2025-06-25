import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';

class ChatSpeakerScreen extends StatefulWidget {
  const ChatSpeakerScreen({super.key});

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen> {
  // --- UI 상태 ---
  // 이 화면의 모든 상태는 이제 ChatProvider가 관리합니다.
  // 따라서 이 클래스 내의 상태 변수는 대부분 필요 없습니다.

  // 예시: 간단한 시각적 피드백을 위한 변수
  double _soundLevelForUi = 0.0;

  @override
  void initState() {
    super.initState();
    // 화면이 시작될 때 TTS가 재생 중일 수 있으므로 중지합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().stopTts();
    });
  }

  // --- 비즈니스 로직은 모두 Provider로 이동 ---
  // _activateMicrophone, _sendFinalResult 등은 모두 제거됩니다.

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        130,
        135,
        139,
      ).withOpacity(0.7),
      body: SafeArea(
        child: Column(
          children: [
            // --- 상단 네비게이션 ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // 화면을 닫기 전에 스트리밍을 중단합니다.
                      chatProvider.stopAudioStreaming();
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // --- 메인 콘텐츠 ---
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chatProvider.characterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // TODO: 실제 오디오 레벨에 따른 시각화 구현 필요
                  WhiteEqualizerBars(soundLevel: _soundLevelForUi),
                  const SizedBox(height: 32),
                  Text(
                    _determineStatusText(chatProvider), // 상태 텍스트
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  // --- 마이크 버튼 ---
                  _buildMicButton(chatProvider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _determineStatusText(ChatProvider provider) {
    if (provider.isProcessing) return "생각 중이에요...";
    if (provider.sttError != null) return "오류가 발생했어요. 다시 시도해주세요.";
    if (provider.isListening) return "듣고 있어요...";
    if (provider.isSpeaking) return "말하는 중...";
    return "버튼을 길게 누르고 말하기";
  }

  Widget _buildMicButton(ChatProvider provider) {
    // GestureDetector를 사용하여 길게 누르는 동작을 감지
    return GestureDetector(
      onLongPressStart: (_) {
        provider.startAudioStreaming();
      },
      onLongPressEnd: (_) {
        provider.stopAudioStreaming();
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: provider.isListening ? Colors.redAccent : Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Icon(
            provider.isListening
                ? Icons.mic
                : (provider.isSpeaking ? Icons.volume_up : Icons.mic_off),
            color: Colors.white,
            size: 50),
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
