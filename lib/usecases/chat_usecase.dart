import 'package:flutter/foundation.dart';
import 'package:nompangs/services/character_manager.dart';
import 'package:nompangs/services/conversation_service.dart';
import 'package:nompangs/services/openai_text_chat_service.dart';
import 'package:nompangs/services/realtime_chat_service.dart';

class ChatUseCase {
  final ConversationService _conversationService = ConversationService();
  final OpenAiTextChatService _openAiTextChatService = OpenAiTextChatService();
  final CharacterManager _characterManager = CharacterManager.instance;
  final RealtimeChatService _realtimeChatService = RealtimeChatService();

  Future<String?> sendMessage({
    required String conversationId,
    required String characterId,
    required String text,
  }) async {
    try {
      // 1. 사용자 메시지를 Firestore에 추가
      await _conversationService.addMessage(
        conversationId: conversationId,
        characterId: characterId,
        sender: 'user',
        text: text,
      );

      // 2. 대화 컨텍스트(메모리, 프로필, 최근 대화) 로드
      final context = await _conversationService.getConversationContext(conversationId);
      final summary = context['summary'] as String?;
      final recentMessages = context['recentMessages'] as List<dynamic>; // Message 타입이지만, 일단 dynamic으로 받음
      final characterProfile = context['characterProfile'] as Map<String, dynamic>?;

      if (characterProfile == null) {
        throw Exception('Character profile not found in conversation context.');
      }

      // 3. 시스템 프롬프트 생성 (기존 로직 재사용)
      final realtimeSettings = characterProfile['realtimeSettings'] as Map<String, dynamic>? ?? {};
      final systemPrompt =
          await _realtimeChatService.buildEnhancedSystemPrompt(
        characterProfile,
        realtimeSettings,
      );

      // 4. AI 응답 생성
      final aiResponseText =
          await _openAiTextChatService.generateResponse(
        systemPrompt: systemPrompt,
        recentMessages: recentMessages.cast(), // List<Message>로 캐스팅
        summary: summary,
      );

      if (aiResponseText.isNotEmpty) {
        // 5. AI 응답을 Firestore에 추가
        await _conversationService.addMessage(
          conversationId: conversationId,
          characterId: characterId,
          sender: 'ai',
          text: aiResponseText,
        );

        // 6. 요약 업데이트 (백그라운드 실행, UI는 기다리지 않음)
        _triggerSummaryIfNeeded(conversationId);

        return aiResponseText;
      }
      return null;
    } catch (e) {
      debugPrint('Error in ChatUseCase.sendMessage: $e');
      // 에러 발생 시 사용자에게 피드백을 주기 위해 null 대신 에러 메시지 반환도 고려 가능
      return '죄송해요, 오류가 발생했어요: $e';
    }
  }

  // 메시지 카운트를 확인하여 요약이 필요한 시점인지 판단하고 실행
  Future<void> _triggerSummaryIfNeeded(String conversationId) async {
    try {
      final messageCount = await _conversationService.getMessageCount(conversationId);

      // 메시지 수가 10의 배수이고 0이 아닐 때 요약 실행
      if (messageCount > 0 && messageCount % 10 == 1) {
        final allMessages = await _conversationService.getAllMessages(conversationId);

        if (allMessages.isNotEmpty) {
          final summary = await _openAiTextChatService.generateSummary(messages: allMessages);
          await _conversationService.updateSummary(
            conversationId: conversationId,
            summary: summary,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _triggerSummaryIfNeeded: $e');
    }
  }
} 