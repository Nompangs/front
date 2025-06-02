// lib/chat_text_screen.dart

import 'package:flutter/material.dart';

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

  /// 메시지 데이터 모델: 텍스트와 isUser 여부를 저장
  List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    // 앱 시작 시, 왼쪽 흰색 버블 하나만 초기 메시지로 삽입
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

  /// 사용자가 보낸 메시지를 _messages에 추가하고 스크롤을 맨 아래로 이동
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _inputController.clear();
    });

    // 프레임이 그려진 뒤에 스크롤 이동
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
    // 사용자가 보낸 메시지가 한 개라도 있는지 체크
    final bool hasUserMessage = _messages.any((msg) => msg.isUser);

    return Scaffold(
      // 전체 화면 배경을 흰색으로 지정 (상단 상태 표시줄 + 내비게이션 바도 흰색)
      backgroundColor: Colors.white,
      body: SafeArea(
        // bottom: true (기본값)로 두어, 하단 입력창이 내비게이션 바 위에 올라가지 않도록 함
        child: Column(
          children: [
            // 1) 상단 내비게이션 바 (흰색 배경)
            _TopNavigationBar(
              characterName: widget.characterName,
              characterHandle: widget.characterHandle,
            ),

            // 2) 나머지 영역: F2F2F2 배경
            Expanded(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Column(
                  children: [
                    // 2-1) 프로필 카드: 첫 사용자 메시지 전까지만 노출
                    if (!hasUserMessage)
                      _ProfileCard(
                        characterName: widget.characterName,
                        characterHandle: widget.characterHandle,
                        personalityTags: widget.personalityTags,
                      ),

                    // 2-2) 채팅 메시지 영역 (ListView)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final bool isFirst = index == 0;

                            // 첫 번째 메시지일 때 여백 조절:
                            // • 프로필 카드가 보이는 동안(hasUserMessage == false): topPadding = 16
                            // • 프로필 카드가 사라진 후(hasUserMessage == true): topPadding = 24
                            final double topPadding;
                            if (isFirst) {
                              topPadding = hasUserMessage ? 24 : 16;
                            } else {
                              topPadding = 8;
                            }

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

                    // 2-3) 하단 입력창
                    //     SafeArea를 다시 한번 사용하여, 기기 하단 내비게이션바 위로 올라오게 함
                    SafeArea(
                      top: false,
                      child: _ChatInputBar(
                        controller: _inputController,
                        onSend: _sendMessage,
                      ),
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

/// 메시지 데이터 모델
class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}

/// ============================================================
/// 1) 상단 내비게이션 바 (_TopNavigationBar)
///    - 배경 흰색(0xFFFFFFFF)
/// ============================================================
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
      height: 56, // 내비게이션 바 높이
      color: Colors.white, // 흰색 배경
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뒤로가기 아이콘
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

          // 프로필 원형 썸네일 (32×32)
          ClipOval(
            child: Image.asset(
              'assets/profile.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),

          // 캐릭터 이름 / 핸들
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

          // 음성(스피커) 아이콘
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.volume_up,
              size: 24,
              color: Color(0xFF333333),
            ),
            onPressed: () {
              // 음성 출력 기능 (필요 시 구현)
            },
          ),

          // 더보기(세 점) 아이콘
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.more_vert,
              size: 24,
              color: Color(0xFF333333),
            ),
            onPressed: () {
              // 메뉴 기능 (필요 시 구현)
            },
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// 2) 프로필 카드 위젯 (_ProfileCard)
/// ============================================================
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
          // 타원형 프로필 이미지(100×100) + 텍스트 블록
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
                    // 캐릭터 이름 (24, Bold)
                    Text(
                      characterName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // "By $characterHandle" (16, Regular, 보라색)
                    Text(
                      'By $characterHandle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 해시태그 Row
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
          // 하단 Stat 텍스트
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

/// ============================================================
/// 3) 채팅 버블 컴포넌트 (_ChatBubble)
///    - isUser true면 오른쪽 보라색, false면 왼쪽 흰색
/// ============================================================
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
    // 사용자가 보낸 메시지는 보라색 배경(#7C3AED), 흰색 텍스트
    const userBgColor = Color(0xFF7C3AED);
    const userTextColor = Colors.white;

    // 기존 메시지는 흰색 배경, 다크 그레이 텍스트
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

/// ============================================================
/// 4) 하단 입력창 컴포넌트 (_ChatInputBar)
///    - 텍스트 입력 유무에 따라 send / call 아이콘 변경
///    - send 누르면 onSend 콜백 호출
/// ============================================================
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
    // 하단 기기의 네비게이션 바 영역을 고려해 viewPadding.bottom 만큼 추가 여백
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        child: Row(
          children: [
            // 이미지/파일 선택 아이콘
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.image,
                size: 28,
                color: Color(0xFF777777),
              ),
              onPressed: () => null,
            ),
            const SizedBox(width: 12),

            // 메시지 입력창
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
                    isCollapsed: true, // 내부 여백 최소화
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

            // send 또는 call 아이콘
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
                    // 전화 기능(필요 시 구현)
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
