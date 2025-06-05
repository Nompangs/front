// lib/services/supertone_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class SupertoneService {
  String? _apiKey;
  final String _supertoneApiBaseUrl = "https://supertoneapi.com";
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateSubscription;
  bool _isApiRequestInProgress = false; // API 요청 중복 방지 플래그

  SupertoneService() {
    _apiKey = dotenv.env['x-sup-api-key'];
    if (_apiKey == null) {
      print('[SupertoneService][${defaultTargetPlatform.name}] 🚨 API 키가 로드되지 않았습니다.');
    }
    _initAudioPlayerListener();
  }

  void _initAudioPlayerListener() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      _playerState = s;
    });
  }

  Future<void> speak(String text, {String voiceId = "e5f6fb1a53d0add87afb4f"}) async {
    final String platform = defaultTargetPlatform.name;
    final String logText = text.length > 30 ? "${text.substring(0, 30)}..." : text;
    print('[SupertoneService][$platform] speak 호출 시작. Text: "$logText"'); 

    if (_apiKey == null || text.isEmpty) {
      print('[SupertoneService][$platform] API 키 없거나 텍스트 비어있음. 종료. (Text: "$logText")'); 
      return;
    }

    if (_isApiRequestInProgress) {
      print('[SupertoneService][$platform] 이미 다른 TTS API 요청 처리 중 ("$logText"). 새 요청 무시.'); 
      return;
    }
    _isApiRequestInProgress = true;
    
    if (_playerState == PlayerState.playing) {
      print('[SupertoneService][$platform] 이전 음성 재생 중, 중지 시도. (Text: "$logText")'); 
      await _audioPlayer.stop();
    }
    final String ttsEndpoint = "$_supertoneApiBaseUrl/v1/text-to-speech/$voiceId";
    final headers = {
      'Content-Type': 'application/json',
      'x-sup-api-key': _apiKey!,
    };
    final requestBody = jsonEncode({
      'text': text,
      "language": "ko",
      "style": "neutral",
      "model": "sona_speech_1"
    });
    try {
      
      final response = await http.post(
        Uri.parse(ttsEndpoint),
        headers: headers,
        body: requestBody,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        
        final tempDir = await getTemporaryDirectory();
        final fileName = 'supertone_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(audioBytes);
        
        if (_playerState == PlayerState.playing) {
          
          await _audioPlayer.stop();
        }

        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.play(DeviceFileSource(file.path));
        print('[SupertoneService][$platform] ✅ 오디오 재생 시작됨 (Text: "$logText").');
        await _audioPlayer.onPlayerComplete.first;
      } else {
        print('[SupertoneService][$platform] 🚨 API 오류: ${response.statusCode}, Body: ${response.body} (Text: "$logText")'); 
      }
    } on TimeoutException catch (e, s) {
      print('[SupertoneService][$platform] 🚨 API 요청 타임아웃: $e (Text: "$logText")'); 
      
    } catch (e, s) {
      print('[SupertoneService][$platform] 🚨 API 요청/오디오 재생 예외: $e (Text: "$logText")'); 
      
    } finally {
      _isApiRequestInProgress = false;
      
    }
  }

  void dispose() {
    final String platform = defaultTargetPlatform.name;
    print('[SupertoneService][$platform] dispose 호출됨.'); 
    _playerStateSubscription?.cancel();
    _audioPlayer.release();
    _audioPlayer.dispose();
  }
}