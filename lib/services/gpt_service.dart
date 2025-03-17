import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GPTService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> sendToGPT(String inputText) async {
    if (apiKey.isEmpty) return "오류: API Key가 누락되었습니다.";

    final String apiUrl = "https://api.openai.com/v1/chat/completions";

    try {
      print("GPT 요청: $inputText"); // 터미널 로그
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": inputText},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String gptResponse = responseData['choices'][0]['message']['content'];
        print("GPT 응답: $gptResponse");
        return gptResponse;
      } else {
        print("GPT 오류: ${response.body}");
        return "GPT 응답 오류: ${response.body}";
      }
    } catch (e) {
      print("네트워크 오류: $e");
      return "네트워크 오류 발생: $e";
    }
  }
}
