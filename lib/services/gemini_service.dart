import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("오류: Gemini API Key가 누락되었습니다.");
    }

    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<Map<String, dynamic>> analyzeUserInput(String inputText) async {
    try {
      print("🔹 Gemini 일정 분석 요청: $inputText");

      final prompt = """
      Analyze the user's command to determine whether it is an event addition request.
      - If it is an event request, return the response in Google Calendar JSON format.
      - If it is NOT an event request, respond with "This is not an event."

      Additional rule:
      - If the user provides only a date without a time, set the default time to 9:00 AM - 10:00 AM.

      Example:
      Input: "I have a meeting tomorrow at 3 PM."
      Output:
      {
        "event": {
          "title": "Meeting",
          "start": "2024-03-20T15:00:00",
          "end": "2024-03-20T16:00:00",
          "timezone": "Asia/Seoul"
        }
      }

      Input: "I have a meeting on March 25."
      Output:
      {
        "event": {
          "title": "Meeting",
          "start": "2024-03-25T09:00:00",
          "end": "2024-03-25T10:00:00",
          "timezone": "Asia/Seoul"
        }
      }

      Input: "What should I eat today?"
      Output:
      "This is not an event."

      User input: "$inputText"
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String geminiResponse = response.text!;
        print("✅ Gemini 응답: $geminiResponse");

        // ✅ Markdown 코드 블록 제거
        geminiResponse =
            geminiResponse
                .replaceAll("```json", "")
                .replaceAll("```", "")
                .trim();

        // ✅ 일정이 아닌 경우 처리
        if (geminiResponse.contains("This is not an event.")) {
          return {"is_event": false};
        }

        // ✅ JSON 파싱 시 예외 처리
        try {
          return jsonDecode(geminiResponse);
        } catch (e) {
          print("❌ JSON Parsing Error: $e");
          return {"is_event": false}; // 일정이 아니라고 판단
        }
      } else {
        print("⚠️ Gemini 응답 오류: 응답이 비어 있습니다.");
        return {"is_event": false};
      }
    } catch (e) {
      print("❌ Gemini 네트워크 오류: $e");
      return {"is_event": false};
    }
  }
}
