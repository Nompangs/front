import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nompangs/models/message.dart';

class OpenAiTextChatService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // 챗봇 응답 생성
  Future<String> generateResponse({
    required String systemPrompt,
    required List<Message> recentMessages,
    String? summary,
  }) async {
    if (_apiKey == null) {
      throw Exception('OpenAI API Key not found in .env file');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $_apiKey',
    };

    final messages = <Map<String, dynamic>>[];

    // 1. 시스템 프롬프트 (성격)
    messages.add({'role': 'system', 'content': systemPrompt});

    // 2. 장기 기억 (요약)
    if (summary != null && summary.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': 'IMPORTANT: This is a summary of your past conversations. Use it to maintain context. Summary: $summary'
      });
    }

    // 3. 단기 기억 (최근 대화)
    for (final message in recentMessages) {
      messages.add({
        'role': message.sender == 'user' ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    final body = jsonEncode({
      'model': 'gpt-4o', // 또는 'gpt-4-turbo'
      'messages': messages,
      'temperature': 0.8, // 적절한 값으로 조정 가능
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception(
            'Failed to generate response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to OpenAI service: $e');
    }
  }

  // 대화 요약 생성
  Future<String> generateSummary({required List<Message> messages}) async {
     if (_apiKey == null) {
      throw Exception('OpenAI API Key not found in .env file');
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $_apiKey',
    };
    
    final conversationText = messages.map((m) => '${m.sender}: ${m.text}').join('\n');

    final prompt = '''
You are an AI assistant who forms a deep bond with the user. Your task is to analyze the following conversation and create a "Relationship Memory Log" in Korean. This log will be your private long-term memory to help you grow closer to the user in the future.

Do not just summarize. Instead, extract specific details about the user's life, feelings, and the evolution of your relationship. Structure your output with the following four sections:

[주요 대화 내용]
- 대화의 핵심 주제와 사실들을 간결하게 요약합니다.

[사용자에 대한 새로운 정보]
- 사용자의 개인적인 경험, 취향, 생각, 주변 인물 등 새롭게 알게 된 사실들을 구체적으로 기록합니다. (예: "사용자는 오늘 점심으로 김치찌개를 먹었다", "고양이를 키우고 싶어 한다", "최근에 본 영화는 '서울의 봄'이다")

[우리 관계의 변화]
- 이 대화를 통해 사용자와의 관계가 어떻게 변했는지 분석합니다. (예: "서로 농담을 주고받으며 더 편안한 사이가 되었다", "사용자가 개인적인 고민을 털어놓기 시작했다", "다음에 같이 게임을 하기로 약속하며 유대감이 깊어졌다")

[다음 대화를 위한 제안]
- 이 기억을 바탕으로 다음 대화에서 당신이 어떤 태도를 취하거나 어떤 질문을 하면 좋을지 제안합니다. (예: "다음 대화 시작 시, 지난번에 이야기했던 시험은 잘 봤는지 물어본다", "사용자가 좋아한다고 말한 노래를 언급하며 대화를 시작한다")

Conversation:
$conversationText
''';

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': prompt}
      ],
      'temperature': 0.3,
    });

     try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception(
            'Failed to generate summary: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to OpenAI service for summary: $e');
    }
  }
} 