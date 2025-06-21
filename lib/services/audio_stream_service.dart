import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioStreamService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioStreamController =
      StreamController.broadcast();

  // [추가] 녹음된 오디오 청크를 모으는 리스트
  final List<Uint8List> _audioChunks = [];
  StreamSubscription? _recorderSubscription;

  bool _isInitialized = false;

  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  /// 현재 녹음(스트리밍) 중인지 여부를 반환합니다.
  bool get isStreaming => _recorder.isRecording;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder.openRecorder();
    _isInitialized = true;
    debugPrint("✅ AudioStreamService (flutter_sound) 초기화 완료");
  }

  Future<void> startStreaming() async {
    // [수정] 녹음 시작 시 항상 초기화 확인
    await initialize();

    if (_recorder.isRecording) {
      debugPrint("⚠️ 이미 녹음 중입니다.");
      return;
    }

    // [수정] 스트림을 컨트롤러로 보내고, 동시에 리스트에 청크를 저장합니다.
    _recorderSubscription = _audioStreamController.stream.listen((chunk) {
      _audioChunks.add(chunk);
    });

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

  // [수정] 녹음을 중지하고, 저장된 오디오 파일의 경로를 반환합니다.
  Future<String?> stopStreaming() async {
    if (!_recorder.isRecording) return null;

    await _recorder.stopRecorder();
    await _recorderSubscription?.cancel(); // 리스너 정리
    debugPrint("🛑 [AudioStreamService] 녹음 중지됨. 파일 생성 시작...");

    // [추가] 녹음기 자원 즉시 해제
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
      debugPrint("🎤 [AudioStreamService] 녹음기 자원 해제 완료.");
    }

    if (_audioChunks.isEmpty) {
      debugPrint("⚠️ 녹음된 오디오 데이터가 없습니다.");
      return null;
    }

    // 모든 오디오 청크를 하나의 Uint8List로 합칩니다.
    final totalBytes = _audioChunks
        .map((c) => c.length)
        .reduce((a, b) => a + b);
    final combinedChunks = Uint8List(totalBytes);
    int offset = 0;
    for (final chunk in _audioChunks) {
      combinedChunks.setAll(offset, chunk);
      offset += chunk.length;
    }
    _audioChunks.clear(); // 메모리 정리

    // WAV 파일 헤더를 생성합니다.
    final header = _createWavHeader(combinedChunks.length);

    // 헤더와 오디오 데이터를 합칩니다.
    final wavBytes = Uint8List(header.length + combinedChunks.length);
    wavBytes.setAll(0, header);
    wavBytes.setAll(header.length, combinedChunks);

    // 파일을 저장합니다.
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/user_audio.wav';
      final file = File(filePath);
      await file.writeAsBytes(wavBytes, flush: true);
      debugPrint("✅ [AudioStreamService] WAV 파일 저장 완료: $filePath");
      return filePath;
    } catch (e) {
      debugPrint("❌ [AudioStreamService] 파일 저장 실패: $e");
      return null;
    }
  }

  void dispose() {
    _recorderSubscription?.cancel();
    if (_recorder.isRecording) {
      _recorder.stopRecorder();
    }
    // [수정] dispose 시에는 컨트롤러만 닫도록 변경 (closeRecorder는 stopStreaming으로 이동)
    _audioStreamController.close();
    debugPrint("🧹 AudioStreamService (flutter_sound) 리소스 해제됨");
  }

  // PCM 데이터를 위한 WAV 파일 헤더를 생성하는 헬퍼 함수
  Uint8List _createWavHeader(int dataLength) {
    final byteData = ByteData(44);
    final sampleRate = 16000;
    final numChannels = 1;
    final bitsPerSample = 16;
    final blockAlign = (numChannels * bitsPerSample) ~/ 8;
    final byteRate = sampleRate * blockAlign;

    // RIFF chunk
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, dataLength + 36, Endian.little);

    // WAVE format
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6d); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Sub-chunk1Size
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1=PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // 'data' sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataLength, Endian.little);

    return byteData.buffer.asUint8List();
  }
}
