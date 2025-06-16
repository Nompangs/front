import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nompangs/services/realtime_chat_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';

// ChatMessage 클래스에 isLoading 플래그 추가
class ChatMessage {
  String text;
  final bool isUser;
  bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false, // 기본값은 false
  });
}

class ChatProvider extends ChangeNotifier {
  final RealtimeChatService _realtimeChatService = RealtimeChatService();
  final OpenAiTtsService _openAiTtsService = OpenAiTtsService();
  
  // 스트림 구독 관리
  StreamSubscription<String>? _completionSubscription;

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;

  ChatProvider({
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
    this.greeting,
  }) {
    _initializeChat();
    if (greeting != null && greeting!.isNotEmpty) {
      _addMessage(greeting!, false, speak: true);
    }
  }
  
  Future<void> _initializeChat() async {
    final characterProfile = {
      'name': characterName,
      'tags': personalityTags,
      'greeting': greeting,
    };
    await _realtimeChatService.connect(characterProfile);

    _completionSubscription = _realtimeChatService.completionStream.listen((fullText) async { // 1. 리스너를 async로 변경
        if (_messages.isNotEmpty && _messages.first.isLoading) {
          // 로딩 중인 메시지를 최종 텍스트로 업데이트하고 UI에 먼저 표시
          _messages.first.text = fullText;
          _messages.first.isLoading = false;
          notifyListeners();

          // 텍스트 업데이트와 동시에 음성 재생
          if (fullText.trim().isNotEmpty) {
            await _openAiTtsService.speak(fullText.trim()); // 2. TTS 재생이 끝날 때까지 await
          }
        }
        
        // 3. TTS 재생이 완료된 후 처리 상태를 false로 변경
        _isProcessing = false;
        notifyListeners();
    },
    onError: (e) {
      if (_messages.isNotEmpty && _messages.first.isLoading) {
          _messages.first.text = "AI 응답 중 오류가 발생했습니다: $e";
          _messages.first.isLoading = false;
      }
       _isProcessing = false;
       notifyListeners();
    });
  }

  void _addMessage(String text, bool isUser, {bool speak = false}) {
    _messages.insert(0, ChatMessage(text: text, isUser: isUser));
    if (speak) {
      _openAiTtsService.speak(text);
    }
    notifyListeners();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isProcessing) return;

    _openAiTtsService.stop(); 
    _addMessage(userInput, true);

    _isProcessing = true;
    // AI 응답을 기다리는 동안 로딩 버블을 추가
    _messages.insert(0, ChatMessage(text: '', isUser: false, isLoading: true));
    notifyListeners();
    
    await _realtimeChatService.sendMessage(userInput);
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    _realtimeChatService.dispose(); 
    _openAiTtsService.dispose();
    super.dispose();
  }
}