import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiTtsService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final AudioPlayer _audioPlayer = AudioPlayer();

  OpenAiTtsService() {
    if (_apiKey == null || _apiKey.isEmpty) {
      debugPrint('[TTS 서비스] 🚨 OPENAI_API_KEY가 설정되지 않았습니다.');
    }
  }

  Future<void> speak(String text) async {
    debugPrint('[TTS Service] speak 호출됨. 텍스트: "$text"');
    if (_apiKey == null || _apiKey!.isEmpty || text.trim().isEmpty) {
      debugPrint('[TTS Service] 🚨 API 키가 없거나 텍스트가 비어있어 실행 중단.');
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
      final body = jsonEncode({'model': 'tts-1', 'input': text, 'voice': 'alloy'});

      final response = await http.post(url, headers: headers, body: body);
      debugPrint('[TTS Service] API 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        debugPrint('[TTS Service] 오디오 데이터 수신 완료 (${audioBytes.length} bytes). 재생 시도...');
        await _audioPlayer.play(BytesSource(audioBytes, mimeType: 'audio/mpeg'));
      } else {
        debugPrint('[TTS Service] 🚨 API 에러: ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TTS Service] 🚨 speak 함수 실행 중 예외 발생: $e');
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete();
      }
      rethrow;
    }
    
    return completer.future;
  }

  Future<void> stop() async {
    // audioplayers 패키지의 stop() 메서드를 호출합니다.
    await _audioPlayer.stop();
    debugPrint('[TTS Service] 재생이 중단되었습니다.');
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}