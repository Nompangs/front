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
  late final String characterName;
  late final String characterHandle;
  late final List<String> personalityTags;
  final String? greeting;

  ChatProvider({
    required this.uuid, 
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
    this.greeting,
  }) {
    _initializeChat();
  }
  
  Future<void> _initializeChat() async {
    await _loadHistory(); 

    final characterProfile = {
      'name': characterName,
      'tags': personalityTags,
      'greeting': greeting,
    };
    await _realtimeChatService.connect(characterProfile);

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
          await _openAiTtsService.speak(fullText.trim());
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

  Future<void> _loadHistory() async {
    final history = await _databaseService.getHistory(uuid);
    _messages.clear();
    _messages.addAll(history.map((msg) => ChatMessage.fromMap(msg)));
    notifyListeners();
  }

  void _addMessage(String text, bool isUser, {bool speak = false, bool saveToDb = false}) {
    final message = ChatMessage(text: text, isUser: isUser, uuid: uuid);
    _messages.insert(0, message);

    if (saveToDb) {
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

    await _openAiTtsService.stop(); 
    _addMessage(userInput, true, saveToDb: true);

    _isProcessing = true;
    _messages.insert(0, ChatMessage(text: '', isUser: false, uuid: uuid, isLoading: true));
    notifyListeners();
    
    await _realtimeChatService.sendMessage(userInput);
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