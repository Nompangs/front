// lib/chat_text_screen.dart

import 'package:flutter/material.dart';
import 'chat_speaker_screen.dart'; // ChatSpeakerScreen으로 라우팅하기 위해 추가

class ChatTextScreen extends StatefulWidget {
  final String characterName;
  final String characterHandle;
  final List<String> personalityTags;
  final String greeting;

  const ChatTextScreen({
    Key? key,
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
    required this.greeting,
  }) : super(key: key);

  @override
  State<ChatTextScreen> createState() => _ChatTextScreenState();
}

class _ChatTextScreenState extends State<ChatTextScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    // 초기 왼쪽 버블 한 개만 추가
    _messages = [
      _Message(
        text: '헤이~ 오늘 강남 어땠어? 사람 많았지? 나였으면 정신 살짝 나갔을지도 ㅋㅋ 🤯',
        isUser: false,
      ),
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _inputController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUserMessage = _messages.any((msg) => msg.isUser);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopNavigationBar(
              characterName: widget.characterName,
              characterHandle: widget.characterHandle,
            ),

            Expanded(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Column(
                  children: [
                    if (!hasUserMessage)
                      _ProfileCard(
                        characterName: widget.characterName,
                        characterHandle: widget.characterHandle,
                        personalityTags: widget.personalityTags,
                      ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final bool isFirst = index == 0;
                            final double topPadding = isFirst
                                ? (hasUserMessage ? 24 : 16)
                                : 8;
                            return Padding(
                              padding: EdgeInsets.only(top: topPadding),
                              child: _ChatBubble(
                                text: msg.text,
                                isUser: msg.isUser,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 하단 입력창: 이 위치에서 ChatInputBar 호출
                    _ChatInputBar(
                      controller: _inputController,
                      onSend: _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

class _TopNavigationBar extends StatelessWidget {
  final String characterName;
  final String characterHandle;

  const _TopNavigationBar({
    Key? key,
    required this.characterName,
    required this.characterHandle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 24,
              color: Color(0xFF333333),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),

          ClipOval(
            child: Image.asset(
              'assets/profile.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                characterName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                characterHandle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),

          const Spacer(),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.volume_up,
              size: 24,
              color: Color(0xFF333333),
            ),
            onPressed: () {},
          ),

          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.more_horiz,
              size: 24,
              color: Color(0xFF333333),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String characterName;
  final String characterHandle;
  final List<String> personalityTags;

  const _ProfileCard({
    Key? key,
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 32, right: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/profile.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      characterName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'By $characterHandle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 0; i < personalityTags.length; i++) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${personalityTags[i]}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ),
                          if (i != personalityTags.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '56K',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                TextSpan(
                  text: ' monthly users · ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                ),
                TextSpan(
                  text: '8.4K',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                TextSpan(
                  text: ' followers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const userBgColor = Color(0xFF7C3AED);
    const userTextColor = Colors.white;
    const otherBgColor = Colors.white;
    const otherTextColor = Color(0xFF222222);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isUser ? userBgColor : otherBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isUser ? userTextColor : otherTextColor,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInputBar({
    Key? key,
    required this.controller,
    required this.onSend,
  }) : super(key: key);

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_textListener);
  }

  void _textListener() {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() => _hasText = hasContent);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_textListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 하단 안전 영역 높이
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.image,
                size: 28,
                color: Color(0xFF777777),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(top: 10),
                    hintText: 'Send message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAAAAAA),
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF222222),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ⑦ 전화기 버튼: 텍스트 입력 없으면 ChatSpeakerScreen으로 이동
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _hasText ? Colors.white : const Color(0xFF6A5ACD),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _hasText ? Icons.send : Icons.call,
                  size: 20,
                  color: _hasText ? Colors.black : Colors.white,
                ),
                onPressed: () {
                  if (_hasText) {
                    widget.onSend();
                  } else {
                    // ⑦-1) 사용자가 텍스트를 입력하지 않은 상태에서 전화 버튼 누르면
                    //       ChatSpeakerScreen으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatSpeakerScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
