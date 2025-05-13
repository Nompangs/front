import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class GeminiService {
  late final GenerativeModel _model;
  // 오늘 날짜를 프롬프트에 포함시키기 위해 추가
  final String todayDate;

  GeminiService()
    : todayDate = DateFormat("yyyy-MM-dd").format(DateTime.now()) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception("❌ Gemini API 키가 없습니다.");
    }

    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  }

  Future<Map<String, dynamic>> analyzeUserInput(String inputText) async {
    try {
      print("🔹 Gemini 요청 (한국어): $inputText");

      final prompt = """
      사용자의 한국어 명령을 분석하여 일정 등록 요청인지 판단합니다.
      오늘은 $todayDate 입니다. 이 날짜를 기준으로 상대적인 날짜 표현(예: "내일", "다음 주 월요일")을 절대 날짜로 변환해야 합니다.

      만약 일정 등록 요청이라면, 분석된 내용을 바탕으로 Google Calendar JSON 형식으로 응답해주세요.
      일정 등록 요청이 아니라면, "일정 요청이 아닙니다." 라고 응답해주세요.

      **중요 규칙:**
      - "내일", "모레", "다음 주 월요일", "이번 주 금요일" 등과 같은 상대적인 날짜 표현을 오늘($todayDate)을 기준으로 정확한 절대 날짜(YYYY-MM-DD)로 변환해야 합니다.
      - 시간 정보가 주어지지 않으면 기본으로 오전 9시 (09:00:00)로 설정합니다.
      - 종료 시간은 시작 시간으로부터 1시간 뒤로 설정합니다. (예: 시작이 09:00:00이면 종료는 10:00:00)
      - 날짜 및 시간 형식은 'YYYY-MM-DDTHH:mm:ss' 이어야 하며, 24시간 형식을 사용합니다.
      - 타임존은 항상 "Asia/Seoul"로 설정합니다.
      - 출력은 유효한 JSON 형식이어야 합니다.

      **예시 (오늘이 $todayDate 라고 가정):**

      - **사용자 입력:** "내일 오후 3시에 회의 있어."
        **기대 출력:**
        ```json
        {
          "event": {
            "title": "회의",
            "start": "${DateFormat("yyyy-MM-dd").format(DateTime.now().add(Duration(days: 1)))}T15:00:00",
            "end": "${DateFormat("yyyy-MM-dd").format(DateTime.now().add(Duration(days: 1)))}T16:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```

      - **사용자 입력:** "다음 주 월요일에 치과 예약했어." (시간 언급 없음)
        **기대 출력 (오늘이 ${DateFormat("yyyy-MM-dd EEEE").format(DateTime.now())}이라고 가정하고, 다음 주 월요일 계산 필요):**
        ```json
        {
          "event": {
            "title": "치과 예약",
            "start": "[계산된_다음_주_월요일_YYYY-MM-DD]T09:00:00",
            "end": "[계산된_다음_주_월요일_YYYY-MM-DD]T10:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```
        (참고: 위 예시의 [계산된_다음_주_월요일_YYYY-MM-DD] 부분은 실제 날짜로 대체되어야 합니다. Gemini가 이를 계산하도록 지시합니다.)

      - **사용자 입력:** "엄마 생신 다음 달 5일"
        **기대 출력 (시간 언급 없음, 다음 달 5일 계산 필요):**
        ```json
        {
          "event": {
            "title": "엄마 생신",
            "start": "[계산된_다음_달_5일_YYYY-MM-DD]T09:00:00",
            "end": "[계산된_다음_달_5일_YYYY-MM-DD]T10:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```

      - **사용자 입력:** "오늘 저녁 7시에 친구랑 약속"
        **기대 출력:**
        ```json
        {
          "event": {
            "title": "친구랑 약속",
            "start": "${DateFormat("yyyy-MM-dd").format(DateTime.now())}T19:00:00",
            "end": "${DateFormat("yyyy-MM-dd").format(DateTime.now())}T20:00:00",
            "timezone": "Asia/Seoul"
          }
        }
        ```

      - **사용자 입력:** "오늘 날씨 어때?"
        **기대 출력:**
        ```json
        {
          "is_event": false,
          "message": "일정 요청이 아닙니다."
        }
        ```

      **사용자 입력:** "$inputText"
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        String geminiResponse = response.text!;
        print("✅ Gemini 응답: $geminiResponse");

        geminiResponse =
            geminiResponse
                .replaceAll("```json", "")
                .replaceAll("```", "")
                .trim();

        // Gemini가 "일정 요청이 아닙니다." 와 같은 텍스트를 JSON의 일부로 반환하도록 유도
        try {
          Map<String, dynamic> parsedJson = jsonDecode(geminiResponse);
          if (parsedJson.containsKey("is_event") &&
              parsedJson["is_event"] == false) {
            return {
              "is_event": false,
              "message": parsedJson["message"] ?? "일정 요청이 아닙니다.",
            };
          }

          if (parsedJson.containsKey("event")) {
            // Gemini가 title을 잘 추출하지 못할 경우, inputText에서 간단히 가져오는 로직
            if (!parsedJson["event"].containsKey("title") ||
                parsedJson["event"]["title"].isEmpty) {
              // 간단한 제목 추출 로직
              parsedJson["event"]["title"] =
                  inputText.length > 20
                      ? inputText.substring(0, 20)
                      : inputText;
            }
            return {"is_event": true, ...parsedJson};
          } else {
            // event 키가 없는 경우, 일정 요청이 아닌 것으로 간주
            return {
              "is_event": false,
              "message": "응답에서 'event' 정보를 찾을 수 없습니다.",
            };
          }
        } catch (e) {
          print("❌ JSON Parsing Error: $e. 응답: $geminiResponse");
          // 파싱 오류가 발생했지만, Gemini가 "일정 요청이 아닙니다"와 유사한 메시지를 보냈을 수 있음
          if (geminiResponse.contains("일정 요청이 아닙니다")) {
            return {"is_event": false, "message": "일정 요청이 아닙니다."};
          }
          return {"is_event": false, "message": "JSON 파싱 오류가 발생했습니다."};
        }
      } else {
        print("⚠️ Gemini 응답 오류: 응답이 비어 있습니다.");
        return {"is_event": false, "message": "Gemini로부터 빈 응답을 받았습니다."};
      }
    } catch (e) {
      print("❌ Gemini API 또는 네트워크 오류: $e");
      return {"is_event": false, "message": "Gemini API 통신 중 오류가 발생했습니다."};
    }
  }
}
