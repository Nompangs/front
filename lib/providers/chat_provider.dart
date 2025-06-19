import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nompangs/services/realtime_chat_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/services/database_service.dart';

class ChatMessage {
  String text;
  final bool isUser;
  bool isLoading;
  final String uuid;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.uuid,
    this.isLoading = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'content': text,
      'sender': isUser ? 'user' : 'ai',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      uuid: map['uuid'],
      text: map['content'],
      isUser: map['sender'] == 'user',
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final RealtimeChatService _realtimeChatService = RealtimeChatService();
  final OpenAiTtsService _openAiTtsService = OpenAiTtsService();
  final DatabaseService _databaseService = DatabaseService.instance;

  StreamSubscription<String>? _completionSubscription;
  StreamSubscription<ChatMessage>? _responseSubscription;

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  final String uuid;
  final String characterName;
  final String characterHandle;
  final List<String> personalityTags;
  final String? greeting;

  final Map<String, dynamic> _characterProfile;

  ChatProvider({required Map<String, dynamic> characterProfile})
    : _characterProfile = characterProfile,
      uuid =
          characterProfile['uuid'] ??
          'temp_uuid_${DateTime.now().millisecondsSinceEpoch}',
      characterName =
          characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음',
      characterHandle =
          '@${(characterProfile['aiPersonalityProfile']?['name'] ?? 'unknown').toLowerCase().replaceAll(' ', '')}',
      personalityTags =
          (characterProfile['personalityTags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
      greeting = characterProfile['greeting'] as String? {
    debugPrint('[ChatProvider] Received characterProfile: $characterProfile');
    debugPrint('[ChatProvider] UUID: ${characterProfile['uuid']}');
    debugPrint(
      '[ChatProvider] 캐릭터명: ${characterProfile['aiPersonalityProfile']?['name']}',
    );
    debugPrint('[ChatProvider] userInput 확인: ${characterProfile['userInput']}');
    debugPrint(
      '[ChatProvider] realtimeSettings 확인: ${characterProfile['realtimeSettings']}',
    );
    debugPrint(
      '[ChatProvider] aiPersonalityProfile 확인: ${characterProfile['aiPersonalityProfile']}',
    );
    debugPrint(
      '[ChatProvider] NPS 점수 개수: ${characterProfile['aiPersonalityProfile']?['npsScores']?.length ?? 0}',
    );
    debugPrint(
      '[ChatProvider] 매력적결함 개수: ${characterProfile['attractiveFlaws']?.length ?? 0}',
    );
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadHistory();

    // characterProfile 맵 전체를 connect 메서드에 전달합니다.
    await _realtimeChatService.connect(_characterProfile);

    if (_messages.isEmpty && greeting != null && greeting!.isNotEmpty) {
      _addMessage(greeting!, false, speak: true, saveToDb: true);
    }

    _completionSubscription = _realtimeChatService.completionStream.listen(
      (fullText) async {
        if (_messages.isNotEmpty && _messages.first.isLoading) {
          _messages.first.text = fullText;
          _messages.first.isLoading = false;
          await _databaseService.saveMessage(_messages.first.toMap());
          notifyListeners();
        }

        if (fullText.trim().isNotEmpty) {
          final realtimeSettings =
              _characterProfile['realtimeSettings'] as Map<String, dynamic>? ??
              {};
          final voice = realtimeSettings['voice'] as String? ?? 'alloy';
          // speak 함수에 voice 파라미터를 전달합니다.
          await _openAiTtsService.speak(fullText.trim(), voice: voice);
        }

        _isProcessing = false;
        notifyListeners();
      },
      onError: (e) {
        if (_messages.isNotEmpty && _messages.first.isLoading) {
          _messages.first.text = "AI 응답 중 오류가 발생했습니다: $e";
          _messages.first.isLoading = false;
        }
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  Future<void> _loadHistory() async {
    final history = await _databaseService.getHistory(uuid);
    _messages.clear();
    _messages.addAll(history.map((msg) => ChatMessage.fromMap(msg)));
    notifyListeners();
  }

  void _addMessage(
    String text,
    bool isUser, {
    bool speak = false,
    bool saveToDb = false,
  }) {
    final message = ChatMessage(text: text, isUser: isUser, uuid: uuid);
    _messages.insert(0, message);

    if (saveToDb) {
      _databaseService.saveMessage(message.toMap());
    }

    if (speak) {
      final realtimeSettings =
          _characterProfile['realtimeSettings'] as Map<String, dynamic>? ?? {};
      final voice = realtimeSettings['voice'] as String? ?? 'alloy';
      _openAiTtsService.speak(text, voice: voice);
    }
    notifyListeners();
  }

  Future<void> stopTts() async {
    await _openAiTtsService.stop();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isProcessing) return;

    await _openAiTtsService.stop();
    _addMessage(userInput, true, saveToDb: true);

    _isProcessing = true;
    _messages.insert(
      0,
      ChatMessage(text: '', isUser: false, uuid: uuid, isLoading: true),
    );
    notifyListeners();

    try {
      // 🔗 연결 상태 확인 후 필요시 재연결
      if (!_realtimeChatService.isConnected) {
        debugPrint("🔄 RealtimeAPI 재연결 시도...");
        await _realtimeChatService.connect(_characterProfile);

        // 재연결 후 안정화 대기 (최소화)
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await _realtimeChatService.sendMessage(userInput);
    } catch (e) {
      debugPrint("❌ 메시지 전송 실패: $e");

      // 연결 오류인 경우 한 번 더 재시도
      if (e.toString().contains('not connected')) {
        try {
          debugPrint("🔄 연결 오류로 인한 재시도...");
          await _realtimeChatService.connect(_characterProfile);
          await Future.delayed(const Duration(milliseconds: 500)); // 재시도 대기
          await _realtimeChatService.sendMessage(userInput);
          return; // 성공하면 return
        } catch (retryError) {
          debugPrint("❌ 재시도도 실패: $retryError");
        }
      }

      // 오류 메시지 표시
      if (_messages.isNotEmpty && _messages.first.isLoading) {
        _messages.first.text = "연결 오류가 발생했습니다. 잠시 후 다시 시도해주세요.";
        _messages.first.isLoading = false;
      }

      _isProcessing = false;
      notifyListeners();

      // 사용자에게 오류 알림 (필요시)
      rethrow;
    }
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    _responseSubscription?.cancel();
    _realtimeChatService.dispose();
    _openAiTtsService.dispose();
    super.dispose();
  }
}
