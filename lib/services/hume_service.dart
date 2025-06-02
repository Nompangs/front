import 'dart:convert'; 
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async'; 

class HumeAiTtsService {
  String? _apiKey;
  
  final String _humeApiTtsStreamFileEndpoint = "https://api.hume.ai/v0/tts/stream/file";

  final AudioPlayer _audioPlayer = AudioPlayer();
  http.Client _httpClient; // 스트리밍 요청을 위해 http.Client 인스턴스 사용

  HumeAiTtsService() : _httpClient = http.Client() { // 생성자에서 httpClient 초기화
    _apiKey = dotenv.env['HUME_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('🚨 Hume AI API 키가 .env 파일에 없거나 비어있습니다.');
    } else {
      print('✅ HumeAiTtsService 초기화 성공 (스트리밍 파일 응답 모드).');
    }
  }

  Future<void> speak(String text, {String? voiceId}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('🚨 Hume AI API 키가 설정되지 않았습니다.');
      return;
    }
    if (text.isEmpty) {
      print('ℹ️ 음성으로 변환할 텍스트가 비어있습니다.');
      return;
    }

    final headers = {
      'Content-Type': 'application/json', // 요청 본문이 JSON인 경우
      'X-Hume-Api-Key': _apiKey!,
      // 'Accept': 'audio/mpeg', // 스트리밍 시에도 받을 포맷 명시 가능 (Hume AI 문서 확인)
    };

    final requestBodyMap = {
      'utterances': [{'text': text}],
      
    };
    final requestBodyJson = jsonEncode(requestBodyMap);

    // 스트리밍 요청 생성
    final request = http.Request('POST', Uri.parse(_humeApiTtsStreamFileEndpoint));
    request.headers.addAll(headers);
    request.body = requestBodyJson;

    // BytesBuilder를 사용하여 수신되는 오디오 청크를 모음
    final BytesBuilder audioBytesBuilder = BytesBuilder();
    StreamSubscription<List<int>>? subscription; // 스트림 구독 관리
    final Completer<void> completer = Completer<void>(); // 작업 완료 신호

    try {
      print('🔹 Hume AI TTS (스트리밍 파일) 요청 시작: "$text"');
      print('🔹 요청 URL: $_humeApiTtsStreamFileEndpoint');

      final http.StreamedResponse streamedResponse = await _httpClient.send(request);

      print('🔸 Hume AI TTS 스트리밍 응답 상태 코드: ${streamedResponse.statusCode}');
      print('🔸 Hume AI TTS 스트리밍 응답 헤더: ${streamedResponse.headers}');

      if (streamedResponse.statusCode == 200) {
        print('🎧 오디오 스트림 수신 시작...');
        subscription = streamedResponse.stream.listen(
          (List<int> chunk) {
            // print('Received chunk: ${chunk.length} bytes'); // 각 청크 크기 로깅 (디버깅용)
            audioBytesBuilder.add(chunk); // 수신된 청크를 BytesBuilder에 추가
          },
          onDone: () async {
            print('✅ 오디오 스트림 수신 완료.');
            final Uint8List finalAudioBytes = audioBytesBuilder.toBytes(); // 모든 청크를 합쳐 Uint8List로 변환
            print('✅ 최종 오디오 데이터 크기: ${finalAudioBytes.lengthInBytes} 바이트');

            if (finalAudioBytes.isEmpty) {
              print('🚨 수신된 최종 오디오 데이터가 비어있습니다.');
              if (!completer.isCompleted) completer.completeError(Exception("Empty audio data received"));
              return;
            }

            final tempDir = await getTemporaryDirectory();
            String fileExtension = ".mp3"; // 기본값, 실제 응답 헤더나 API 스펙에 따라 결정
            final contentType = streamedResponse.headers['content-type'];
            if (contentType != null) {
                if (contentType.contains("mpeg")) fileExtension = ".mp3";
                else if (contentType.contains("wav")) fileExtension = ".wav";
                else if (contentType.contains("ogg")) fileExtension = ".ogg";
            }
            final fileName = 'hume_tts_stream_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
            final file = File('${tempDir.path}/$fileName');

            await file.writeAsBytes(finalAudioBytes);
            print('✅ 스트리밍 오디오 파일 임시 저장 완료: ${file.path}');

            await _audioPlayer.play(DeviceFileSource(file.path));
            print('✅ Hume AI TTS 스트리밍 오디오 재생 성공');
            if (!completer.isCompleted) completer.complete();
          },
          onError: (error, stackTrace) {
            print('🚨 오디오 스트림 수신 중 오류 발생: $error');
            print('🚨 스택 트레이스 (스트림 오류): $stackTrace');
            if (!completer.isCompleted) completer.completeError(error);
          },
          cancelOnError: true, // 오류 발생 시 스트림 자동 취소
        );
      } else {
        print('🚨 Hume AI API (스트리밍 파일) 오류: ${streamedResponse.statusCode}');
        final errorBody = await streamedResponse.stream.bytesToString();
        print('🚨 오류 응답 본문 (스트리밍): $errorBody');
        if (!completer.isCompleted) completer.completeError(Exception("API Error: ${streamedResponse.statusCode} - $errorBody"));
      }
    } catch (e, s) {
      print('🚨 Hume AI API (스트리밍 파일) 요청 준비 또는 전송 중 예외 발생: $e');
      print('🚨 스택 트레이스 (요청 예외): $s');
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future; // speak 메소드가 스트림 처리가 완료될 때까지 기다리도록 Future 반환
  }

  void dispose() {
    _audioPlayer.dispose();
    _httpClient.close(); // http.Client 사용 후에는 close() 호출
    print('HumeAiTtsService disposed.');
  }
}