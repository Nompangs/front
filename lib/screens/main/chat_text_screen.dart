import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:nompangs/models/message.dart';
import 'chat_speaker_screen.dart';
import 'chat_setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:io';
import 'package:nompangs/widgets/masked_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class ChatTextScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> characterProfile;
  final bool showHomeInsteadOfBack;

  const ChatTextScreen({
    super.key,
    required this.conversationId,
    required this.characterProfile,
    this.showHomeInsteadOfBack = false,
  });

  @override
  State<ChatTextScreen> createState() => _ChatTextScreenState();
}

class _ChatTextScreenState extends State<ChatTextScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false)
          .initializeChat(widget.conversationId, widget.characterProfile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return _ChatTextScreenContent(
          provider: provider,
          showHomeInsteadOfBack: widget.showHomeInsteadOfBack,
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
  late ImageProvider _displayImageProvider;
  Color? _placeholderColor;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }
  
  @override
  void didUpdateWidget(covariant _ChatTextScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.photoBase64 != oldWidget.provider.photoBase64 ||
        widget.provider.userPhotoPath != oldWidget.provider.userPhotoPath ||
        widget.provider.imageUrl != oldWidget.provider.imageUrl) {
      _initializeImages();
    }
  }

  void _initializeImages() {
    final photoBase64 = widget.provider.photoBase64;
    final userPhotoPath = widget.provider.userPhotoPath;
    final imageUrl = widget.provider.imageUrl;
    bool imageFound = false;

    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final imageBytes = base64Decode(photoBase64);
        _displayImageProvider = MemoryImage(imageBytes);
        imageFound = true;
      } catch (e) {
        debugPrint("Base64 디코딩 실패: $e");
      }
    }

    if (!imageFound && userPhotoPath != null && userPhotoPath.isNotEmpty) {
      final file = File(userPhotoPath);
      if (file.existsSync()) {
        _displayImageProvider = FileImage(file);
        imageFound = true;
      }
    }
    
    if (!imageFound && imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        _displayImageProvider = NetworkImage(imageUrl);
        imageFound = true;
      }
    }

    if (!imageFound) {
      final placeholderIndex = Random().nextInt(19) + 1;
      _displayImageProvider = AssetImage(
        'assets/ui_assets/object_png/obj ($placeholderIndex).png',
      );
      final random = Random();
      final hue = random.nextDouble() * 360;
      _placeholderColor = HSLColor.fromAHSL(1.0, hue, 0.8, 0.9).toColor();
    } else {
      _placeholderColor = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = widget.provider;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopNavigationBar(
              characterName: chatProvider.characterName,
              characterHandle: chatProvider.userDisplayName,
              imageProvider: _displayImageProvider,
              placeholderColor: _placeholderColor,
              showHomeInsteadOfBack: widget.showHomeInsteadOfBack,
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Column(
                  children: [
                    if (chatProvider.isLoading)
                      const LinearProgressIndicator(),
                    if (chatProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          chatProvider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: StreamBuilder<List<Message>>(
                          stream: chatProvider.messagesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('오류: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text(chatProvider.greeting ?? '대화를 시작해보세요!'));
                            }

                            final messages = snapshot.data!;
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0.0);
                              }
                            });

                            return ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isUser = message.sender == 'user';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: _ChatBubble(
                                    text: message.text,
                                    isUser: isUser,
                                  ),
                                );
                              },
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
              onSend: () {
                if (_inputController.text.isNotEmpty) {
                  chatProvider.sendMessage(_inputController.text);
                  _inputController.clear();
                }
              },
              onSpeakerModePressed: () {
                // 음성 채팅 화면 전환 로직 (현재 비활성화 또는 수정 필요)
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
  final ImageProvider imageProvider;
  final Color? placeholderColor;
  final bool showHomeInsteadOfBack;

  const _TopNavigationBar({
    required this.characterName,
    required this.characterHandle,
    required this.imageProvider,
    this.placeholderColor,
    required this.showHomeInsteadOfBack,
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
                  Icons.arrow_back,
                  size: 24,
                  color: Color(0xFF333333),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),

          SizedBox(
            width: 32,
            height: 32,
            child: MaskedImage(
              image: imageProvider,
              mask: const AssetImage(
                'assets/ui_assets/cardShape_ph_tiny_3.png',
              ),
              width: 32,
              height: 32,
              backgroundColor: placeholderColor,
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
                '@$characterHandle',
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
  final ImageProvider imageProvider;
  final Color? placeholderColor;

  const _ProfileCard({
    required this.characterName,
    required this.characterHandle,
    required this.personalityTags,
    required this.imageProvider,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              SizedBox(
                width: 100,
                height: 100,
                child: MaskedImage(
                  image: imageProvider,
                  mask: const AssetImage('assets/ui_assets/cardShape_ph_2.png'),
                  width: 100,
                  height: 100,
                  backgroundColor: placeholderColor,
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
                      'By @$characterHandle',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text.rich(
                      TextSpan(
                        children: [
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
              ),
            ],
          ),

          const SizedBox(height: 16),

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
                if (i != personalityTags.length - 1) const SizedBox(width: 8),
              ],
            ],
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

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onSpeakerModePressed,
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
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(top: 10),
                    hintText: '메시지를 입력하세요...',
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
                  color: _hasText ? Colors.black : Colors.white,
                ),
                onPressed: _hasText ? widget.onSend : widget.onSpeakerModePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
