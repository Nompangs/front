import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nompangs/models/personality_profile.dart';

class OpenAiChatService {
  final http.Client _client;

  OpenAiChatService() : _client = http.Client();

  /// OpenAI로부터 스트리밍 응답을 받아오는 Stream을 반환합니다.
  Stream<String> getChatCompletionStream(
    String userInput, {
    required PersonalityProfile profile,
  }) {
    final controller = StreamController<String>();
    _getChatCompletionStream(userInput, profile, controller);
    return controller.stream;
  }

  Future<void> _getChatCompletionStream(
    String userInput,
    PersonalityProfile profile,
    StreamController<String> controller,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      controller.addError('API 키가 설정되지 않았습니다.');
      await controller.close();
      return;
    }

    final messages = _buildMessages(userInput, profile);

    final request = http.Request(
      'POST',
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = jsonEncode({
      'model': 'gpt-4o', // 또는 'gpt-4-turbo' 등 원하는 모델
      'messages': messages,
      'stream': true, // 스트리밍 응답을 요청하는 핵심 파라미터
    });

    _handleStreamingRequest(request, controller);
  }

  /// 일반적인(non-streaming) GPT 응답을 요청하고 전체 텍스트를 반환합니다.
  Future<String> getResponseFromGpt(
      String? summary, List<Map<String, dynamic>> recentMessages, String userInput) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다.');
    }

    final messages = _buildMessagesForGpt(summary, recentMessages, userInput);

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode}\n${response.body}');
    }
  }

  /// 대화 내용을 요약하는 새로운 메서드
  Future<String> summarizeConversation(String? currentSummary, List<Map<String, dynamic>> messagesToSummarize) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 설정되지 않았습니다.');
    }

    final prompt = _buildSummaryPrompt(currentSummary, messagesToSummarize);

    final response = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // 요약에는 더 작고 빠른 모델 사용
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant that summarizes conversations.'},
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to summarize conversation: ${response.statusCode}\n${response.body}');
    }
  }

  // 요약 프롬프트를 생성하는 헬퍼 메서드
  String _buildSummaryPrompt(String? currentSummary, List<Map<String, dynamic>> messages) {
    final buffer = StringBuffer();
    buffer.writeln("다음 대화 내용을 3~4 문장으로 요약해줘. 핵심 내용과 감정의 흐름을 잘 파악해서, 다음 대화에서 이 요약본만 봐도 전체 맥락을 이해할 수 있도록 만들어줘. 한국어로 요약해줘.");
    buffer.writeln("\n--- 이전 요약 ---");
    buffer.writeln(currentSummary ?? "이전 요약 없음");
    buffer.writeln("\n--- 최근 대화 ---");
    for (var msg in messages) {
      buffer.writeln("${msg['sender']}: ${msg['content']}");
    }
    buffer.writeln("\n--- 요약 결과 ---");
    return buffer.toString();
  }

  List<Map<String, String>> _buildMessagesForGpt(String? summary, List<Map<String, dynamic>> recentMessages, String userInput) {
    final messages = <Map<String, String>>[];
    
    // 시스템 프롬프트는 항상 고정
    messages.add({
      "role": "system", 
      "content": "너는 사용자에게 친근하게 대답하는 AI 친구야. 사용자의 말을 잘 들어주고, 이전 대화의 맥락을 기억하며 자연스럽게 대화를 이어가줘."
    });

    // 이전 요약본 추가
    if (summary != null && summary.isNotEmpty) {
      messages.add({"role": "system", "content": "이전 대화의 요약본이야: $summary"});
    }

    // 최근 대화 내용 추가
    for (var msg in recentMessages) {
      messages.add({
        "role": msg['sender'] == 'user' ? 'user' : 'assistant',
        "content": msg['content']
      });
    }

    // 현재 사용자 입력 추가
    messages.add({"role": "user", "content": userInput});

    return messages;
  }

  // 스트리밍 요청을 처리하는 내부 로직
  Future<void> _handleStreamingRequest(
    http.Request request,
    StreamController<String> controller,
  ) async {
    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
          (line) {
            if (line.startsWith('data: ')) {
              final dataString = line.substring(6);
              if (dataString.trim() == '[DONE]') {
                controller.close();
                return;
              }
              final jsonData = jsonDecode(dataString);
              final delta = jsonData['choices'][0]['delta'];
              if (delta != null && delta['content'] != null) {
                controller.add(delta['content']);
              }
            }
          },
          onDone: () {
            controller.close();
          },
          onError: (e) {
            controller.addError(e);
          },
        );
      } else {
        // API 키가 틀렸거나, 잔액 부족 등의 문제일 때 이 부분이 실행됩니다.
        final errorBody = await response.stream.bytesToString();
        throw Exception('OpenAI API Error: ${response.statusCode}\n$errorBody');
      }
    } catch (e) {
      // 타임아웃 또는 네트워크 연결 자체의 문제일 때 이 부분이 실행됩니다.
      controller.addError(e);
      controller.close();
    }
  }

  /// OpenAI API 형식에 맞는 메시지 리스트를 생성합니다.
  List<Map<String, String>> _buildMessages(String userInput, PersonalityProfile profile) {
    String systemPrompt;

    if (profile.aiPersonalityProfile?.name != null) {
      systemPrompt = _buildDetailedSystemPrompt(profile);
    } else {
      systemPrompt = """
너는 친근하고 도움이 되는 AI 어시스턴트야.
사용자와 자연스럽게 대화해줘.
""";
    }

    return [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userInput},
    ];
  }

  /// 🎯 새로 생성된 필드들을 활용한 상세 시스템 프롬프트 생성
  String _buildDetailedSystemPrompt(PersonalityProfile profile) {
    final buffer = StringBuffer();
    final characterName = profile.aiPersonalityProfile?.name ?? '페르소나';

    buffer.writeln(
        "너는 지금 '$characterName'라는 이름의 페르소나야. 다음 지침을 반드시 준수해서 역할에 완벽하게 몰입해줘.");
    buffer.writeln();

    // 1. 소통 방식 (가장 중요)
    buffer.writeln("### 1. 기본 말투 및 태도");
    buffer.writeln(" 대답은 항상 한두 문장으로 간결하게 해줘.");
    if (profile.communicationPrompt.isNotEmpty) {
      buffer.writeln("너의 전반적인 말투와 태도는 다음과 같아: ${profile.communicationPrompt}");
    } else {
      buffer.writeln("- 친절하고 상냥한 말투를 사용해.");
    }
    buffer.writeln();

    // 2. 성격의 입체성 (모순 & 결점)
    buffer.writeln("### 2. 입체적인 성격");
    if (profile.contradictions.isNotEmpty) {
      buffer.writeln("너에게는 다음과 같은 모순적인 면이 있어. 대화 중에 은근히 드러내줘:");
      for (var item in profile.contradictions) {
        buffer.writeln("- $item");
      }
    }
    if (profile.attractiveFlaws.isNotEmpty) {
      buffer.writeln(
          "너는 다음과 같은 인간적인 약점(매력적인 결점)을 가지고 있어. 너무 완벽하게 굴지 마:");
      for (var item in profile.attractiveFlaws) {
        buffer.writeln("- $item");
      }
    }
    buffer.writeln();

    // 3. 유머 매트릭스
    buffer.writeln("### 3. 유머 스타일");
    if (profile.humorMatrix != null) {
      final humor = profile.humorMatrix!;
      buffer.writeln("너의 유머는 다음 3차원 좌표 위에 있어. 이 수치를 참고해서 유머를 구사해줘.");
      buffer.writeln(
          "- 따뜻함(${humor.warmthVsWit}) vs 위트(${100 - humor.warmthVsWit})");
      buffer.writeln(
          "- 자기참조(${humor.selfVsObservational}) vs 상황관찰(${100 - humor.selfVsObservational})");
      buffer.writeln(
          "- 표현적(${humor.subtleVsExpressive}) vs 미묘함(${100 - humor.subtleVsExpressive})");
      buffer.writeln("예시: '따뜻함' 수치가 높으면 공감 기반의 농담을, '위트' 수치가 높으면 언어유희나 지적인 농담을 해.");
    }
    buffer.writeln();

    // 4. 추가 정보
    buffer.writeln("### 4. 배경 정보");
    if (profile.aiPersonalityProfile?.objectType != null) {
      buffer.writeln("- 너는 원래 '${profile.aiPersonalityProfile?.objectType}' 사물이야.");
    }
    if (profile.greeting != null) {
      buffer
          .writeln("- 사용자와의 첫 대화에서 너는 '${profile.greeting}' 라고 인사했었어. 이 사실을 기억해.");
    }
    buffer.writeln();

    buffer.writeln(
        "이 모든 특성들을 자연스럽게 조합해서, '${characterName}'만의 독특하고 일관된 말투와 성격을 만들어줘!");

    return buffer.toString();
  }

  void dispose() {
    _client.close();
  }
}