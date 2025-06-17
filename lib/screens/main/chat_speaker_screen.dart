import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class ChatSpeakerScreen extends StatefulWidget {
  const ChatSpeakerScreen({super.key});

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // --- 상태 변수 ---
  bool _isListening = false; // 현재 음성 인식이 활성화되었는지
  bool _isLocked = false;    // '길게 말하기'(잠금) 모드가 활성화되었는지
  double _lastSoundLevel = 0.0;
  String _statusText = "준비 중...";
  String _currentRecognizedText = "";

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
          setState(() {
            _isListening = false;
            // 잠금 모드가 아닐 때만 타임아웃으로 간주하고 메시지 전송
            if (!_isLocked) {
              _sendFinalResult();
            }
          });
        }
      },
    );
    if (available && mounted) {
      // AI가 응답 중이 아니라면 바로 듣기 시작
      if (!context.read<ChatProvider>().isProcessing) {
        _startListening();
      }
    }
  }

  /// 음성 인식 시작 (잠금 모드 여부 설정 가능)
  Future<void> _startListening({bool locked = false}) async {
    // 이미 같은 상태로 듣고 있거나, AI가 처리 중이면 무시
    if ((_isListening && _isLocked == locked) || context.read<ChatProvider>().isProcessing) return;

    await _speech.stop(); // 재시작을 위해 기존 리스닝 중단

    setState(() {
      _isLocked = locked;
      _isListening = true;
    });

    _speech.listen(
      onResult: (result) {
        if (mounted) setState(() => _currentRecognizedText = result.recognizedWords);
      },
      listenFor: const Duration(minutes: 10), // 최대 녹음 시간
      // 잠금 모드일 경우, 자동 종료 시간을 매우 길게 설정하여 사실상 비활성화
      pauseFor: _isLocked ? const Duration(minutes: 10) : const Duration(seconds: 4),
      localeId: 'ko_KR',
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _lastSoundLevel = level);
      },
    );
  }

  /// AI에게 최종 인식 결과 전송
  void _sendFinalResult() {
    if (_currentRecognizedText.trim().isEmpty) {
       // 인식된 텍스트가 없으면 그냥 리스닝만 중단
       if (_isListening) {
         _speech.stop();
         setState(() => _isListening = false);
       }
       return;
    };
    
    _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isLocked = false; // 전송 후에는 항상 잠금 해제
      });
      context.read<ChatProvider>().sendMessage(_currentRecognizedText);
      _currentRecognizedText = "";
    }
  }
  
  /// 현재 상태에 맞는 버튼 위젯을 반환
  Widget _buildButton() {
    final chatProvider = context.watch<ChatProvider>();

    // 1. AI가 응답/TTS 중인 경우 (방해하기 버튼)
    if (chatProvider.isProcessing) {
      _statusText = "생각중이에요.";
      return _buildInterruptButton();
    } 
    // 2. 음성 인식 중인 경우
    else if (_isListening) {
      // 2-1. '길게 말하기'(잠금) 모드
      if (_isLocked) {
        _statusText = "귀 기울여 듣고 있어요.";
        return _buildLockedListeningButton();
      } 
      // 2-2. 일반 말하기 모드
      else {
        _statusText = "얘기가 끝나면 알려주세요.";
        return _buildNormalListeningButton();
      }
    } 
    // 3. 아무것도 안 하는 유휴 상태일 경우 (말하기 시작 버튼)
    else {
      _statusText = "탭하여 말하기";
      return _buildStartListeningButton();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바 (닫기, 설정 버튼)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () {
                      _speech.stop();
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
            // 중앙 컨텐츠
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.watch<ChatProvider>().characterName,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  WhiteEqualizerBars(soundLevel: _lastSoundLevel),
                  const SizedBox(height: 32),
                  // 상태 텍스트
                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 상태별 버튼
                  _buildButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [상태1] AI 응답 중 -> 방해하고 말하기 시작 버튼
  Widget _buildInterruptButton() {
    return GestureDetector(
      onTap: () {
        context.read<ChatProvider>().stopTts(); // TTS 중단
        _startListening(locked: false); // 일반 모드로 듣기 시작
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }

  /// [상태2] 일반 듣기 모드 -> 탭: 턴 종료 / 길게 누르기: 잠금 모드 전환
  Widget _buildNormalListeningButton() {
    return GestureDetector(
      onTap: _sendFinalResult, // 탭하면 내 턴 종료
      onLongPress: () => _startListening(locked: true), // 길게 누르면 잠금 모드로 전환
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
        child: const Icon(Icons.lock_open, color: Colors.white, size: 40),
      ),
    );
  }
  
  /// [상태3] 잠금 모드 -> 탭: 턴 종료 / 길게 누르기: 일반 모드 전환
  Widget _buildLockedListeningButton() {
    return GestureDetector(
      onTap: _sendFinalResult, // 탭하면 내 턴 종료
      onLongPress: () => _startListening(locked: false), // 길게 누르면 잠금 해제
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.lock, color: Colors.white, size: 40),
      ),
    );
  }
  
  /// 유휴 상태 -> 말하기 시작 버튼 (UI는 Interrupt와 동일)
  Widget _buildStartListeningButton() {
    return GestureDetector(
      onTap: () => _startListening(locked: false),
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }
}

// 이퀄라이저 위젯 (변경 없음)
class WhiteEqualizerBars extends StatefulWidget {
  final double soundLevel;
  const WhiteEqualizerBars({super.key, required this.soundLevel});

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