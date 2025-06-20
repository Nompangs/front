import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioStreamService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioStreamController =
      StreamController.broadcast();

  bool _isInitialized = false;

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 마이크 권한 요청
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _isInitialized = true;
    debugPrint("✅ AudioStreamService (flutter_sound) 초기화 완료");
  }

  Future<void> startStreaming() async {
    if (!_isInitialized) {
      throw Exception(
        "AudioStreamService not initialized. Call initialize() first.",
      );
    }
    if (_recorder.isRecording) {
      debugPrint("⚠️ 이미 녹음 중입니다.");
      return;
    }

    try {
      await _recorder.startRecorder(
        toStream: _audioStreamController.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      debugPrint("🎤 [AudioStreamService] 녹음 시작됨");
    } catch (e) {
      debugPrint("❌ 녹음 시작 실패: $e");
      rethrow;
    }
  }

  Future<void> stopStreaming() async {
    if (!_recorder.isRecording) return;

    try {
      await _recorder.stopRecorder();
      debugPrint("🛑 [AudioStreamService] 녹음 중지됨");
    } catch (e) {
      debugPrint("❌ 녹음 중지 실패: $e");
    }
  }

  void dispose() {
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    _recorder.closeRecorder();
    _audioStreamController.close();
    debugPrint("🧹 AudioStreamService (flutter_sound) 리소스 해제됨");
  }
}
