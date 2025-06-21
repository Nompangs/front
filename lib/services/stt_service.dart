import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SttService {
  bool _isInitialized = false;

  SttService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("OpenAI API 키가 .env 파일에 없습니다.");
      }
      OpenAI.apiKey = apiKey;
      _isInitialized = true;
      debugPrint("✅ SttService 초기화 완료");
    } catch (e) {
      debugPrint("❌ SttService 초기화 실패: $e");
    }
  }

  Future<String> transcribeAudio(String filePath) async {
    if (!_isInitialized) {
      debugPrint("⚠️ SttService가 초기화되지 않았습니다.");
      await _initialize();
      if (!_isInitialized) return ""; // 재시도 후에도 실패하면 빈 문자열 반환
    }

    try {
      debugPrint("🗣️ [SttService] 오디오 파일 STT 시작: $filePath");
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("오디오 파일이 존재하지 않습니다: $filePath");
      }

      final transcription = await OpenAI.instance.audio.createTranscription(
        file: file,
        model: "whisper-1",
        responseFormat: OpenAIAudioResponseFormat.json,
      );

      debugPrint("✅ [SttService] STT 완료: ${transcription.text}");
      return transcription.text;
    } on RequestFailedException catch (e) {
      debugPrint("❌ [SttService] OpenAI API 요청 실패: ${e.message}");
      return "";
    } catch (e) {
      debugPrint("❌ [SttService] 오디오 변환 중 알 수 없는 오류: $e");
      return "";
    }
  }
}
