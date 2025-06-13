// lib/services/elevenlabs_tts_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ElevenLabsTtsService {
  final String? _apiKey = dotenv.env['ELEVENLABS_API_KEY'];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Default voice ID (Rachel - a popular ElevenLabs voice)
  static const String _defaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';

  ElevenLabsTtsService() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('[ElevenLabs TTS 서비스] 🚨 ELEVENLABS_API_KEY가 설정되지 않았습니다.');
    }
  }

  Future<void> speak(String text, {String? voiceId}) async {
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
      final selectedVoiceId = voiceId ?? _defaultVoiceId;
      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$selectedVoiceId',
      );
      final headers = {
        'xi-api-key': _apiKey!,
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {'stability': 0.5, 'similarity_boost': 0.5},
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        await _audioPlayer.play(
          BytesSource(audioBytes, mimeType: 'audio/mpeg'),
        );
      } else {
        throw Exception('ElevenLabs API Error: ${response.statusCode}');
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
