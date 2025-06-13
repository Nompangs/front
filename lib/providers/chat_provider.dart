import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nompangs/services/openai_chat_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';

class ChatMessage {
  String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatProvider extends ChangeNotifier {
  final OpenAiChatService _openAiChatService = OpenAiChatService();
  final OpenAiTtsService _openAiTtsService = OpenAiTtsService();
  StreamSubscription<String>? _apiStreamSubscription;

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
    if (greeting != null && greeting!.isNotEmpty) {
      // 초기 인사 메시지는 Provider 생성 시점에 추가합니다.
      _addMessage(greeting!, false, speak: true);
    }
  }
  
  void _addMessage(String text, bool isUser, {bool speak = false}) {
    if (!isUser && _messages.isNotEmpty && !_messages.first.isUser && _messages.first.text.isEmpty) {
      // AI의 첫 스트리밍 데이터일 경우, 기존의 빈 메시지를 업데이트합니다.
      _messages.first.text = text;
    } else {
      _messages.insert(0, ChatMessage(text: text, isUser: isUser));
    }
    
    if (speak) {
      _openAiTtsService.speak(text);
    }
    notifyListeners();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isProcessing) return;

    _addMessage(userInput, true);
    await _requestAiResponseStream(userInput);
  }

  Future<void> _requestAiResponseStream(String userInput) async {
    _isProcessing = true;
    _messages.insert(0, ChatMessage(text: '', isUser: false)); // AI 응답을 위한 빈 placeholder 추가
    notifyListeners();
    
    String fullResponseText = '';
    String sentenceBuffer = '';
    Future<void>? firstSentencePlaybackFuture;

    final characterProfile = {
      'name': characterName,
      'tags': personalityTags,
      'greeting': greeting,
    };

    _apiStreamSubscription = _openAiChatService
        .getChatCompletionStream(userInput, characterProfile: characterProfile)
        .listen(
      (textChunk) {
        fullResponseText += textChunk;
        if (_messages.isNotEmpty && !_messages.first.isUser) {
          _messages.first.text = fullResponseText;
          notifyListeners();
        }

        // 첫 문장이 완성되면 바로 TTS 재생 시작
        if (firstSentencePlaybackFuture == null) {
          sentenceBuffer += textChunk;
          RegExp sentenceEnd = RegExp(r'[.?!]\s|\n');
          if (sentenceEnd.hasMatch(sentenceBuffer)) {
            final match = sentenceEnd.firstMatch(sentenceBuffer)!;
            final firstSentence = sentenceBuffer.substring(0, match.end).trim();
            if (firstSentence.isNotEmpty) {
              firstSentencePlaybackFuture = _openAiTtsService.speak(firstSentence);
            }
          }
        }
      },
      onDone: () async {
        // 첫 문장 재생이 끝날 때까지 대기
        await firstSentencePlaybackFuture;
        
        String restOfText = '';
        if (firstSentencePlaybackFuture != null) {
            RegExp sentenceEnd = RegExp(r'[.?!]\s|\n');
            final firstMatch = sentenceEnd.firstMatch(fullResponseText);
            if (firstMatch != null && fullResponseText.length > firstMatch.end) {
              restOfText = fullResponseText.substring(firstMatch.end).trim();
            }
        } else if (fullResponseText.isNotEmpty) {
            restOfText = fullResponseText;
        }

        if (restOfText.isNotEmpty) {
          await _openAiTtsService.speak(restOfText);
        }

        _isProcessing = false;
        notifyListeners();
      },
      onError: (e) {
        print("ChatProvider Error: $e");
        if (_messages.isNotEmpty && !_messages.first.isUser) {
          _messages.first.text = "AI 응답 중 오류가 발생했습니다.";
        }
        _isProcessing = false;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _apiStreamSubscription?.cancel();
    _openAiChatService.dispose();
    _openAiTtsService.dispose();
    super.dispose();
  }
}
