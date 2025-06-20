import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/openai_chat_service.dart';
import 'package:nompangs/services/openai_tts_service.dart';
import 'package:nompangs/models/personality_profile.dart';

class ChatMessage {
  String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final PersonalityProfile profile;

  const ChatScreen({super.key, required this.profile});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late OpenAiTtsService _openAiTtsService;
  late OpenAiChatService _openAiChatService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print('[ChatScreen] initState 호출');
    _openAiTtsService = OpenAiTtsService();
    _openAiChatService = OpenAiChatService();
    _initSpeech();

    if (widget.profile.greeting != null &&
        widget.profile.greeting!.isNotEmpty) {
      _addMessage(widget.profile.greeting!, false, speak: true);
    }
    if (widget.profile.initialUserMessage != null &&
        widget.profile.initialUserMessage!.isNotEmpty) {
      _addMessage(widget.profile.initialUserMessage!, true, speak: false);
      _requestAiResponse(widget.profile.initialUserMessage!);
    }
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    await _speech.initialize();
  }

  Future<void> _requestAiResponse(String userInput) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final botResponse =
          await _openAiChatService.getResponseFromGpt(null, [], userInput);

      if (mounted) {
        _addMessage(botResponse, false, speak: true);
      }
    } catch (e) {
      if (mounted) {
        _addMessage("AI 응답 중 오류 발생: $e", false);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _addMessage(String text, bool isUser, {bool speak = false}) {
    setState(
      () => _messages.insert(0, ChatMessage(text: text, isUser: isUser)),
    );
    if (speak) {
      _openAiTtsService.speak(text);
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    final userMessage = text.trim();
    _textController.clear();
    _addMessage(userMessage, true);
    _requestAiResponse(userMessage);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          _textController.text = result.recognizedWords;
          if (result.finalResult) {
            _handleSubmitted(result.recognizedWords);
            _stopListening();
          }
        },
        localeId: "ko_KR",
      );
    }
  }

  void _stopListening() {
    if (_isListening) {
      print('[ChatScreen] _stopListening 호출, 음성 인식 중지');
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    print('[ChatScreen] dispose 호출, 리소스 해제 시작');
    _textController.dispose();
    _speech.stop();
    _openAiTtsService.dispose();
    print('[ChatScreen] dispose 완료');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: Text(
                widget.profile.aiPersonalityProfile?.name?.isNotEmpty == true
                    ? widget.profile.aiPersonalityProfile!.name[0]
                    : 'C',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.aiPersonalityProfile?.name ?? '페르소나',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "다정함",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(
                  message,
                  message.isUser
                      ? "나"
                      : (widget.profile.aiPersonalityProfile?.name ?? "캐릭터"),
                );
              },
            ),
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[800],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "메시지 보내기",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _isProcessing ? null : _handleSubmitted,
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isProcessing
                      ? null
                      : () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, String sender) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!message.isUser)
            CircleAvatar(
              child: Text(sender[0]),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Text(sender, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color:
                        message.isUser ? Colors.blue : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Text(message.text,
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 10),
          if (message.isUser)
            const CircleAvatar(
              child: Text("나"),
            ),
        ],
      ),
    );
  }
} 