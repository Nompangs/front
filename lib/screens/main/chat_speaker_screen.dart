// lib/chat_speaker_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/gemini_service.dart';
import 'chat_setting.dart';


class ChatSpeakerScreen extends StatefulWidget {
  const ChatSpeakerScreen({Key? key}) : super(key: key);

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen>
    with TickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _manualStop = false;
  late GeminiService _geminiService;
  bool _isProcessing = false;

  /// 마지막으로 전달받은 sound level (0.0 ~ 1.0)
  double _lastSoundLevel = 0.0;

  /// Equalizer Bars 컨트롤러 리스트
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
    _initSpeech();
    _initEqualizerControllers();
  }

  @override
  void dispose() {
    // STT 중지
    if (_isListening) {
      _manualStop = true;
      _speech.stop();
    }
    // Equalizer AnimationController 해제
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// speech_to_text 초기화
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();

    if (!await Permission.microphone.request().isGranted) {
      debugPrint('마이크 권한이 거부되었습니다.');
      return;
    }

    setState(() {
      _speechInitialized = true;
    });

    await _startListening();
  }

  /// STT 듣기 시작
  Future<void> _startListening() async {
    if (!_speechInitialized || _isListening) return;

    _manualStop = false;

    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (errorNotification) {
        debugPrint('STT initialize error: ' + errorNotification.toString());
      },
    );

    if (!available) {
      debugPrint('STT not available');
      return;
    }

    _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      // 사용자가 말을 멈춘 뒤 2초가 지나면 자동 중단
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      localeId: 'ko_KR',
      onSoundLevelChange: (level) {
        // sound level(0.0~1.0)이 변경될 때마다 업데이트
        _processSoundLevel(level);
      },
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );

    setState(() {
      _isListening = true;
    });
  }

  /// STT 듣기 중단
  void _stopListening() {
    if (!_isListening) return;
    _manualStop = true;
    _speech.stop();
    setState(() {
      _isListening = false;
      _lastSoundLevel = 0.0;
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && mounted) {
      setState(() => _isListening = false);
      if (!_manualStop) {
        _startListening();
      }
    }
  }

  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    if (recognized.isNotEmpty) {
      debugPrint('\u{1F3A4} 인식된 음성: ' + recognized);
    }
    if (result.finalResult && recognized.isNotEmpty) {
      _sendToGemini(recognized);
    }
  }

  /// sound level → Equalizer 애니메이션에 전달
  void _processSoundLevel(double level) {
    // level: 0.0 ~ 1.0 (실제 STT에서 넘어오는 값은 보통 작으므로 증폭)
    final amplified = (level * 3).clamp(0.0, 1.0);
    setState(() {
      _lastSoundLevel = amplified;
    });
  }

  Future<void> _sendToGemini(String text) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final response = await _geminiService.analyzeUserInput(text);
      final reply = response['response'] ?? '';
      if (reply.isNotEmpty) {
        debugPrint('\u{1F48E} Gemini 응답: ' + reply);
      }
    } catch (e) {
      debugPrint('Gemini 통신 오류: ' + e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Equalizer AnimationController + Tween 초기화
  void _initEqualizerControllers() {
    _controllers = List.generate(24, (index) {
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
  Widget build(BuildContext context) {
    return WillPopScope(
      // 뒤로가기 시 STT 중단
      onWillPop: () async {
        if (_isListening) _stopListening();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ─── 상단 바 ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (_isListening) _stopListening();
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatSettingScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ─── 중앙 콘텐츠 ────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ① Equalizer Bars 위젯
                    WhiteEqualizerBars(),

                    const SizedBox(height: 32),

                    // ② 안내 문구
                    const Text(
                      '귀 기울여 듣고 있어요.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ③ 잠금 버튼 (빨간 원 + 자물쇠 아이콘)
                    GestureDetector(
                      onTap: () {
                        if (_isListening) _stopListening();
                        Navigator.of(context).maybePop();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE64545),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================================================
/// WhiteEqualizerBars
///
/// • 24개의 바를 애니메이션으로 생성하고, 각 바의 높이를
///   기본 애니메이션 값(animation.value)과 “soundLevel”을 곱해 진폭 조절.
/// • [soundLevel]: 0.0 ~ 1.0 값(포화 시 amplitude가 최대가 됨)
/// • [animations]: initState에서 생성된 24개의 Animation<double>
/// =============================================================
class WhiteEqualizerBars extends StatefulWidget {
  @override
  _WhiteEqualizerBarsState createState() => _WhiteEqualizerBarsState();
}

class _WhiteEqualizerBarsState extends State<WhiteEqualizerBars>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> animations;

  @override
  void initState() {
    super.initState();

    // 24개 바에 대한 애니메이션 컨트롤러 생성
    controllers = List.generate(24, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 50)), // 각각 다른 속도
        vsync: this,
      );
    });

    animations = controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // 모든 애니메이션 시작
    for (var controller in controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: animations[index],
            builder: (context, child) {
              double baseHeight = _getBaseHeight(index);
              double currentHeight = baseHeight * animations[index].value;

              return Container(
                width: 20,
                height: currentHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3 + (animations[index].value * 0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  double _getBaseHeight(int index) {
    // 중앙이 가장 높고 양쪽으로 갈수록 낮아지는 패턴
    double center = 3;
    double distance = (index - center).abs();
    return 150 - (distance * 4); // 높이 조절
  }
}