import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OpenAiTtsService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final http.Client _httpClient = http.Client();

  // [추가] 초기화 상태 관리를 위한 플래그
  bool _isPlayerInitialized = false;
  bool _isInitializing = false;

  // 🎵 캐릭터별 음성 설정 저장
  String _currentVoice = 'alloy';
  Map<String, dynamic>? _realtimeSettings;

  OpenAiTtsService() {
    if (_apiKey == null || _apiKey.isEmpty) {
      debugPrint('[TTS 서비스] 🚨 OPENAI_API_KEY가 설정되지 않았습니다.');
    }
  }

  // [수정] 중복 실행 방지 및 에러 핸들링 강화
  Future<void> initialize() async {
    if (_isPlayerInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      await _audioPlayer.openPlayer();
      _isPlayerInitialized = true;
      debugPrint('[TTS Service] FlutterSoundPlayer 초기화 완료.');
    } catch (e) {
      debugPrint('[TTS Service] 🚨 플레이어 초기화 중 오류 발생: $e');
      _isPlayerInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  // 🎵 캐릭터 프로필 설정 메서드 추가
  void setCharacterVoiceSettings(Map<String, dynamic> characterProfile) {
    _realtimeSettings =
        characterProfile['realtimeSettings'] as Map<String, dynamic>?;
    if (_realtimeSettings != null) {
      _currentVoice = _realtimeSettings!['voice'] ?? 'alloy';
      debugPrint('[TTS 서비스] 🎵 캐릭터 음성 설정됨: $_currentVoice');
      debugPrint(
        '[TTS 서비스] 🎵 음성 선택 이유: ${_realtimeSettings!['voiceRationale'] ?? '기본값'}',
      );
    }
  }

  Future<void> speak(String text, {String? voice}) async {
    // [수정] speak 호출 시점에 플레이어 초기화를 보장
    await initialize();

    if (!_isPlayerInitialized) {
      debugPrint('[TTS Service] 🚨 플레이어 초기화 실패로 speak 중단.');
      return;
    }

    final voiceToUse = voice ?? _currentVoice;
    debugPrint('[TTS Service] speak 호출됨. 텍스트: "$text", 목소리: "$voiceToUse"');
    if (_apiKey == null || _apiKey!.isEmpty || text.trim().isEmpty) {
      debugPrint('[TTS Service] 🚨 API 키가 없거나 텍스트가 비어있어 실행 중단.');
      return;
    }

    if (_audioPlayer.isPlaying) {
      await _audioPlayer.stopPlayer();
    }

    try {
      final url = Uri.parse('https://api.openai.com/v1/audio/speech');
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': voiceToUse,
      });

      final response = await _httpClient
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('[TTS Service] API 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Uint8List audioBytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/tts_audio.mp3';
        final file = File(filePath);
        await file.writeAsBytes(audioBytes, flush: true);

        debugPrint('[TTS Service] 오디오 파일 저장 완료 ($filePath). 재생 시도...');
        await _audioPlayer.startPlayer(
          fromURI: filePath,
          codec: Codec.mp3,
          whenFinished: () {
            debugPrint('[TTS Service] 재생 완료.');
          },
        );
      } else {
        debugPrint('[TTS Service] 🚨 API 에러: ${response.body}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[TTS Service] 🚨 speak 함수 실행 중 예외 발생: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    if (_isPlayerInitialized && _audioPlayer.isPlaying) {
      await _audioPlayer.stopPlayer();
      debugPrint('[TTS Service] 재생이 중단되었습니다.');
    }
  }

  void dispose() {
    if (_isPlayerInitialized) {
      _audioPlayer.closePlayer();
      _isPlayerInitialized = false;
    }
    _httpClient.close();
  }
}
