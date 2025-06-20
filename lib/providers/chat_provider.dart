import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nompangs/services/conversation_service.dart';
import 'package:nompangs/services/elevenlabs_tts_service.dart';
import 'package:nompangs/services/openai_chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ConversationService _conversationService = ConversationService();
  final OpenAiChatService _chatService = OpenAiChatService();
  final ElevenLabsTtsService _ttsService = ElevenLabsTtsService();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  late final String uuid;
  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;

  ChatProvider({required Map<String, dynamic> characterProfile})
      : greeting = characterProfile['greeting'] as String? {
    uuid = characterProfile['uuid'] ??
        'temp_uuid_${DateTime.now().millisecondsSinceEpoch}';
    characterName =
        characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음';
    characterHandle =
        '@${(characterProfile['aiPersonalityProfile']?['name'] ?? 'unknown').toLowerCase().replaceAll(' ', '')}';
    personalityTags = (characterProfile['personalityTags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        [];
    
    _initializeChat();
  }
  
  void _initializeChat() {
    _sendInitialGreetingIfNeeded();
  }

  Future<void> _sendInitialGreetingIfNeeded() async {
    final messagesStream = getMessagesStream();
    final snapshot = await messagesStream.first;
    if (snapshot.docs.isEmpty && greeting != null && greeting!.isNotEmpty) {
      await sendMessage(greeting!, isInitialGreeting: true);
    }
  }

  Stream<QuerySnapshot> getMessagesStream() {
    return _conversationService.getMessagesStream(uuid);
  }

  Future<void> stopTts() async {
    // _ttsService.stop();
  }

  Future<void> sendMessage(String text, {bool isInitialGreeting = false}) async {
    if (text.trim().isEmpty || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      if (!isInitialGreeting) {
        await _conversationService.sendMessage(uuid, text, 'user');
      }

      final context = await _conversationService.getConversationContext(uuid);

      final botResponse = await _chatService.getResponseFromGpt(
          context['summary'], context['recentMessages'], text);

      await _conversationService.sendMessage(uuid, botResponse, 'bot');

      // await _ttsService.play(botResponse);

    } catch (e) {
      debugPrint("메시지 전송/처리 중 에러 발생: $e");
      try {
        await _conversationService.sendMessage(uuid, "오류가 발생했어요: $e", 'bot');
      } catch (e2) {
        debugPrint("오류 메시지 저장 실패: $e2");
      }
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
