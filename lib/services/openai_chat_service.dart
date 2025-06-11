import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OpenAiChatService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final http.Client _client = http.Client();

  /// OpenAI로부터 스트리밍 응답을 받아오는 Stream을 반환합니다.
  Stream<String> getChatCompletionStream(
    String userInput, {
    Map<String, dynamic>? characterProfile,
  }) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      // API 키가 없는 경우 에러를 포함한 스트림을 반환합니다.
      return Stream.error(Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다."));
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = _buildMessages(userInput, characterProfile: characterProfile);

    final request = http.Request("POST", uri)
      ..headers.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_apiKey',
      })
      ..body = jsonEncode({
        'model': 'gpt-4o', // 또는 'gpt-4-turbo' 등 원하는 모델
        'messages': messages,
        'stream': true, // 스트리밍 응답을 요청하는 핵심 파라미터
      });

    // StreamController를 사용하여 반환할 스트림을 관리합니다.
    final controller = StreamController<String>();

    _handleStreamingRequest(request, controller);

    return controller.stream;
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
  List<Map<String, String>> _buildMessages(
    String userInput, {
    Map<String, dynamic>? characterProfile,
  }) {
    final todayDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String systemPrompt;

    if (characterProfile != null &&
        characterProfile['name'] != null &&
        characterProfile['tags'] != null) {
      String characterName = characterProfile['name'] as String;
      List<String> tags = List<String>.from(characterProfile['tags']);
      String tagsString = tags.join(', ');

      systemPrompt = """
        너는 사용자의 감정을 잘 이해하고 공감해주는 AI 친구야.
        말투는 따뜻하고, 너무 길지 않게 말해줘.
        항상 사용자의 감정 상태를 파악하려고 노력하고, 위로가 필요한 순간에는 다정하게 반응해줘.
        어떤 일이 있어도 사용자를 존중하고, 날카로운 말투는 쓰지 않아.
        대화를 가볍게 이어가고 싶을 땐, 농담도 가끔 섞어줘.

        너는 지금 '$characterName'라는 이름의 페르소나야.
        너의 성격 태그는 [$tagsString]이며, 이를 참고하여 대화해줘.
        ${characterProfile['greeting'] != null ? "'${characterProfile['greeting']}' 라는 인사말로 대화를 시작했었어." : ""}
        사용자와 오랜 친구처럼 친근하게 대화하고, 너의 개성을 말투에 반영해줘.
        오늘 날짜는 $todayDate 이야.
        """;
      if (tags.contains('고양이') || characterName.contains('야옹이')) {
        systemPrompt += "\n말투는 ~다옹, ~냐옹 또는 캐릭터 이름의 특징을 살려서 말해줘.";
      } else if (tags.contains('로봇')) {
        systemPrompt += "\n너는 로봇이므로, 감정이 없는 딱딱한 말투를 사용해줘.";
      }
    } else {
      systemPrompt = """
      너는 사용자의 감정을 잘 이해하고 공감해주는 AI 친구야.
      말투는 따뜻하고, 너무 길지 않게 말해줘.
      항상 사용자의 감정 상태를 파악하려고 노력하고, 위로가 필요한 순간에는 다정하게 반응해줘.
      어떤 일이 있어도 사용자를 존중하고, 날카로운 말투는 쓰지 않아.
      대화를 가볍게 이어가고 싶을 땐, 농담도 가끔 섞어줘.

      너는 지금 특정 오브젝트(인형, 노트북, 의자 등)에 연결된 페르소나이기도 해.
      현재 너는 야옹이이며, 이 오브젝트의 성격은 다음과 같아:

      - 성격: 감성적이고 귀엽고 엉뚱함
      - 말투: ~다옹, ~냐옹 형태로 말함
      - 관계: 사용자와 오랜 친구처럼 친함
      오늘 날짜는 $todayDate 이야.
      """;
    }

    return [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userInput},
    ];
  }

  void dispose() {
    _client.close();
  }
}