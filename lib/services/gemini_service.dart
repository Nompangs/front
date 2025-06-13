import 'dart:async'; // StreamController를 위해 추가
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

  /// --- 기존 메소드 (한 번에 전체 응답 받기) ---
  Future<Map<String, dynamic>> analyzeUserInput(String inputText, {Map<String, dynamic>? characterProfile}) async {
    try {
      print("🔹 Gemini 요청 (Unary): $inputText");
      final personaPrompt = _buildPersonaPrompt(inputText, characterProfile: characterProfile);
      final content = [Content.text(personaPrompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String geminiResponse = response.text!;
        print("✅ Gemini 응답 (Unary): $geminiResponse");
        return {"is_event": false, "response": geminiResponse};
      } else {
        print("⚠️ Gemini 응답 오류 (Unary): 응답이 비어 있습니다.");
        return {"is_event": false, "response": "Gemini로부터 빈 응답을 받았습니다."};
      }
    } catch (e) {
      print("❌ Gemini API 또는 네트워크 오류 (Unary): $e");
      return {"is_event": false, "response": "Gemini API 통신 중 오류가 발생했습니다."};
    }
  }

  /// --- ⬇️ 새로 추가된 스트리밍 메소드 ⬇️ ---
  /// 텍스트 응답을 실시간 스트림으로 반환합니다.
  Stream<String> analyzeUserInputStream(String inputText, {Map<String, dynamic>? characterProfile}) {
    print("🔹 Gemini 요청 (Stream): $inputText");
    final personaPrompt = _buildPersonaPrompt(inputText, characterProfile: characterProfile);
    final content = [Content.text(personaPrompt)];

    // generateContentStream을 호출하여 응답 스트림을 받습니다.
    final Stream<GenerateContentResponse> responseStream = _model.generateContentStream(content);

    // 각 응답(chunk)에서 텍스트만 추출하여 새로운 String 스트림으로 변환 후 반환합니다.
    return responseStream.map((chunk) {
      final text = chunk.text;
      if (text != null) {
        print("✅ Gemini 응답 (Stream chunk): $text");
        return text;
      }
      return '';
    }).handleError((e) {
      print("❌ Gemini API 또는 네트워크 오류 (Stream): $e");
      // 스트림에 에러를 전달할 수도 있습니다.
      // throw Exception("Gemini API 스트리밍 중 오류 발생");
    });
  }

  /// 페르소나 프롬프트를 생성하는 내부 헬퍼 메소드
  String _buildPersonaPrompt(String inputText, {Map<String, dynamic>? characterProfile}) {
    String personaPrompt;
    if (characterProfile != null &&
        characterProfile['name'] != null &&
        characterProfile['tags'] != null) {
      String characterName = characterProfile['name'] as String;
      List<String> tags = characterProfile['tags'] as List<String>;
      String tagsString = tags.join(', ');

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
      if (tags.contains('고양이') || characterName.contains('야옹이')) {
        personaPrompt += "\n말투는 ~다옹, ~냐옹 또는 캐릭터 이름의 특징을 살려서 말해줘.";
      } else if (tags.contains('로봇')) {
        personaPrompt += "\n너는 로봇이므로, 감정이 없는 딱딱한 말투를 사용해줘.";
      }

    } else {
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
    return "$personaPrompt\n\n[대화 시작]\n사용자: $inputText\n너:";
  }
}