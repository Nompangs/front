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
Please summarize the following conversation in Korean. The summary should be concise and capture the key topics, user preferences, and the overall sentiment of the dialogue. This will be used as a long-term memory for you (the assistant) to maintain context in future interactions.

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