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

  const ChatScreen({
    super.key,
    required this.profile,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  StreamSubscription<String>? _apiStreamSubscription;
  late OpenAiTtsService _openAiTtsService;
  late OpenAiChatService _openAiChatService;
  bool _isProcessing = false;
  String _sentenceBuffer = '';
  Future<void>? _firstSentencePlaybackFuture;

  @override
  void initState() {
    super.initState();
    _openAiTtsService = OpenAiTtsService();
    _openAiChatService = OpenAiChatService();
    _initSpeech();

    if (widget.profile.greeting != null && widget.profile.greeting!.isNotEmpty) {
      _addMessage(widget.profile.greeting!, false, speak: true);
    }
    if (widget.profile.initialUserMessage != null && widget.profile.initialUserMessage!.isNotEmpty) {
      _addMessage(widget.profile.initialUserMessage!, true, speak: false);
      _requestAiResponseStream(widget.profile.initialUserMessage!);
    }
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    await _speech.initialize();
  }

  void _requestAiResponseStream(String userInput) {
    if (_isProcessing) return;
    _sentenceBuffer = '';
    _firstSentencePlaybackFuture = null;

    setState(() {
      _isProcessing = true;
      _messages.insert(0, ChatMessage(text: '', isUser: false));
    });

    _apiStreamSubscription = _openAiChatService
        .getChatCompletionStream(userInput, profile: widget.profile)
        .listen(
      (textChunk) {
        if (mounted) {
          setState(() => _messages[0].text += textChunk);
          if (_firstSentencePlaybackFuture == null) {
            _sentenceBuffer += textChunk;
            RegExp sentenceEnd = RegExp(r'[.?!]\s|\n');
            if (sentenceEnd.hasMatch(_sentenceBuffer)) {
              final match = sentenceEnd.firstMatch(_sentenceBuffer)!;
              final firstSentence = _sentenceBuffer.substring(0, match.end).trim();
              if (firstSentence.isNotEmpty) {
                _firstSentencePlaybackFuture = _openAiTtsService.speak(firstSentence);
              }
            }
          }
        }
      },
      onDone: () async {
        if (mounted) {
          await _firstSentencePlaybackFuture;
          String fullText = _messages[0].text;
          String restOfText = '';
          if (_firstSentencePlaybackFuture != null) {
            RegExp sentenceEnd = RegExp(r'[.?!]\s|\n');
            final firstMatch = sentenceEnd.firstMatch(fullText);
            if (firstMatch != null && fullText.length > firstMatch.end) {
              restOfText = fullText.substring(firstMatch.end).trim();
            }
          } else if (fullText.isNotEmpty) {
            restOfText = fullText;
          }
          if (restOfText.isNotEmpty) {
            await _openAiTtsService.speak(restOfText);
          }
          setState(() => _isProcessing = false);
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _messages[0].text = "AI 응답 중 오류 발생";
            _isProcessing = false;
          });
        }
      },
    );
  }

  void _addMessage(String text, bool isUser, {bool speak = false}) {
    setState(() => _messages.insert(0, ChatMessage(text: text, isUser: isUser)));
    if (speak) {
      _openAiTtsService.speak(text);
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    final userMessage = text.trim();
    _textController.clear();
    _addMessage(userMessage, true);
    _requestAiResponseStream(userMessage);
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
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    _apiStreamSubscription?.cancel(); 
    _openAiTtsService.dispose();
    _openAiChatService.dispose();
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
                widget.profile.aiPersonalityProfile?.name?.isNotEmpty == true ? widget.profile.aiPersonalityProfile!.name[0] : 'C',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profile.aiPersonalityProfile?.name ?? '페르소나',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "다정함",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(
                  message,
                  message.isUser ? "나" : (widget.profile.aiPersonalityProfile?.name ?? "캐릭터"),
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
                      AlwaysStoppedAnimation<Color>(Colors.purpleAccent)),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.text_fields, color: Colors.white),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _handleSubmitted,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? Colors.red : Colors.white,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.white),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, String senderName) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.0),
        padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurpleAccent : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
            bottomLeft:
                message.isUser ? Radius.circular(20.0) : Radius.circular(0),
            bottomRight:
                message.isUser ? Radius.circular(0) : Radius.circular(20.0),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}