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
  
  bool _isListening = false;
  bool _isConfirmingEndTurn = false;
  double _lastSoundLevel = 0.0;
  String _currentRecognizedText = "";
  bool _hasHadFirstInteraction = false;
  
  
  Timer? _endTurnTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _speech.stop();
    
    _endTurnTimer?.cancel();
    super.dispose();
  }

  void _restartListeningLoop() {
    if (!_hasHadFirstInteraction || !mounted || context.read<ChatProvider>().isProcessing || _isListening) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !context.read<ChatProvider>().isProcessing && !_isListening) {
            _activateMicrophone();
        }
    });
  }
  
  Future<void> _activateMicrophone() async {
    if (_isListening || !mounted) return;

    bool isInitialized = await _speech.initialize(
        onError: (error) {
          print('STT Init Error: $error');
          _showErrorDialog("음성 인식 중 오류가 발생했습니다: ${error.errorMsg}");
        },
        onStatus: (status) {
            if (status == stt.SpeechToText.notListeningStatus && mounted) {
                
                
                if (_isListening) {
                    setState(() => _isListening = false);
                }
            }
        },
    );

    if (isInitialized && mounted) {
        setState(() {
            _isListening = true;
            _isConfirmingEndTurn = false; 
            _currentRecognizedText = "";
        });

        _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            setState(() { _currentRecognizedText = result.recognizedWords; });

            
            if (!_isConfirmingEndTurn) {
                _endTurnTimer?.cancel(); 
                _endTurnTimer = Timer(const Duration(seconds: 3), () {
                    if (_isListening) {
                        print("⏰ 자동 종료 타이머 실행 (일반 모드)");
                        _sendFinalResult();
                    }
                });
            }
          },
          
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(minutes: 10),
          localeId: 'ko_KR',
          onSoundLevelChange: (level) {
            if (mounted) setState(() => _lastSoundLevel = level);
          },
        );
    } else if (mounted) {
        _showErrorDialog("음성 인식 엔진을 시작할 수 없습니다.");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _sendFinalResult() {
    if (!mounted || !_isListening) return;
    
    
    _endTurnTimer?.cancel();
    
    final textToSend = _currentRecognizedText.trim();
    
    _speech.stop();
    setState(() {
      _isListening = false;
      _isConfirmingEndTurn = false;
      _currentRecognizedText = "";
    });

    if (textToSend.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(textToSend);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    if (!chatProvider.isProcessing) {
      _restartListeningLoop();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_isConfirmingEndTurn) {
              
              setState(() => _isConfirmingEndTurn = false);
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () { _speech.stop(); Navigator.of(context).pop(); },
                    ),
                    IconButton(icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(chatProvider.characterName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40),
                    WhiteEqualizerBars(soundLevel: _lastSoundLevel),
                    const SizedBox(height: 32),
                    Text(_determineStatusText(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 40),
                    _buildButton(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _determineStatusText() {
    final chatProvider = context.watch<ChatProvider>();
    if (chatProvider.isProcessing) return "생각중이에요.";
    if (_isConfirmingEndTurn) return "얘기가 끝나면 알려주세요.";
    if (_isListening) return "귀 기울여 듣고 있어요.";
    return "탭하여 말하기";
  }

  Widget _buildButton() {
    final chatProvider = context.watch<ChatProvider>();
    if (chatProvider.isProcessing) {
      return _buildStartOrInterruptButton(); 
    } else if (_isConfirmingEndTurn) {
      return _buildConfirmEndTurnButton();
    } else if (_isListening) {
      return _buildListeningButton();
    } else {
      return _buildStartOrInterruptButton(); 
    }
  }

  Widget _buildStartOrInterruptButton() {
    return GestureDetector(
      onTap: () {
        if (!_hasHadFirstInteraction) {
          setState(() => _hasHadFirstInteraction = true);
        }
        context.read<ChatProvider>().stopTts();
        _activateMicrophone();
      },
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildListeningButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isConfirmingEndTurn = true;
          
          _endTurnTimer?.cancel(); 
        });
      },
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.lock, color: Colors.white, size: 40),
      ),
    );
  }
  
  Widget _buildConfirmEndTurnButton() {
    return GestureDetector(
      onTap: _sendFinalResult,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
        child: const Icon(Icons.lock_open, color: Colors.white, size: 40),
      ),
    );
  }
}

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
    _controllers = List.generate(5, (i) => AnimationController(duration: Duration(milliseconds: 800 + (i * 50)), vsync: this)..repeat(reverse: true));
    _animations = _controllers.map((c) => Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
  }
  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (i) => AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            double baseHeight = 150 - ((i - 2).abs() * 40.0);
            double scale = 0.5 + (widget.soundLevel * 1.5);
            double height = (baseHeight * _animations[i].value * scale).clamp(10.0, baseHeight);
            return Container(
              width: 20, height: height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3 + (_animations[i].value * 0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        )),
      ),
    );
  }
}