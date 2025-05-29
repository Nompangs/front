// lib/services/supertone_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
// 필요한 경우 audioplayers 또는 path_provider 등 추가 import
// import 'package:audioplayers/audioplayers.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'dart:typed_data';

class SupertoneService {
  String? _apiKey;
  final String _supertoneApiBaseUrl = "https://supertoneapi.com/v1/voices"; // Supertone API 문서에서 확인

  SupertoneService() {
    _apiKey = dotenv.env['x-sup-api-key']; // .env 파일에 정의된 키 이름 사용
    if (_apiKey == null) {
      print('🚨 x-sup-api-key가 .env 파일에 없거나 로드되지 않았습니다.');
    } else {
      print('✅ SupertoneService 초기화 성공: API 키 로드됨.');
    }
  }

  // 예시: TTS 요청 함수
  Future<void> speak(String text) async {
    if (_apiKey == null) {
      print('🚨 Supertone API 키가 로드되지 않았습니다. 음성 출력을 할 수 없습니다.');
      return;
    }
    if (text.isEmpty) {
      print('ℹ️ 음성으로 변환할 텍스트가 비어있습니다.');
      return;
    }

    // Supertone API 문서를 참고하여 실제 엔드포인트 URL로 변경하세요.
    final String ttsEndpoint = "$_supertoneApiBaseUrl/tts"; // 예시 엔드포인트

    // Supertone API 문서를 참고하여 요청 헤더 및 본문을 구성하세요.
    // 일반적으로 API 키는 'Authorization' 헤더나 'X-API-Key' 같은 커스텀 헤더에 포함됩니다.
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey', // 또는 'X-API-Key': _apiKey 등 API 명세에 따름
    };

    final requestBody = jsonEncode({
      'text': text,
      // Supertone API에서 요구하는 추가 파라미터들 (예: voice_model, language 등)
    });

    try {
      print('🔹 Supertone TTS 요청: "$text"');
      final response = await http.post(
        Uri.parse(ttsEndpoint),
        headers: headers,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        // 성공적으로 오디오 데이터를 받았다면, 처리 로직을 구현합니다.
        // 예: 바이트 데이터를 받아와서 audioplayers로 재생
        // final Uint8List audioBytes = response.bodyBytes;
        // print('✅ Supertone TTS 오디오 수신 (${audioBytes.lengthInBytes} 바이트)');
        // final tempDir = await getTemporaryDirectory();
        // final fileName = 'supertone_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        // final file = File('${tempDir.path}/$fileName');
        // await file.writeAsBytes(audioBytes);
        // print('✅ 오디오 파일 저장됨: ${file.path}');
        // await _audioPlayer.play(DeviceFileSource(file.path)); // _audioPlayer 인스턴스 필요
        print('✅ Supertone API 응답 성공');
        // 응답 처리 (예: JSON 파싱, 오디오 데이터 처리)
      } else {
        print('🚨 Supertone API 오류: ${response.statusCode}');
        print('🚨 응답 본문: ${response.body}');
      }
    } catch (e, s) {
      print('🚨 Supertone API 요청 또는 오디오 재생 중 예외 발생: $e');
      print('🚨 스택 트레이스: $s');
    }
  }

  // 다른 Supertone API 기능(예: 목소리 변환 등)을 위한 함수들을 여기에 추가할 수 있습니다.

  // AudioPlayer 인스턴스 및 dispose (필요한 경우)
  // final AudioPlayer _audioPlayer = AudioPlayer();
  // void dispose() {
  //   _audioPlayer.dispose();
  // }
}