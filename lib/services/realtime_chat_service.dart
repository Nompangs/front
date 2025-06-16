import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint를 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart' as openai_rt;
import 'package:nompangs/providers/chat_provider.dart';

class RealtimeChatService {
  late final openai_rt.RealtimeClient _client;

  // UI 업데이트용 스트림 (텍스트 조각) - 타입을 String으로 변경
  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;

  // TTS 재생용 스트림 (완성된 문장)
  final _completionController = StreamController<String>.broadcast();
  Stream<String> get completionStream => _completionController.stream;

  RealtimeChatService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다.");
    }
    _client = openai_rt.RealtimeClient(apiKey: apiKey);
  }

  Future<void> connect(Map<String, dynamic> characterProfile) async {
    await _client.updateSession(instructions: _buildSystemPrompt(characterProfile));

    // 대화 내용 업데이트 이벤트 리스너
    _client.on(openai_rt.RealtimeEventType.conversationUpdated, (event) {
      final result = (event as openai_rt.RealtimeEventConversationUpdated).result;
      final delta = result.delta;
      if (delta?.transcript != null) {
        // ChatMessage 객체 대신 순수 텍스트(String)를 전달
        _responseController.add(delta!.transcript!);
      }
    });

    // --- '응답 완료' 감지를 위한 새로운 리스너 (디버깅 로그 추가) ---
    _client.on(openai_rt.RealtimeEventType.conversationItemCompleted, (event) {
      final item = (event as openai_rt.RealtimeEventConversationItemCompleted).item;
      debugPrint("[Realtime Service] 💬 응답 완료 이벤트 발생!");

      if (item.item case final openai_rt.ItemMessage message) {
        debugPrint("[Realtime Service] 역할: ${message.role.name}, 내용: ${message.content}");

        if (message.role.name == 'assistant') {
          String textContent = '';
          
          // --- 오류 수정 부분: content 리스트를 순회하며 올바른 타입에서 텍스트 추출 ---
          for (final part in message.content) {
            // 응답이 ContentPart.audio 타입이고, 그 안에 transcript가 있을 경우
            if (part is openai_rt.ContentPartAudio && part.transcript != null) {
              textContent = part.transcript!;
              break; // 텍스트를 찾았으므로 반복 중단
            }
            // 예비용: 만약 ContentPart.text 타입으로 올 경우
            else if (part is openai_rt.ContentPartText) {
              textContent = part.text;
              break;
            }
          }
          
          debugPrint("[Realtime Service] 추출된 텍스트: '$textContent'");

          if (textContent.isNotEmpty) {
            _completionController.add(textContent);
            debugPrint("[Realtime Service] ✅ TTS 재생을 위해 텍스트 전송 완료!");
          } else {
            debugPrint("[Realtime Service] ⚠️ 추출된 텍스트가 비어있어 TTS를 호출하지 않음.");
          }
        }
      } else {
        debugPrint("[Realtime Service] ⚠️ 완료된 아이템이 'ItemMessage' 타입이 아님: ${item.item.runtimeType}");
      }
    });

    _client.on(openai_rt.RealtimeEventType.error, (event) {
      final error = (event as openai_rt.RealtimeEventError).error;
      _responseController.addError(error);
      debugPrint('[Realtime Service] 🚨 에러 발생: $error');
    });

    await _client.connect();
  }

  Future<void> sendMessage(String text) async {
    await _client.sendUserMessageContent([
      openai_rt.ContentPart.inputText(text: text),
    ]);
  }

  String _buildSystemPrompt(Map<String, dynamic> characterProfile) {
    String characterName = characterProfile['name'] as String;
    List<String> tags = List<String>.from(characterProfile['tags']);
    String tagsString = tags.join(', ');

    return """
        너는 지금 '$characterName'라는 이름의 페르소나야.
        너의 성격 태그는 [$tagsString]이며, 이를 참고하여 대화해줘.
        사용자와 오랜 친구처럼 친근하게 대화하고, 너의 개성을 말투에 반영해줘.
        말투는 따뜻하고, 너무 길지 않게 말해줘.
        """;
  }

  void dispose() {
    _client.disconnect();
    _responseController.close();
    _completionController.close();
  }
}