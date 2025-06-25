import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:nompangs/models/message.dart';
import 'package:nompangs/services/conversation_service.dart';
import 'package:nompangs/usecases/chat_usecase.dart';
import 'package:nompangs/services/stt_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/services/audio_stream_service.dart';

class ChatProvider with ChangeNotifier {
  // --- Services & UseCases ---
  final ChatUseCase _chatUseCase = ChatUseCase();
  final ConversationService _conversationService = ConversationService();
  late final SttService _sttService;
  late final OpenAiTtsService _ttsService;
  late final AudioStreamService _audioStreamService;
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  // --- State Variables ---
  String? _conversationId;
  String? _characterId;
  Map<String, dynamic>? _characterProfile;
  bool _isLoading = false;
  String? _error;

  // --- Voice Chat State ---
  bool _isListening = false;
  bool _isProcessing = false; // STT 결과를 처리 중인지 여부
  bool _isSpeaking = false; // TTS가 재생 중인지 여부
  String? _sttError;
  StreamSubscription? _sttSubscription;

  // --- UI-related Data ---
  // 이 데이터들은 채팅 화면에 진입할 때 외부에서 설정되어야 합니다.
  String characterName = '캐릭터';
  String userDisplayName = '사용자';
  List<String> personalityTags = ['태그1', '태그2'];
  String? photoBase64;
  String? userPhotoPath;
  String? imageUrl;
  String? greetings;

  // --- Getters for UI ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get conversationId => _conversationId;
  Map<String, dynamic>? get characterProfile => _characterProfile;
  
  // --- Voice Chat Getters ---
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String? get sttError => _sttError;

  // 메시지 목록을 위한 스트림
  Stream<List<Message>>? get messagesStream {
    if (_conversationId == null) return null;
    return _conversationService.getMessagesStream(_conversationId!);
  }

  // 생성자에서 서비스를 초기화합니다.
  ChatProvider() {
    _sttService = SttService(
      onResult: _handleSttResult,
      onError: _handleSttError,
    );
    _ttsService = new OpenAiTtsService();
    _audioStreamService = AudioStreamService();

    _sttService.initialize();
    _player.openPlayer();
  }

  // 채팅방에 처음 진입할 때 호출됩니다.
  Future<void> initializeChat(String convId, Map<String, dynamic> characterProfile) async {
    _conversationId = convId;
    _characterId = characterProfile['uuid'] as String?;
    _characterProfile = characterProfile;
    
    final userInput = characterProfile['userInput'] as Map<String, dynamic>? ?? {};

    characterName = characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음';
    userDisplayName = userInput['userDisplayName'] ?? characterProfile['userDisplayName'] ?? '친구';

    // 인사말 찾기 (모든 가능성 확인)
    // 1. 최상위 'greetings' (Firebase에서 올 때)
    // 2. 최상위 'greeting'
    // 3. userInput 맵 안의 'greeting'
    greetings = characterProfile['greetings'] as String? ??
                characterProfile['greeting'] as String? ??
                userInput['greeting'] as String? ??
                '안녕!';

    // 사진 정보 찾기 (모든 가능성 확인)
    photoBase64 = characterProfile['photoBase64'] as String?;
    
    // 1. 최상위 'userPhotoPath' (기존 로직)
    // 2. 최상위 'photoPath' (로그에서 확인된 키)
    // 3. userInput 맵 안의 'photoPath'
    userPhotoPath = characterProfile['userPhotoPath'] as String? ??
                  characterProfile['photoPath'] as String? ??
                  userInput['photoPath'] as String?;
                  
    imageUrl = characterProfile['imageUrl'] as String?;

    // TTS 서비스에 캐릭터의 음성 설정을 전달합니다.
    _ttsService.setCharacterVoiceSettings(characterProfile);

    // 대화 기록이 없는 경우에만 초기 인사말을 추가합니다.
    if (_conversationId != null && _characterId != null) {
      final messageCount = await _conversationService.getMessageCount(_conversationId!);
      if (messageCount == 0) {
        await _conversationService.addMessage(
          conversationId: _conversationId!,
          characterId: _characterId!,
          sender: 'ai',
          text: greetings!,
        );
      }
    }

    notifyListeners();
  }

  // 메시지 전송 로직을 UseCase에 위임
  Future<void> sendMessage(String text) async {
    if (_conversationId == null || _characterId == null) {
      _error = "오류: 대화 또는 캐릭터 ID가 설정되지 않았습니다.";
      notifyListeners();
      return;
    }
    if (text.trim().isEmpty) return;

    _error = null;
    
    try {
      // UseCase는 UI를 기다리지 않고 백그라운드에서 실행됩니다.
      final aiResponseText = await _chatUseCase.sendMessage(
        conversationId: _conversationId!,
        characterId: _characterId!,
        text: text,
      );

      if (aiResponseText != null && aiResponseText.isNotEmpty) {
        await _playTts(aiResponseText);
      }
    } catch (e) {
      _error = "메시지 전송에 실패했습니다: $e";
      notifyListeners();
    }
  }

  // --- Voice Chat Control Methods ---
  Future<void> startAudioStreaming() async {
    if (_isListening) return;
    await stopTts(); // 혹시 TTS가 재생중이면 중지
    _isListening = true;
    _sttError = null;
    notifyListeners();
    await _sttService.startListening();
  }

  Future<void> stopAudioStreaming() async {
    if (!_isListening) return;
    await _sttService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  Future<void> stopTts() async {
    if (_isSpeaking) {
      await _player.stopPlayer();
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> _playTts(String text) async {
    try {
      await stopTts(); // 현재 재생 중인 TTS 중지

      _isSpeaking = true;
      notifyListeners();

      // OpenAiTtsService가 내부적으로 오디오 재생을 처리합니다.
      await _ttsService.speak(text);

      // speak 메서드가 완료되면 재생이 끝난 것으로 간주합니다.
      // (더 정교한 상태 관리를 위해서는 tts service에 콜백 추가 필요)
      _isSpeaking = false;
      notifyListeners();
      
    } catch (e) {
      _error = "TTS 재생에 실패했습니다: $e";
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // --- STT Helper Methods ---
  void _handleSttResult(String text, bool isFinal) {
    if (isFinal && text.isNotEmpty) {
      _isListening = false;
      _isProcessing = true;
      notifyListeners();
      
      // STT 최종 결과를 메시지로 전송
      sendMessage(text);
      
      // 처리가 완료되면 isProcessing을 false로 설정
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _handleSttError(String error) {
    _sttError = error;
    _isListening = false;
    _isProcessing = false;
    notifyListeners();
  }

  // Provider가 소멸될 때 호출됩니다.
  @override
  void dispose() {
    _sttService.dispose();
    _audioStreamService.dispose();
    _player.closePlayer();
    _sttSubscription?.cancel();
    super.dispose();
  }
}
