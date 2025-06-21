import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nompangs/services/audio_stream_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/services/realtime_chat_service.dart';

// 챗 메시지를 위한 간단한 데이터 클래스
class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class ChatProvider with ChangeNotifier {
  // --- 서비스 ---
  final RealtimeChatService _realtimeChatService = RealtimeChatService();
  final OpenAiTtsService _ttsService = OpenAiTtsService();
  final AudioStreamService _audioStreamService = AudioStreamService();

  // --- 상태 변수 ---
  final List<ChatMessage> _messages = [];
  bool _isConnecting = true;
  bool _isProcessing = false; // STT 또는 TTS 처리 중
  String? _realtimeError;

  // --- 외부에서 접근할 Getter ---
  List<ChatMessage> get messages => _messages;
  bool get isConnecting => _isConnecting;
  bool get isProcessing => _isProcessing;
  String? get realtimeError => _realtimeError;

  // --- 페르소나 정보 ---
  late final String uuid;
  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;
  late final String userDisplayName;

  // 스트림 구독 관리
  StreamSubscription? _messageSubscription;
  StreamSubscription? _completionSubscription;

  // --- 생성자 ---
  ChatProvider({required Map<String, dynamic> characterProfile})
    : greeting = characterProfile['greeting'] as String? {
    // 페르소나 정보 초기화
    uuid =
        characterProfile['uuid'] ??
        'temp_uuid_${DateTime.now().millisecondsSinceEpoch}';
    characterName =
        characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음';
    characterHandle =
        '@${(characterProfile['aiPersonalityProfile']?['name'] ?? 'unknown').toLowerCase().replaceAll(' ', '')}';
    personalityTags =
        (characterProfile['personalityTags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        [];
    userDisplayName = characterProfile['userDisplayName'] ?? 'unknown';

    // 실시간 서비스 초기화
    _initializeServices(characterProfile);
  }

  // --- 초기화 로직 ---
  Future<void> _initializeServices(
    Map<String, dynamic> characterProfile,
  ) async {
    try {
      // 1. 오디오 서비스 초기화 (마이크 권한 요청 등)
      await _audioStreamService.initialize();

      // 2. 실시간 채팅 서비스 연결
      await _realtimeChatService.connect(characterProfile);
      _isConnecting = false;
      _realtimeError = null;

      // 3. 실시간 응답 스트림 구독 (UI 업데이트용)
      _messageSubscription?.cancel();
      _messageSubscription = _realtimeChatService.responseStream.listen(
        _onResponseReceived,
        onError: _onErrorReceived,
      );

      // 4. 완성된 문장 스트림 구독 (TTS 재생용)
      _completionSubscription?.cancel();
      _completionSubscription = _realtimeChatService.completionStream.listen(
        _onCompletionReceived,
      );

      // 5. 초기 인사말 처리
      _sendInitialGreetingIfNeeded();
    } catch (e) {
      _isConnecting = false;
      _realtimeError = "서비스 초기화에 실패했습니다: $e";
      debugPrint(_realtimeError);
    } finally {
      notifyListeners();
    }
  }

  // --- 메시지 처리 헬퍼 ---
  void addMessage(String text, String sender) {
    // UI 업데이트를 위해 메시지 추가
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, message); // 최신 메시지를 맨 앞에 추가
    notifyListeners();
  }

  // --- 스트림 리스너 ---
  void _onResponseReceived(String textChunk) {
    // AI 응답이 시작되면, 기존에 있던 (아마도 비어있는) AI 메시지를 찾아서 업데이트
    final lastMessage = _messages.isNotEmpty ? _messages.first : null;
    if (lastMessage != null && lastMessage.sender == 'bot') {
      final updatedMessage = ChatMessage(
        id: lastMessage.id,
        text: lastMessage.text + textChunk,
        sender: 'bot',
        timestamp: lastMessage.timestamp,
      );
      _messages[0] = updatedMessage;
    } else {
      // 새로운 AI 메시지 시작
      addMessage(textChunk, 'bot');
    }
    notifyListeners();
  }

  void _onCompletionReceived(String completedSentence) {
    debugPrint("✅ [ChatProvider] 완성된 문장 수신: $completedSentence");
    // STT->TTS 루프 방지를 위해, isProcessing(음성입력중)일 때는 자동재생 안함
    if (!_isProcessing) {
      _ttsService.speak(completedSentence);
    }
  }

  void _onErrorReceived(Object error) {
    _realtimeError = "실시간 응답 중 오류 발생: $error";
    addMessage("오류가 발생했습니다. 잠시 후 다시 시도해주세요.", 'bot');
    notifyListeners();
  }

  // --- 초기 인사말 ---
  void _sendInitialGreetingIfNeeded() {
    if (_messages.isEmpty && greeting != null && greeting!.isNotEmpty) {
      addMessage(greeting!, 'bot');
      _ttsService.speak(greeting!);
    }
  }

  // --- 공개 메서드 (텍스트) ---
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isConnecting || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      addMessage(text, 'user');
      await _realtimeChatService.sendMessage(text);
    } catch (e) {
      debugPrint("메시지 전송/처리 중 에러 발생: $e");
      _onErrorReceived(e);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // --- 공개 메서드 (오디오) ---
  Future<void> startAudioStreaming() async {
    if (_isConnecting || _isProcessing) return;

    _isProcessing = true;
    notifyListeners();

    try {
      // 이전 TTS 중지
      await _ttsService.stop();

      // 1. 오디오 스트림을 먼저 구독하고
      final audioStream = _audioStreamService.audioStream;
      // 2. 이 스트림을 실시간 서비스로 전달합니다. (Future를 기다리지 않음)
      _realtimeChatService.sendAudioStream(audioStream);

      // 3. 그런 다음 녹음을 시작합니다.
      await _audioStreamService.startStreaming();
    } catch (e) {
      debugPrint("오디오 스트리밍 시작/처리 중 에러 발생: $e");
      _onErrorReceived(e);
      // 에러 발생 시 처리 상태 복원
      _isProcessing = false;
      notifyListeners();
    }
    // 스트리밍이 중지될 때 isProcessing은 stopAudioStreaming에서 false로 바뀝니다.
  }

  Future<void> stopAudioStreaming() async {
    await _audioStreamService.stopStreaming();
    // 스트리밍이 중지되었으므로 처리 상태를 false로 설정합니다.
    if (_isProcessing) {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> stopTts() async {
    await _ttsService.stop();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _completionSubscription?.cancel();
    _realtimeChatService.dispose();
    _audioStreamService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
