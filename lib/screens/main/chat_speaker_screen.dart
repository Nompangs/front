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
  bool _isLocked = false;
  double _lastSoundLevel = 0.0;
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
          if (_isListening && !_isLocked) {
            _sendFinalResult();
          }
          setState(() => _isListening = false);
        }
      },
    );
    if (available && mounted && !context.read<ChatProvider>().isProcessing) {
      _startListening();
    }
  }

  void _restartListeningLoop() {
    if (mounted && !context.read<ChatProvider>().isProcessing && !_isListening) {
      Future.delayed(const Duration(milliseconds: 500), () => _startListening());
    }
  }
  
  Future<void> _startListening({bool locked = false}) async {
    if (mounted && (_isListening && _isLocked == locked)) return;
    
    await _speech.stop();

    setState(() {
      _isLocked = locked;
      _isListening = true;
    });

    _speech.listen(
      onResult: (result) {
        if (mounted) setState(() => _currentRecognizedText = result.recognizedWords);
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: _isLocked ? const Duration(minutes: 10) : const Duration(seconds: 4),
      localeId: 'ko_KR',
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _lastSoundLevel = level);
      },
    );
  }

  void _sendFinalResult() {
    if (!mounted) return;

    if (_currentRecognizedText.trim().isEmpty) {
      if (_isListening) _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    
    context.read<ChatProvider>().sendMessage(_currentRecognizedText);
    
    if (mounted) {
      _speech.stop();
      setState(() {
        _isListening = false;
        _isLocked = false;
        _currentRecognizedText = "";
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    _restartListeningLoop();

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
                    onPressed: () { _speech.stop(); Navigator.of(context).pop(); },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chatProvider.characterName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  WhiteEqualizerBars(soundLevel: _lastSoundLevel),
                  const SizedBox(height: 32),
                  Text(
                    _determineStatusText(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
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

  String _determineStatusText() {
    final chatProvider = context.watch<ChatProvider>();
    if (chatProvider.isProcessing) return "생각중이에요.";
    if (_isListening) {
      return _isLocked ? "귀 기울여 듣고 있어요." : "얘기가 끝나면 알려주세요.";
    }
    return "탭하여 말하기";
  }

  Widget _buildButton() {
    final chatProvider = context.watch<ChatProvider>();
    if (chatProvider.isProcessing) {
      return _buildInterruptButton();
    } else if (_isListening) {
      return _isLocked ? _buildLockedListeningButton() : _buildNormalListeningButton();
    } else {
      return _buildStartListeningButton();
    }
  }

  Widget _buildInterruptButton() {
    return GestureDetector(
      onTap: () {
        context.read<ChatProvider>().stopTts();
        _startListening(locked: false);
      },
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildNormalListeningButton() {
    return GestureDetector(
      onTap: () => _startListening(locked: true),
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
        child: const Icon(Icons.lock_open, color: Colors.white, size: 40),
      ),
    );
  }
  
  Widget _buildLockedListeningButton() {
    return GestureDetector(
      onTap: _sendFinalResult,
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.lock, color: Colors.white, size: 40),
      ),
    );
  }
  
  Widget _buildStartListeningButton() {
    return GestureDetector(
      onTap: () => _startListening(locked: false),
      child: Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        child: const Icon(Icons.mic, color: Colors.white, size: 40),
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