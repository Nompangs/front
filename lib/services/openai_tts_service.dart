import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiTtsService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final http.Client _httpClient = http.Client();

  OpenAiTtsService() {
    if (_apiKey == null || _apiKey.isEmpty) {
      debugPrint('[TTS 서비스] 🚨 OPENAI_API_KEY가 설정되지 않았습니다.');
    }
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[TTS Service] Player State Changed: $state');
    });
  }

  Future<void> speak(String text, {String voice = 'alloy'}) async {
    debugPrint('[TTS Service] speak 호출됨. 텍스트: "$text", 목소리: "$voice"');
    if (_apiKey == null || _apiKey!.isEmpty || text.trim().isEmpty) {
      debugPrint('[TTS Service] 🚨 API 키가 없거나 텍스트가 비어있어 실행 중단.');
      return;
    }

    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.stop();
    }

    final completer = Completer<void>();
    StreamSubscription? subscription;

    subscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete();
        }
      }
    });

    try {
      final url = Uri.parse('https://api.openai.com/v1/audio/speech');
      final headers = {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'};
      final body = jsonEncode({'model': 'tts-1', 'input': text, 'voice': voice});

      final response = await _httpClient.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('[TTS Service] API 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        debugPrint('[TTS Service] 오디오 데이터 수신 완료 (${audioBytes.length} bytes). 재생 시도...');
        await _audioPlayer.play(BytesSource(audioBytes, mimeType: 'audio/mpeg'));
      } else {
        debugPrint('[TTS Service] 🚨 API 에러: ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('[TTS Service] 🚨 API 호출 시간 초과: $e');
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete();
      }
    } catch (e) {
      debugPrint('[TTS Service] 🚨 speak 함수 실행 중 예외 발생: $e');
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete();
      }
      rethrow;
    }

    return completer.future;
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    debugPrint('[TTS Service] 재생이 중단되었습니다.');
  }

  void dispose() {
    _audioPlayer.dispose();
    _httpClient.close();
  }
}