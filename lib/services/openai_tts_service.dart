// lib/services/openai_tts_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAiTtsService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final AudioPlayer _audioPlayer = AudioPlayer();

  OpenAiTtsService() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('[TTS 서비스] 🚨 OPENAI_API_KEY가 설정되지 않았습니다.');
    }
  }

  Future<void> speak(String text) async {
    if (_apiKey == null || _apiKey!.isEmpty || text.trim().isEmpty) {
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
      final body = jsonEncode({'model': 'tts-1', 'input': text, 'voice': 'alloy'});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        await _audioPlayer.play(BytesSource(audioBytes, mimeType: 'audio/mpeg'));
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete();
      }
      rethrow;
    }
    
    return completer.future;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}