import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/services/api_service.dart';
import 'package:nompangs/widgets/masked_image.dart';
import 'package:nompangs/widgets/personality_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ObjectDetailScreen extends StatefulWidget {
  final String objectId;

  const ObjectDetailScreen({Key? key, required this.objectId})
    : super(key: key);

  @override
  State<ObjectDetailScreen> createState() => _ObjectDetailScreenState();
}

class _ObjectDetailScreenState extends State<ObjectDetailScreen> {
  final GlobalKey _qrKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();

  PersonalityProfile? _profile;
  bool _isLoading = true;
  bool _isScrolledToBottom = false;
  String _message = "페르소나 정보를 불러오는 중입니다...";
  String _userHandle = '게스트';
  String? _qrCodeData; // QR 코드 데이터 (UUID)

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProfileAndUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    _isScrolledToBottom = currentScroll >= maxScroll * 0.9;
    setState(() {});
  }

  Future<void> _loadProfileAndUser() async {
    try {
      // 1. 유저 핸들(닉네임) 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          _userHandle = doc.data()?['displayName'] ?? '게스트';
        }
      }

      // 2. 사물 프로필 정보 불러오기
      final profileData = await _apiService.loadProfile(widget.objectId);
      if (profileData == null) {
        throw Exception('프로필을 찾을 수 없습니다.');
      }

      setState(() {
        _profile = profileData;
        _qrCodeData = profileData.uuid; // QR 데이터로 UUID 사용
        _isLoading = false;
        _message = "정보 불러오기 완료!";
      });
    } catch (e) {
      debugPrint('🚨 프로필 로드 실패: $e');
      setState(() {
        _isLoading = false;
        _message = "정보를 불러오는 데 실패했습니다: ${e.toString()}";
      });
    }
  }

  Uint8List? _decodeQrImage(String? base64String) {
    if (base64String == null || !base64String.startsWith('data:image')) {
      return null;
    }
    final pureBase64 = base64String.substring(base64String.indexOf(',') + 1);
    try {
      return base64Decode(pureBase64);
    } catch (e) {
      print("Base64 디코딩 실패: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(_message),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('오류')),
        body: Center(child: Text(_message)),
      );
    }

    final character = _profile!;
    final characterName = character.aiPersonalityProfile?.name ?? '페르소나';

    // 🚨 [Fix] RangeError 방지를 위해 personalityTags 생성 로직 수정
    final personalityTags =
        (character.aiPersonalityProfile?.coreValues != null &&
                character.aiPersonalityProfile!.coreValues.isNotEmpty)
            ? character.aiPersonalityProfile!.coreValues.take(2).toList()
            : ['친구', '따뜻함']; // 기본값 제공

    final qrBytes = _decodeQrImage(_qrCodeData);
    final photoPath = character.userInput?['photoPath'] as String?;

    // 🚨 [Fix] PathNotFoundException을 방지하기 위해 안전한 이미지 프로바이더 생성
    ImageProvider getSafeFileImageProvider(String? path, String fallbackAsset) {
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        return FileImage(File(path));
      }
      return AssetImage(fallbackAsset);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 150,
            ),
            controller: _scrollController,
            child: Column(
              children: [
                _ObjectDetailProfileCard(
                  characterName: characterName,
                  characterHandle: _userHandle,
                  personalityTags: personalityTags,
                  photoPath: photoPath,
                ),
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 70,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD8F1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(39),
                                bottomLeft: Radius.circular(39),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08,
                                vertical: 15,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'QR을 붙이면\n언제 어디서든 대화할 수 있어요!',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                () =>
                                                    _saveQRCode(characterName),
                                            icon: const Icon(
                                              Icons.download,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              '저장하기',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF6750A4,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                () => _shareQRCode(character),
                                            icon: const Icon(
                                              Icons.share,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              '공유하기',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF6750A4,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              minimumSize: const Size(0, 36),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 35,
                          child: GestureDetector(
                            onTap: () => _showQRPopup(character),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFC8A6FF),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(39),
                                  bottomRight: Radius.circular(39),
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  padding: const EdgeInsets.all(0),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child:
                                      _qrCodeData != null
                                          ? RepaintBoundary(
                                            key: _qrKey,
                                            child: QrImageView(
                                              data:
                                                  'https://invitepage.netlify.app/?roomId=${_qrCodeData!}',
                                              version: QrVersions.auto,
                                              size: 100,
                                              backgroundColor: Colors.white,
                                            ),
                                          )
                                          : const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7E9),
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: const BorderRadius.all(Radius.circular(40)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    characterName,
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${DateTime.now().year}년 ${DateTime.now().month}월생', // TODO: 실제 생성일로 변경
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 15,
                                      color: const Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        character
                                                .aiPersonalityProfile
                                                ?.objectType ??
                                            '멘탈지기',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        character.userInput?['location'] ??
                                            '알 수 없음',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 480,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: screenWidth * 0.8,
                                    height: screenWidth * 0.8,
                                    child: Builder(
                                      builder: (context) {
                                        final userPhotoPath =
                                            _profile?.userInput?['photoPath']
                                                as String?;
                                        final serverImageUrl =
                                            _profile?.imageUrl;

                                        ImageProvider imageProvider;
                                        Color? backgroundColor;

                                        if (userPhotoPath != null &&
                                            userPhotoPath.isNotEmpty &&
                                            File(userPhotoPath).existsSync()) {
                                          imageProvider = FileImage(
                                            File(userPhotoPath),
                                          );
                                          backgroundColor = null;
                                        } else if (serverImageUrl != null &&
                                            serverImageUrl.isNotEmpty &&
                                            serverImageUrl.startsWith('http')) {
                                          imageProvider = NetworkImage(
                                            serverImageUrl,
                                          );
                                          backgroundColor = null;
                                        } else {
                                          final placeholderIndex =
                                              Random().nextInt(19) + 1;
                                          imageProvider = AssetImage(
                                            'assets/ui_assets/object_png/obj ($placeholderIndex).png',
                                          );
                                          final random = Random();
                                          final hue = random.nextDouble() * 360;
                                          backgroundColor =
                                              HSLColor.fromAHSL(
                                                1.0,
                                                hue,
                                                0.8,
                                                0.9,
                                              ).toColor();
                                        }

                                        return MaskedImage(
                                          image: imageProvider,
                                          mask: const AssetImage(
                                            'assets/ui_assets/cardShape_1.png',
                                          ),
                                          stroke: const AssetImage(
                                            'assets/ui_assets/cardShape_stroke_1.png',
                                          ),
                                          width: screenWidth * 0.8,
                                          height: screenWidth * 0.8,
                                          backgroundColor: backgroundColor,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 170,
                                  left: 0,
                                  child: Container(
                                    width: screenWidth * 0.8,
                                    height: 320,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/ui_assets/speechBubble.png',
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 51,
                                        vertical: 40,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final tags = List<String>.from(
                                                personalityTags,
                                              );
                                              if (tags.isEmpty) {
                                                tags.addAll([
                                                  '',
                                                  '',
                                                ]); // 빈 태그라도 공간 차지
                                              } else if (tags.length == 1) {
                                                tags.add(''); // 두 번째 태그 공간 확보
                                              }

                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (tags[0].isNotEmpty)
                                                    _buildPersonalityTag(
                                                      tags[0],
                                                    ),
                                                  if (tags[0].isNotEmpty &&
                                                      tags[1].isNotEmpty)
                                                    const SizedBox(width: 8),
                                                  if (tags[1].isNotEmpty)
                                                    _buildPersonalityTag(
                                                      tags[1],
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            character.greeting ?? '만나서 반가워!',
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 17,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -3),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7E9),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PersonalityChart(
                          warmth:
                              (character
                                          .aiPersonalityProfile
                                          ?.npsScores?['W01_친절함'] ??
                                      50)
                                  .toDouble(),
                          competence:
                              (character
                                          .aiPersonalityProfile
                                          ?.npsScores?['C01_효율성'] ??
                                      50)
                                  .toDouble(),
                          extroversion:
                              (character
                                          .aiPersonalityProfile
                                          ?.npsScores?['E01_사교성'] ??
                                      50)
                                  .toDouble(),
                          creativity: _calculateCreativity(character),
                          humour: _calculateHumour(character),
                          reliability: _calculateReliability(character),
                          realtimeSettings: character.realtimeSettings,
                          attractiveFlaws: character.attractiveFlaws,
                          contradictions: character.contradictions,
                          communicationPrompt: character.communicationPrompt,
                          coreTraits: character.coreTraits,
                          personalityDescription:
                              character.personalityDescription,
                        ),
                      ],
                    ),
                  ),
                ),
                // Admin Card
                _buildAdminCard(context),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final characterProfile = _profile!.toMap();

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final doc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                  characterProfile['userDisplayName'] =
                      doc.data()?['displayName'] ?? '게스트';
                } else {
                  characterProfile['userDisplayName'] = '게스트';
                }

                characterProfile['personalityTags'] =
                    _profile!.aiPersonalityProfile?.coreValues.isNotEmpty ==
                            true
                        ? _profile!.aiPersonalityProfile!.coreValues
                        : ['친구'];

                debugPrint(
                  '✅ [상세페이지 진입] ChatProvider로 전달되는 프로필: $characterProfile',
                );

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ChangeNotifierProvider(
                          create:
                              (_) => ChatProvider(
                                characterProfile: characterProfile,
                              ),
                          child: const ChatTextScreen(
                            showHomeInsteadOfBack: true,
                          ),
                        ),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                '대화 시작하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: MediaQuery.of(context).padding.bottom + 24 + 56 + 15,
            child: GestureDetector(
              onTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _isScrolledToBottom
                        ? 0
                        : _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Icon(
                  _isScrolledToBottom
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '관리 메뉴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.edit, size: 16),
              label: Text('수정하기'),
              onPressed: _editObject,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.bar_chart, size: 16),
              label: Text('나와의 교감 기록'),
              onPressed: _showStats,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_outline, size: 16),
              label: Text('삭제하기'),
              onPressed: () => _deleteObject(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editObject() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('수정 기능은 현재 준비 중입니다.')));
  }

  void _showStats() async {
    final characterId = _profile?.uuid;
    if (characterId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사물 ID를 찾을 수 없습니다.')));
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(characterId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      final int messageCount = await FirebaseFirestore.instance
          .collection('chats')
          .doc(characterId)
          .collection('messages')
          .get()
          .then((snap) => snap.size);

      String lastInteraction = '대화 기록 없음';
      if (querySnapshot.docs.isNotEmpty) {
        final lastTimestamp =
            (querySnapshot.docs.first['timestamp'] as Timestamp).toDate();
        lastInteraction = _formatTimeAgo(lastTimestamp);
      }

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('나와의 교감 기록'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이 사물과의 모든 상호작용 기록입니다.'),
                  SizedBox(height: 16),
                  _buildStatRow(
                    Icons.chat_bubble_outline,
                    '총 대화 메시지 수',
                    '$messageCount개',
                  ),
                  SizedBox(height: 8),
                  _buildStatRow(Icons.access_time, '마지막 대화', lastInteraction),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('닫기'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('통계 정보를 불러오는 데 실패했습니다: $e')));
    }
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(fontSize: 15)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}달 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Future<void> _deleteObject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('정말 삭제하시겠어요?'),
            content: Text('삭제한 사물은 복구할 수 없어요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('qr_profiles')
          .doc(_profile!.uuid)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제되었습니다.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // true를 반환하여 이전 화면에서 새로고침하도록
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $e')));
    }
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9AC28),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _saveQRCode(String characterName) async {
    if (_qrKey.currentContext == null) return;
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          '${characterName}_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      var status = await Permission.photos.request();
      if (status.isGranted) {
        await Gal.putImage(file.path, album: 'Nompangs');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('갤러리 접근 권한이 필요합니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      await file.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode(PersonalityProfile character) async {
    if (_qrKey.currentContext == null) return;
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'nompangs_qr.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${character.aiPersonalityProfile?.name ?? '내 친구'}와 함께하세요! 놈팽쓰 QR 코드입니다 🎉\n\nQR을 스캔하면 ${character.aiPersonalityProfile?.name ?? '내 친구'}과 대화할 수 있어요!',
        subject: '놈팽쓰 친구 공유 - ${character.aiPersonalityProfile?.name ?? '친구'}',
      );

      await file.delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('공유 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQRPopup(PersonalityProfile character) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                onLongPress: () {
                  Navigator.of(context).pop();
                  _saveQRCode(
                    character.aiPersonalityProfile?.name ?? 'persona',
                  );
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(color: const Color(0xFFC8A6FF)),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data:
                              _qrCodeData != null
                                  ? 'https://invitepage.netlify.app/?roomId=${_qrCodeData!}'
                                  : '',
                          version: QrVersions.auto,
                          size: 100.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateCreativity(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;
    final nps = character!.aiPersonalityProfile!.npsScores;
    final imagination = nps['O01_상상력'] ?? 50;
    final creativity = nps['C03_창의성'] ?? 50;
    final curiosity = nps['O02_호기심'] ?? 50;
    return (imagination * 0.4 + creativity * 0.4 + curiosity * 0.2).clamp(
      0.0,
      100.0,
    );
  }

  double _calculateHumour(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 75.0;
    final nps = character!.aiPersonalityProfile!.npsScores;
    final playfulness = nps['E06_유쾌함'] ?? 75;
    final creativity = nps['C03_창의성'] ?? 50;
    final sociability = nps['E01_사교성'] ?? 50;
    return (playfulness * 0.5 + creativity * 0.3 + sociability * 0.2).clamp(
      0.0,
      100.0,
    );
  }

  double _calculateReliability(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;
    final nps = character!.aiPersonalityProfile!.npsScores;
    final trustworthiness = nps['A01_신뢰성'] ?? 50;
    final responsibility = nps['CS01_책임감'] ?? 50;
    final consistency = nps['CS02_질서성'] ?? 50;
    return (trustworthiness * 0.4 + responsibility * 0.4 + consistency * 0.2)
        .clamp(0.0, 100.0);
  }
}

class _ObjectDetailProfileCard extends StatelessWidget {
  final String characterName;
  final String characterHandle;
  final String? photoPath;
  final List<String> personalityTags;

  const _ObjectDetailProfileCard({
    required this.characterName,
    required this.characterHandle,
    required this.photoPath,
    required this.personalityTags,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    Color? placeholderColor;

    // Check if the file exists and is not empty.
    if (photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync()) {
      imageProvider = FileImage(File(photoPath!));
    } else {
      final random = Random();
      final List<Color> placeholderColors = [
        Colors.blue[50]!,
        Colors.green[50]!,
        Colors.pink[50]!,
        Colors.orange[50]!,
        Colors.purple[50]!,
        Colors.teal[50]!,
        Colors.amber[50]!,
        Colors.red[50]!,
        Colors.indigo[50]!,
      ];
      // Use a random placeholder from obj (1) to obj (9)
      final placeholderIndex = random.nextInt(9) + 1; // Generates 1-9
      final placeholderPath =
          'assets/ui_assets/object_png/obj ($placeholderIndex).png';
      imageProvider = AssetImage(placeholderPath);
      placeholderColor =
          placeholderColors[random.nextInt(placeholderColors.length)];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MaskedImage(
                image: imageProvider,
                mask: const AssetImage('assets/ui_assets/cardShape_ph_2.png'),
                width: 80,
                height: 80,
                backgroundColor: placeholderColor,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
