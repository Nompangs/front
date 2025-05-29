import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SupertoneService {
  String? _apiKey;
  final String _supertoneApiBaseUrl = "https://supertoneapi.com"; 
  final AudioPlayer _audioPlayer = AudioPlayer();

  SupertoneService() {
    _apiKey = dotenv.env['x-sup-api-key'];
    if (_apiKey == null) {
      print('🚨 x-sup-api-key가 .env 파일에 없거나 로드되지 않았습니다.');
    } else {
      print('✅ SupertoneService 초기화 성공: API 키 로드됨.');
    }
  }
  
  Future<void> speak(String text, {String voiceId = "e5f6fb1a53d0add87afb4f"}) async {
    if (_apiKey == null) {
      print('🚨 Supertone API 키가 로드되지 않았습니다. 음성 출력을 할 수 없습니다.');
      return;
    }
    if (text.isEmpty) {
      print('ℹ️ 음성으로 변환할 텍스트가 비어있습니다.');
      return;
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
      print('🔹 Supertone TTS 요청: "$text"');
      final response = await http.post(
        Uri.parse(ttsEndpoint),
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        print('✅ Supertone TTS 오디오 수신 (${audioBytes.lengthInBytes} 바이트)');
        final tempDir = await getTemporaryDirectory();
        final fileName = 'supertone_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(audioBytes);
        print('✅ 오디오 파일 저장됨: ${file.path}');
        await _audioPlayer.play(DeviceFileSource(file.path)); 
        print('✅ Supertone API 응답 성공');
      } else {
        print('🚨 Supertone API 오류: ${response.statusCode}');
        print('🚨 응답 본문: ${response.body}');
      }
    } catch (e, s) {
      print('🚨 Supertone API 요청 또는 오디오 재생 중 예외 발생: $e');
      print('🚨 스택 트레이스: $s');
    }
  }
}