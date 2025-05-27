import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ZyphraTtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _apiKey;
  final String _zyphraApiUrl = 'http://api.zyphra.com/v1/audio/text-to-speech';

  ZyphraTtsService() {
    _apiKey = dotenv.env['ZYPHRA_API_KEY'];
    if (_apiKey == null) {
      print('🚨 ZYPHRA_API_KEY가 .env 파일에 없거나 로드되지 않았습니다. (ZyphraTtsService 생성자)');
      print("현재 dotenv.env 내용 (ZyphraTtsService 생성자): ${dotenv.env}");
    } else {
      print('✅ ZyphraTtsService 초기화 성공: API 키 로드됨. (ZyphraTtsService 생성자)');
    }

  }

  Future<void> speak(String text, {String languageCode = "ko"}) async {
    if (_apiKey == null) {
      print('🚨 Zyphra API 키가 로드되지 않았습니다. 음성 출력을 할 수 없습니다.');
      return;
    }
    if (text.isEmpty) {
      print('ℹ️ 음성으로 변환할 텍스트가 비어있습니다.');
      return;
    }

    final requestBody = jsonEncode({
      'text': text,
      'model': 'zonos-v0.1-transformer',
      'speaking_rate': 15,
      'language_iso_code': languageCode,
      'mime_type': 'audio/mp3'
    });

    try {
      print('🔹 Zyphra TTS 요청: "$text"');
      print('🔹 요청 본문: $requestBody');

      final response = await http.post(
        Uri.parse(_zyphraApiUrl),
        headers: {
          'X-API-Key': _apiKey!,
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        print('✅ Zyphra TTS 오디오 수신 (${audioBytes.lengthInBytes} 바이트)');

        final tempDir = await getTemporaryDirectory();
        final fileName = 'tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(audioBytes);
        print('✅ 오디오 파일 저장됨: ${file.path}');

        if (_audioPlayer.state == PlayerState.playing) { // PlayerState enum은 audioplayers 임포트 필요
          await _audioPlayer.stop();
          print('🎧 이전 오디오 중지됨.');
        }
        await _audioPlayer.play(DeviceFileSource(file.path));
        print('▶️ 저장된 오디오 파일 재생 시도: ${file.path}');

      } else {
        print('🚨 Zyphra TTS API 오류: ${response.statusCode}');
        print('🚨 응답 본문: ${response.body}');
      }
    } catch (e, s) {
      print('🚨 Zyphra TTS 요청 또는 오디오 재생 중 예외 발생: $e');
      print('🚨 스택 트레이스: $s');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}