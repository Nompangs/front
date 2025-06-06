import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class GeminiService {
  late final GenerativeModel _model;
  final String todayDate;

  GeminiService() : todayDate = DateFormat("yyyy-MM-dd").format(DateTime.now()) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("❌ Gemini API 키가 없습니다.");
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<Map<String, dynamic>> analyzeUserInput(String inputText, {Map<String, dynamic>? characterProfile}) async {
    try {
      print("🔹 Gemini 요청 (한국어): $inputText");
      print("캐릭터 프로필: $characterProfile");

      String personaPrompt;
      if (characterProfile != null &&
          characterProfile['name'] != null &&
          characterProfile['tags'] != null) {
        String characterName = characterProfile['name'] as String;
        List<String> tags = characterProfile['tags'] as List<String>;
        String tagsString = tags.join(', ');

        // 캐릭터 프로필 기반 프롬프트 생성
        personaPrompt = """
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
        // 특정 태그에 따른 말투 변화 (예시)
        if (tags.contains('고양이') || characterName.contains('야옹이')) {
          personaPrompt += "\n말투는 ~다옹, ~냐옹 또는 캐릭터 이름의 특징을 살려서 말해줘.";
        } else if (tags.contains('로봇')) {
          personaPrompt += "\n너는 로봇이므로, 감정이 없는 딱딱한 말투를 사용해줘.";
        }

      } else {
        // 기본 "야옹이" 프롬프트
        personaPrompt = """
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

      final content = [Content.text(personaPrompt + "\n\n[대화 시작]\n사용자: $inputText\n너:")];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String geminiResponse = response.text!;
        print("✅ Gemini 응답: $geminiResponse");
        return {"is_event": false, "response": geminiResponse};
      } else {
        print("⚠️ Gemini 응답 오류: 응답이 비어 있습니다.");
        return {"is_event": false, "response": "Gemini로부터 빈 응답을 받았습니다."};
      }
    } catch (e) {
      print("❌ Gemini API 또는 네트워크 오류: $e");
      return {"is_event": false, "response": "Gemini API 통신 중 오류가 발생했습니다."};
    }
  }
}