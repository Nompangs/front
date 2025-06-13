import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ChatSpeakerScreen extends StatefulWidget {
  const ChatSpeakerScreen({Key? key}) : super(key: key);

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  double _lastSoundLevel = 0.0;
  String _statusText = "준비 중...";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onError: (error) => print('STT Error: $error'),
      onStatus: (status) {
        if (status == 'notListening' && mounted) {
           _restartListeningLoop();
        }
      }
    );
    if (available && mounted) {
      _startListening();
    }
  }
  
  void _restartListeningLoop() {
    if (!mounted) return;
    final chatProvider = context.read<ChatProvider>();
    if (!chatProvider.isProcessing && !_isListening) {
      Future.delayed(const Duration(milliseconds: 500), () => _startListening());
    }
  }

  void _startListening() async {
    if (!mounted || _isListening || context.read<ChatProvider>().isProcessing) return;
    
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        print('음성 인식 결과: ${result.recognizedWords}');
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          print('최종 인식 완료: ${result.recognizedWords}');
          _stopListening();
          context.read<ChatProvider>().sendMessage(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ko_KR',
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _lastSoundLevel = level);
      },
    );
  }
  
  void _stopListening() {
    if (!_isListening) return;
    _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    _restartListeningLoop();
    
    if (chatProvider.isProcessing) {
      _statusText = "생각하는 중...";
    } else if (_isListening) {
      _statusText = "귀 기울여 듣고 있어요.";
    } else {
      _statusText = "대화를 시작하려면 탭하세요.";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () {
                      _stopListening();
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      chatProvider.characterName,
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    WhiteEqualizerBars(soundLevel: _lastSoundLevel),
                    const SizedBox(height: 32),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 120),
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

class WhiteEqualizerBars extends StatefulWidget {
  final double soundLevel;
  const WhiteEqualizerBars({Key? key, required this.soundLevel}) : super(key: key);

  @override
  _WhiteEqualizerBarsState createState() => _WhiteEqualizerBarsState();
}

class _WhiteEqualizerBarsState extends State<WhiteEqualizerBars> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 50)),
        vsync: this,
      )..repeat(reverse: true);
    });
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              double baseHeight = 150 - ((index - 2).abs() * 40.0);
              double scale = 0.5 + (widget.soundLevel * 1.5);
              double height = baseHeight * _animations[index].value * scale;
              height = height.clamp(10.0, baseHeight);

              return Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3 + (_animations[index].value * 0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
