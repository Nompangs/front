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
  String? greeting;

  // --- Getters for UI ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get conversationId => _conversationId;
  
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
  void initializeChat(String convId, Map<String, dynamic> characterProfile) {
    _conversationId = convId;
    
    // 캐릭터 프로필에서 UI에 필요한 정보를 설정합니다.
    characterName = characterProfile['aiPersonalityProfile']?['name'] ?? '이름 없음';
    userDisplayName = characterProfile['userInput']?['userDisplayName'] ?? '친구';
    greeting = characterProfile['greeting'] ?? '안녕!';
    photoBase64 = characterProfile['photoBase64'];
    userPhotoPath = characterProfile['userPhotoPath'];
    imageUrl = characterProfile['imageUrl'];

    // TTS 서비스에 캐릭터의 음성 설정을 전달합니다.
    _ttsService.setCharacterVoiceSettings(characterProfile);

    // 필요하다면 초기 인사말을 스트림에 추가하는 로직을 여기에 구현할 수 있습니다.
    // (현재는 UseCase가 처리하므로 UI단에서는 생략)
    notifyListeners();
  }

  // 메시지 전송 로직을 UseCase에 위임
  Future<void> sendMessage(String text) async {
    if (_conversationId == null) {
      _error = "오류: 대화 ID가 설정되지 않았습니다.";
      notifyListeners();
      return;
    }
    if (text.trim().isEmpty) return;

    _error = null;
    
    try {
      // UseCase는 UI를 기다리지 않고 백그라운드에서 실행됩니다.
      final aiResponseText = await _chatUseCase.sendMessage(
        conversationId: _conversationId!,
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
