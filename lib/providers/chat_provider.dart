import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nompangs/services/realtime_chat_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/services/database_service.dart';

// ChatMessage 클래스 수정
class ChatMessage {
  String text;
  final bool isUser;
  bool isLoading;
  final String uuid; // 어떤 사물(페르소나)과의 대화인지 식별

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.uuid,
    this.isLoading = false,
  });

  // DB 저장을 위해 Map으로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'content': text,
      'sender': isUser ? 'user' : 'ai',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // DB에서 읽은 Map을 ChatMessage 객체로 변환하는 factory 생성자
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      uuid: map['uuid'],
      text: map['content'],
      isUser: map['sender'] == 'user',
      // timestamp는 ChatProvider에서 정렬용으로만 사용되므로 여기선 직접 사용하지 않음
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final RealtimeChatService _realtimeChatService = RealtimeChatService();
  final OpenAiTtsService _openAiTtsService = OpenAiTtsService();
  final DatabaseService _databaseService = DatabaseService.instance; // DB 서비스 인스턴스
  
  // 스트림 구독 관리
  StreamSubscription<String>? _completionSubscription;

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;
  final String uuid; // 페르소나의 고유 ID

  ChatProvider({
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
    this.greeting,
    required this.uuid, // 생성자에서 uuid를 받음
  }) {
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    // 1. 데이터베이스에서 과거 대화 기록을 먼저 불러옵니다.
    await _loadHistory();

    final characterProfile = {
      'name': characterName,
      'tags': personalityTags,
      'greeting': greeting,
    };
    await _realtimeChatService.connect(characterProfile);

    // 2. 기록을 모두 불러온 후, 메시지가 정말 하나도 없을 때만 인사말을 추가합니다.
    if (_messages.isEmpty && greeting != null && greeting!.isNotEmpty) {
      _addMessage(greeting!, false, speak: true);
    }

    // AI의 실시간 응답(텍스트 조각)을 처리하는 리스너
    _realtimeChatService.responseStream.listen((deltaText) {
      if (_messages.isNotEmpty && _messages.first.isLoading) {
        _messages.first.text = deltaText;
        notifyListeners();
      }
    });

    _completionSubscription = _realtimeChatService.completionStream.listen((fullText) async {
        if (_messages.isNotEmpty && _messages.first.isLoading) {
          _messages.first.text = fullText;
          _messages.first.isLoading = false;
          
          // AI 응답이 완료되면 DB에 저장
          await _databaseService.saveMessage(_messages.first.toMap());
          notifyListeners();

          if (fullText.trim().isNotEmpty) {
            await _openAiTtsService.speak(fullText.trim());
          }
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
    });
  }

  // DB에서 과거 기록을 불러오는 메서드
  Future<void> _loadHistory() async {
    final history = await _databaseService.getHistory(uuid);
    _messages.clear(); // 불러오기 전에 기존 메시지 초기화
    _messages.addAll(history.map((msg) => ChatMessage.fromMap(msg)));
    notifyListeners();
  }

  void _addMessage(String text, bool isUser, {bool speak = false}) {
    final message = ChatMessage(text: text, isUser: isUser, uuid: uuid);
    _messages.insert(0, message);

    // 사용자 메시지와 초기 인사말은 즉시 DB에 저장
    if (isUser || !isProcessing) { // AI 응답 로딩중이 아닐때 (즉, 초기 인사말)
        _databaseService.saveMessage(message.toMap());
    }

    if (speak) {
      _openAiTtsService.speak(text);
    }
    notifyListeners();
  }

  Future<void> stopTts() async {
    await _openAiTtsService.stop();
  }

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isProcessing) return;

    _openAiTtsService.stop(); 
    _addMessage(userInput, true);

    _isProcessing = true;
    _messages.insert(0, ChatMessage(text: '', isUser: false, uuid: uuid, isLoading: true));
    notifyListeners();
    
    await _realtimeChatService.sendMessage(userInput);
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    _realtimeChatService.dispose(); 
    _openAiTtsService.dispose();
    super.dispose();
  }
}