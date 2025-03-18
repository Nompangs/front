import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("❌ Gemini API Key is missing.");
    }

    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<Map<String, dynamic>> analyzeUserInput(String inputText) async {
    try {
      print("🔹 Gemini 요청: $inputText");

      final prompt = """
      Analyze the user's command and determine whether it is an event request.
      If it is an event request, return the response in Google Calendar JSON format.
      If it is NOT an event request, respond with "This is not an event."

      **Important Rules:**
      - Convert relative dates like "tomorrow" or "next Monday" into absolute dates based on today's date.
      - If "next week" is mentioned, calculate the correct date for that week.
      - The date format should be YYYY-MM-DDTHH:mm:ss in 24-hour format.
      - If no time is provided, default to 09:00 AM.
      - The output should be in valid JSON format.

      **Examples:**
      - **Input:** "I have a meeting next Monday at 3 PM."
        **Output:**
        ```json
        {
          "event": {
            "title": "Meeting",
            "start": "2024-03-25T15:00:00",
            "end": "2024-03-25T16:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```
        
      - **Input:** "I have a meeting on April 5."
        **Output:**
        ```json
        {
          "event": {
            "title": "Meeting",
            "start": "2024-04-05T09:00:00",
            "end": "2024-04-05T10:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```

      **User input:** "$inputText"
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String geminiResponse = response.text!;
        print("✅ Gemini 응답: $geminiResponse");

        // ✅ Markdown 코드 블록 제거 (```json ... ```)
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
          Map<String, dynamic> parsedJson = jsonDecode(geminiResponse);
          return _adjustRelativeDates(parsedJson);
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

  /// ✅ 상대적 날짜 표현을 절대 날짜로 변환하는 함수
  Map<String, dynamic> _adjustRelativeDates(Map<String, dynamic> eventJson) {
    if (!eventJson.containsKey("event")) return eventJson;

    final event = eventJson["event"];
    if (event.containsKey("start")) {
      event["start"] = _convertRelativeDate(event["start"]);
    }
    if (event.containsKey("end")) {
      event["end"] = _convertRelativeDate(event["end"]);
    }
    return eventJson;
  }

  /// ✅ "next Monday" 같은 표현을 절대 날짜(YYYY-MM-DD)로 변환
  String _convertRelativeDate(String dateStr) {
    final now = DateTime.now();
    if (dateStr.contains("next")) {
      final weekdays = {
        "Monday": DateTime.monday,
        "Tuesday": DateTime.tuesday,
        "Wednesday": DateTime.wednesday,
        "Thursday": DateTime.thursday,
        "Friday": DateTime.friday,
        "Saturday": DateTime.saturday,
        "Sunday": DateTime.sunday,
      };

      for (var day in weekdays.keys) {
        if (dateStr.contains(day)) {
          DateTime nextDay = now.add(
            Duration(days: (7 - now.weekday + weekdays[day]!) % 7 + 7),
          );
          return DateFormat("yyyy-MM-ddTHH:mm:ss").format(nextDay);
        }
      }
    }
    return dateStr; // 변환할 필요가 없는 경우 원본 그대로 반환
  }
}
