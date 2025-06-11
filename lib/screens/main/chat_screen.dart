import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nompangs/services/gemini_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/openai_tts_service.dart';

class ChatMessage {
  String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String characterName;
  final List<String> personalityTags;
  final String? greeting;
  final String? initialUserMessage;

  const ChatScreen({
    Key? key,
    required this.characterName,
    required this.personalityTags,
    this.greeting,
    this.initialUserMessage,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  StreamSubscription<String>? _geminiStreamSubscription;
  late OpenAiTtsService _openAiTtsService;
  late GeminiService _geminiService;
  bool _isProcessing = false;
  String _sentenceBuffer = '';
  Future<void>? _firstSentencePlaybackFuture;

  @override
  void initState() {
    super.initState();
    _openAiTtsService = OpenAiTtsService();
    _geminiService = GeminiService();
    _initSpeech();

    if (widget.greeting != null && widget.greeting!.isNotEmpty) {
      _addMessage(widget.greeting!, false, speak: true);
    }
    if (widget.initialUserMessage != null && widget.initialUserMessage!.isNotEmpty) {
      _addMessage(widget.initialUserMessage!, true, speak: false);
      _requestAiResponseStream(widget.initialUserMessage!);
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

    final characterProfile = {
      'name': widget.characterName,
      'tags': widget.personalityTags,
      'greeting': widget.greeting,
    };

    _geminiStreamSubscription = _geminiService
        .analyzeUserInputStream(userInput, characterProfile: characterProfile)
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
    _geminiStreamSubscription?.cancel();
    _openAiTtsService.dispose();
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
                widget.characterName.isNotEmpty ? widget.characterName[0] : 'C',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.characterName,
                    style: TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.personalityTags.isNotEmpty)
                    Text(
                      widget.personalityTags.join(', '),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
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
                return _buildMessageBubble(message);
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

  Widget _buildMessageBubble(ChatMessage message) {
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
              message.isUser ? "나" : widget.characterName,
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