import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'chat_speaker_screen.dart';
import 'chat_setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatTextScreen extends StatelessWidget {
  final bool showHomeInsteadOfBack;
  const ChatTextScreen({super.key, this.showHomeInsteadOfBack = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return _ChatTextScreenContent(
          provider: provider,
          showHomeInsteadOfBack: showHomeInsteadOfBack,
        );
      },
    );
  }
}

class _ChatTextScreenContent extends StatefulWidget {
  final ChatProvider provider;
  final bool showHomeInsteadOfBack;
  const _ChatTextScreenContent({
    required this.provider,
    this.showHomeInsteadOfBack = false,
  });

  @override
  State<_ChatTextScreenContent> createState() => __ChatTextScreenContentState();
}

class __ChatTextScreenContentState extends State<_ChatTextScreenContent> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = widget.provider;

    // ListView를 항상 아래로 스크롤하는 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopNavigationBar(
              characterName: chatProvider.characterName,
              characterHandle: chatProvider.characterHandle,
              showHomeInsteadOfBack: widget.showHomeInsteadOfBack,
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Column(
                  children: [
                    // --- 실시간 상태 표시 UI ---
                    if (chatProvider.isConnecting)
                      const LinearProgressIndicator(),
                    if (chatProvider.realtimeError != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          chatProvider.realtimeError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    // --- 메시지 목록 ---
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            final isUser = message.sender == 'user';
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: _ChatBubble(
                                text: message.text,
                                isUser: isUser,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ChatInputBar(
              controller: _inputController,
              isProcessing: chatProvider.isProcessing,
              onSend: () {
                if (_inputController.text.isNotEmpty) {
                  chatProvider.sendMessage(_inputController.text);
                  _inputController.clear();
                }
              },
              onSpeakerModePressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChangeNotifierProvider.value(
                          value: context.read<ChatProvider>(),
                          child: const ChatSpeakerScreen(),
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavigationBar extends StatelessWidget {
  final String characterName;
  final String characterHandle;
  final bool showHomeInsteadOfBack;

  const _TopNavigationBar({
    required this.characterName,
    required this.characterHandle,
    this.showHomeInsteadOfBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          showHomeInsteadOfBack
              ? IconButton(
                icon: const Icon(
                  Icons.home,
                  size: 28,
                  color: Color(0xFF333333),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/flutter-mobile-clone',
                    (route) => false,
                  );
                },
              )
              : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 24,
                  color: Color(0xFF333333),
                ),
                onPressed: () => Navigator.of(context).pop(),
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
            onPressed: () {
              // ① 점 세 개 버튼을 누르면 ChatSettingScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatSettingScreen()),
              );
            },
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
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
  });

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

  const _ChatBubble({required this.text, required this.isUser});

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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
  final VoidCallback onSpeakerModePressed;
  final bool isProcessing;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onSpeakerModePressed,
    this.isProcessing = false,
  });

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
              icon: const Icon(Icons.image, size: 28, color: Color(0xFF777777)),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  // AI가 응답 중일 때 배경색 변경
                  color:
                      widget.isProcessing
                          ? const Color(0xFFE8E8E8)
                          : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: widget.controller,
                  // AI 응답 중일 때 입력 비활성화
                  enabled: !widget.isProcessing,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(top: 10),
                    // 힌트 텍스트 수정 및 상태에 따른 변경
                    hintText:
                        widget.isProcessing
                            ? 'AI가 답변 중입니다...'
                            : '메시지를 입력하세요...',
                    hintStyle: const TextStyle(
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
                  // AI 응답 중일 때 아이콘 색상 변경
                  color:
                      widget.isProcessing
                          ? Colors.grey
                          : (_hasText ? Colors.black : Colors.white),
                ),
                // AI 응답 중일 때 버튼 비활성화
                onPressed:
                    widget.isProcessing
                        ? null
                        : () {
                          if (_hasText) {
                            widget.onSend();
                          } else {
                            widget.onSpeakerModePressed();
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
