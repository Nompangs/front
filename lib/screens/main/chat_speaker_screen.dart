import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/gemini_service.dart';
import 'package:nompangs/services/supertone_service.dart';
import 'chat_setting.dart';

class ChatSpeakerScreen extends StatefulWidget {
  const ChatSpeakerScreen({Key? key}) : super(key: key);

  @override
  State<ChatSpeakerScreen> createState() => _ChatSpeakerScreenState();
}

class _ChatSpeakerScreenState extends State<ChatSpeakerScreen>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  late SupertoneService _supertoneService;
  late GeminiService _geminiService;
  bool _isProcessing = false; // Gemini 요청 또는 TTS 재생 중인 상태

  bool _showLockButton = false;
  Timer? _lockTimer;

  double _lastSoundLevel = 0.0;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _supertoneService = SupertoneService();
    _geminiService = GeminiService();
    _initSpeech();
    _initEqualizerControllers();
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _lockTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// STT 초기화 (퍼미션 + initialize)
  Future<void> _initSpeech() async {
    if (!await Permission.microphone.request().isGranted) {
      debugPrint('마이크 권한이 거부되었습니다.');
      return;
    }

    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    if (!available) {
      debugPrint('STT not available');
      return;
    }

    // 초기화 성공 후 바로 STT 시작
    await _startListening();
  }

  /// STT 듣기 시작
  Future<void> _startListening() async {
    // 이미 듣고 있거나 Gemini/TTS 처리 중이면 호출 무시
    if (_isListening || _isProcessing) return;
    _cancelLockTimer();

    _speech.listen(
      onResult: _onSpeechResult,
      // listenFor와 pauseFor를 넉넉히 늘려서 곧바로 타임아웃나지 않도록
      listenFor: const Duration(seconds: 30), // 최대 30초 동안 듣기 유지
      pauseFor: const Duration(seconds: 5),   // 5초 침묵 시 “끝”으로 간주
      partialResults: true,
      localeId: 'ko_KR',
      onSoundLevelChange: (level) {
        _processSoundLevel(level);
      },
      cancelOnError: true,
      // onStatus는 initialize 단계에서만 설정했으므로 여기서는 생략
    );

    setState(() {
      _isListening = true;
    });
  }

  /// STT 듣기 중단
  void _stopListening() {
    if (!_isListening) return;
    _speech.stop();
    setState(() {
      _isListening = false;
      _lastSoundLevel = 0.0;
    });
    _cancelLockTimer();
  }

  /// STT 상태 변화 콜백 (initialize 단계에서만 설정)
  void _onSpeechStatus(String status) {
    debugPrint('STT 상태: $status');

    // “notListening” 상태이면서, 지금 Gemini/TTS 처리가 진행 중이지 않은 상태라면 재시작
    if (status == 'notListening' && mounted && !_isProcessing) {
      setState(() => _isListening = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isListening && !_isProcessing) {
          _startListening();
        }
      });
    }
  }

  /// STT 오류 콜백 (initialize 단계에서만 설정)
  void _onSpeechError(stt.SpeechRecognitionError error) {
    debugPrint('STT 오류: ' + error.toString());

    // 타임아웃(error_speech_timeout) 혹은 말소리 감지 실패(error_no_match) 시,
    // Gemini/TTS가 진행 중이지 않으면 재시작
    if ((error.errorMsg == 'error_speech_timeout' ||
        error.errorMsg == 'error_no_match') &&
        mounted &&
        !_isProcessing) {
      setState(() => _isListening = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isListening && !_isProcessing) {
          _startListening();
        }
      });
    }
  }

  /// 음성 인식 결과 콜백
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    final recognized = result.recognizedWords;
    if (recognized.isNotEmpty) {
      debugPrint('🎤 인식된 음성: ' + recognized);
      _startLockTimer();
    }
    if (result.finalResult && recognized.isNotEmpty) {
      // 최종 결과 확정 시 Gemini로 전송
      _sendToGemini(recognized);
      _cancelLockTimer();
    }
  }

  /// 음성 레벨 변화 → Equalizer 애니메이션
  void _processSoundLevel(double level) {
    final amplified = (level * 3).clamp(0.0, 1.0);
    setState(() {
      _lastSoundLevel = amplified;
    });
    if (amplified > 0.1) {
      _startLockTimer();
    } else if (amplified < 0.1) {
      _cancelLockTimer();
    }
  }

  /// Gemini 요청과 TTS 재생
  Future<void> _sendToGemini(String text) async {
    if (_isProcessing) return;

    // (1) Gemini/TTS 처리 중임을 나타내는 플래그를 켜고,
    //     STT가 듣고 있으면 중단한다.
    setState(() {
      _isProcessing = true;
    });
    if (_isListening) {
      _stopListening();
    }

    try {
      final response = await _geminiService.analyzeUserInput(text);
      final reply = response['response'] ?? '';
      if (reply.isNotEmpty) {
        debugPrint('💎 Gemini 응답: ' + reply);
        // (2) TTS 재생: 이 Future가 꺼질 때까지 STT를 절대 재시작하지 않는다.
        await _supertoneService.speak(reply);
      }
    } catch (e) {
      debugPrint('Gemini 통신 오류: ' + e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gemini 혹은 TTS 처리 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        // (3) TTS 재생이 모두 끝난 뒤에만 플래그 해제
        setState(() {
          _isProcessing = false;
        });
        // (4) 딜레이를 충분히 준 뒤(1초) STT를 다시 시작
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isListening && !_isProcessing) {
            _startListening();
          }
        });
      }
    }
  }

  void _startLockTimer() {
    if (_lockTimer != null) return; // already counting
    _lockTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showLockButton = true);
      }
      _lockTimer = null;
    });
  }

  void _cancelLockTimer() {
    if (_lockTimer != null) {
      _lockTimer!.cancel();
      _lockTimer = null;
    }
    if (_showLockButton) {
      setState(() => _showLockButton = false);
    }
  }

  /// Equalizer 바들 초기화
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
      onWillPop: () async {
        if (_isListening) _stopListening();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
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
                        Icons.more_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        // 추가 메뉴 동작
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
                    WhiteEqualizerBars(soundLevel: _lastSoundLevel),
                    const SizedBox(height: 32),
                    const Text(
                      '귀 기울여 듣고 있어요.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(height: 72),
                  ],
                ),
              ),
              ],
            ),
              if (_showLockButton) _buildLockButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockButton(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double scaleX = size.width / 375.0;
    double scaleY = size.height / 812.0;
    double left = 138 * scaleX;
    double top = 606 * scaleY;
    double diameter = 94 * scaleX;
    double iconSize = 42 * scaleX;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          if (_isListening) _stopListening();
          Navigator.of(context).maybePop();
        },
        child: Container(
          width: diameter,
          height: diameter,
          decoration: const BoxDecoration(
            color: Color(0xFFFF3B2F),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class WhiteEqualizerBars extends StatefulWidget {
  final double soundLevel;
  const WhiteEqualizerBars({Key? key, required this.soundLevel})
      : super(key: key);

  @override
  _WhiteEqualizerBarsState createState() => _WhiteEqualizerBarsState();
}

class _WhiteEqualizerBarsState extends State<WhiteEqualizerBars>
    with TickerProviderStateMixin {
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
    return Container(
      width: 300,
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              double baseHeight = _getBaseHeight(index);
              double scale = 0.5 + (widget.soundLevel * 0.5);
              double height = baseHeight * _animations[index].value * scale;
              height = height.clamp(10.0, baseHeight);

              return Container(
                width: 20,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.3 + (_animations[index].value * 0.4)),
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
    double center = 2;
    double distance = (index - center).abs();
    return 150 - (distance * 4);
  }
}