import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/widgets/common/primary_button.dart';
import 'package:nompangs/theme/app_theme.dart';
import 'package:nompangs/widgets/personality_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _bounceController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  final GlobalKey _qrKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);

    // 축하 애니메이션 시작
    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _bounceController.forward();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.9; // 90% 스크롤 시 하단으로 간주

      final isAtBottom = currentScroll >= threshold;
      if (isAtBottom != _isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = isAtBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따른 반응형 높이 계산
    final greenHeight = screenHeight * 0.25;
    final pinkHeight = screenHeight * 0.35;
    final blueHeight = screenHeight * 0.4;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final character = provider.state.generatedCharacter;

        if (character == null) {
          return const Scaffold(
            body: Center(child: Text('캐릭터 정보를 불러올 수 없습니다.')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white, // 전체 배경은 흰색으로 유지
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 전체 스크롤 가능한 컨테이너 (앱바 아래부터 시작)
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.of(context).padding.top +
                      56, // 시스템 상태바 + 앱바 높이만
                  bottom: 150, // 80에서 150으로 증가하여 버튼과 겹치지 않게
                ),
                controller: _scrollController,
                child: Column(
                  children: [
                    // 분홍+연보라 섹션 (QR 코드) - 가로로 나눔
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          // 왼쪽 분홍 섹션 (65%) - 70%에서 65%로 줄임
                          Expanded(
                            flex: 65, // 70에서 65로 변경
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD8F1), // 분홍색
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                  vertical: 15,
                                ),
                                child: Center(
                                  // 전체를 중앙 정렬
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // 최소 크기로 설정
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // QR 텍스트
                                      const Text(
                                        'QR을 붙이면\n언제 어디서든 대화할 수 있어요!',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 16, // 16에서 18로 증가
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
                                      ),

                                      const SizedBox(height: 2), // 8에서 4로 더 줄임
                                      // 저장하기, 공유하기 버튼
                                      Row(
                                        children: [
                                          Expanded(
                                            // 다시 Expanded로 변경
                                            child: ElevatedButton.icon(
                                              onPressed: () => _saveQRCode(),
                                              icon: const Icon(
                                                Icons.download,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                '저장하기',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 12,
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
                                            // 다시 Expanded로 변경
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
                                                  fontSize: 12,
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

                          // 오른쪽 연보라 섹션 (35%) - QR 코드 - 30%에서 35%로 증가
                          Expanded(
                            flex: 35, // 30에서 35로 변경
                            child: GestureDetector(
                              onTap: () => _showQRPopup(character),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC8A6FF), // 연보라색
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90, // 80에서 90으로 증가
                                    height: 90, // 80에서 90으로 증가
                                    padding: const EdgeInsets.all(
                                      4,
                                    ), // 8에서 4로 줄임 (여백 축소)
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: RepaintBoundary(
                                      key: _qrKey,
                                      child: QrImageView(
                                        data: _generateQRData(character),
                                        version: QrVersions.auto,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 파란색 섹션 (캐릭터 정보) - 아래 라운딩 추가
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C7E8),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            // 캐릭터 이름과 나이
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '털찐말랑이',
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${DateTime.now().year}년 ${DateTime.now().month}월생',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          '멘탈지기',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          provider.state.userInput?.location ??
                                              '우리집 거실',
                                          style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 촬영한 사진과 말풍선 겹치게 배치
                            SizedBox(
                              height: 420, // 전체 높이 증가하여 말풍선 잘림 방지
                              child: Stack(
                                children: [
                                  // 촬영한 사진 표시 (20px 더 증가)
                                  Container(
                                    width: double.infinity,
                                    height: 230, // 210px에서 230px로 20px 증가
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        provider.state.photoPath != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(provider.state.photoPath!),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 230, // 210에서 230으로 변경
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.access_time,
                                                    size: 60,
                                                    color: Colors.red,
                                                  );
                                                },
                                              ),
                                            )
                                            : const Icon(
                                              Icons.access_time,
                                              size: 60,
                                              color: Colors.red,
                                            ),
                                  ),

                                  // bubble@2x.png 이미지 (말풍선 상단 오른쪽에 위치) - 40px 위로
                                  Positioned(
                                    top: 50, // 90에서 50으로 40px 위로 이동
                                    right: 30,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble@2x.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 버블 배경 이미지 위에 태그와 텍스트 - 20px 위로
                                  Positioned(
                                    top: 90, // 110에서 90으로 20px 위로 이동
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      width: double.infinity,
                                      height: 280, // 높이 더 증가하여 잘림 방지
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble_bg@2x.png',
                                          ),
                                          fit:
                                              BoxFit
                                                  .fitWidth, // 가로 넓이에 맞춰서 비율 유지
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 50,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 성격 태그들 (성격 슬라이더 기반)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildPersonalityTag(
                                                  _getPersonalityTag1(
                                                    provider.state,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildPersonalityTag(
                                                  _getPersonalityTag2(
                                                    provider.state,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 24),

                                            // 말풍선 텍스트 (버블 배경 위에)
                                            const Column(
                                              children: [
                                                Text(
                                                  '가끔 털이 엉킬까봐 걱정돼 :(',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  '가끔 털이 엉킬까봐 걱정돼 :(',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 사진/말풍선과 성격차트 사이 간격 (두 배로 증가)
                            const SizedBox(height: 80), // 기존 40에서 80으로 두 배 증가

                            const SizedBox(height: 40), // 성격차트 위 간격
                            // 성격 차트 추가
                            Builder(
                              builder: (context) {
                                final personalityData =
                                    _generatePersonalityData(provider.state);
                                final traits =
                                    personalityData["성격특성"]
                                        as Map<String, dynamic>;

                                return PersonalityChart(
                                  warmth: (traits["온기"] as double),
                                  competence: (traits["능력"] as double),
                                  extroversion: (traits["외향성"] as double),
                                  creativity: (traits["창의성"] as double),
                                  humour: (traits["유머감각"] as double),
                                  reliability: (traits["신뢰성"] as double),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 플로팅 대화 시작 버튼 (배경없음)
              Positioned(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chat/${character.id}',
                        arguments: character,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '지금 바로 대화해요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // 플로팅 스크롤 힌트 화살표 (말풍선 아래 오른쪽 고정 위치)
              Positioned(
                right: 30,
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    24 +
                    56 +
                    15, // 버튼 아래 여백 + 버튼 높이 + 15px 위
                child: GestureDetector(
                  onTap: () {
                    if (_scrollController.hasClients) {
                      if (_isScrolledToBottom) {
                        // 하단에서 클릭 시 하늘색 영역 상단으로 이동 (앱바 바로 아래)
                        _scrollController.animateTo(
                          140.0, // QR 섹션 높이만큼 스크롤하여 하늘색 섹션이 앱바 바로 아래 오도록
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // 상단에서 클릭 시 하늘색 섹션 끝으로 이동
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isScrolledToBottom
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // 상단 고정 앱바 (라운딩 처리)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // 시스템 상태바 영역만 연두색
                    Container(
                      height: MediaQuery.of(context).padding.top,
                      width: double.infinity,
                      color: const Color(0xFFC5FF35), // 시스템 상태바만 연두색
                    ),

                    // 앱바 영역 (라운딩된 부분 밖은 투명)
                    Container(
                      height: 56,
                      width: double.infinity,
                      color: Colors.transparent, // 라운딩 밖 영역은 투명
                      child: Stack(
                        children: [
                          // 라운딩된 앱바 배경
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC5FF35), // 앱바만 연두색
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              border: Border(
                                left: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          // 앱바 콘텐츠
                          Row(
                            children: [
                              // 뒤로가기 버튼
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),

                              // 중앙 타이틀
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${character.name.isNotEmpty ? character.name : '털찐말랑이'}이 깨어났어요!',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 오른쪽 여백 (뒤로가기 버튼과 대칭)
                              const SizedBox(width: 48),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  String _generateQRData(Character character) {
    final data = {
      'characterId': character.id,
      'name': character.name,
      'objectType': character.objectType,
      'personality': {
        'warmth': character.personality.warmth,
        'competence': character.personality.competence,
        'extroversion': character.personality.extroversion,
      },
      'greeting': character.greeting,
      'traits': character.traits,
      'createdAt': character.createdAt?.toIso8601String(),
    };

    return 'nompangs://character?data=${base64Encode(utf8.encode(jsonEncode(data)))}';
  }

  Future<void> _saveQRCode() async {
    try {
      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 갤러리에 저장 - 권한 확인 없이 바로 시도
      try {
        await Gal.putImage(file.path, album: 'Nompangs');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (galError) {
        // Gal 저장 실패 시 권한 요청 후 재시도
        print('Gal 저장 실패, 권한 확인 중: $galError');

        bool hasPermission = false;

        if (Platform.isAndroid) {
          // Android 권한 요청
          var photosStatus = await Permission.photos.request();
          var storageStatus = await Permission.storage.request();
          hasPermission = photosStatus.isGranted || storageStatus.isGranted;

          if (!hasPermission) {
            var manageStatus = await Permission.manageExternalStorage.request();
            hasPermission = manageStatus.isGranted;
          }
        } else if (Platform.isIOS) {
          final status = await Permission.photosAddOnly.request();
          hasPermission = status.isGranted;
        }

        if (hasPermission) {
          // 권한 획득 후 재시도
          await Gal.putImage(file.path, album: 'Nompangs');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('저장소 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // 임시 파일 삭제
      await file.delete();
    } catch (e) {
      print('QR 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode(Character character) async {
    try {
      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 이미지와 함께 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${character.name}와 함께하세요! 놈팽쓰 QR 코드입니다 🎉\n\nQR을 스캔하면 ${character.name}과 대화할 수 있어요!',
        subject: '놈팽쓰 친구 공유 - ${character.name}',
      );

      // 잠시 후 임시 파일 삭제
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.delete();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QR 코드가 공유되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2), // 2초로 단축
          ),
        );
      }
    } catch (e) {
      print('QR 공유 오류: $e');
      if (mounted) {
        // 실패 시 기본 텍스트 공유
        final qrData = _generateQRData(character);
        await Share.share(
          '${character.name}와 함께하세요! 놈팽쓰 QR: $qrData',
          subject: '놈팽쓰 친구 공유',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 이미지 공유 실패, 텍스트로 공유되었습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2), // 2초로 단축
          ),
        );
      }
    }
  }

  // QR 코드 팝업 표시
  void _showQRPopup(Character character) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(), // 밖 부분 누르면 사라짐
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // QR 영역 클릭 시 팝업이 닫히지 않도록
                onLongPress: () {
                  Navigator.of(context).pop();
                  _saveQRCode(); // 길게 누르면 저장
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8A6FF), // 연보라색
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: _generateQRData(character),
                          version: QrVersions.auto,
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

  String _getPersonalityTag1(OnboardingState state) {
    // 첫 번째 태그: 내향성 기반 (수줍음 ↔ 활발함)
    final introversion = state.introversion ?? 5;
    if (introversion <= 3) {
      return '#수줍음';
    } else if (introversion >= 7) {
      return '#활발함';
    } else {
      return '#적당함';
    }
  }

  String _getPersonalityTag2(OnboardingState state) {
    // 두 번째 태그: 감정표현과 유능함 조합 기반
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    if (warmth >= 7 && competence >= 7) {
      return '#따뜻하고능숙';
    } else if (warmth >= 7) {
      return '#따뜻함';
    } else if (competence >= 7) {
      return '#능숙함';
    } else if (warmth <= 3 && competence <= 3) {
      return '#차갑고서툰';
    } else if (warmth <= 3) {
      return '#차가움';
    } else if (competence <= 3) {
      return '#서툰';
    } else {
      return '#균형잡힌';
    }
  }

  // 백엔드 스타일의 성격 데이터 생성 (실제로는 API에서 받아올 데이터)
  Map<String, dynamic> _generatePersonalityData(OnboardingState state) {
    // 사용자가 설정한 값을 기반으로 백엔드 스타일 성격특성 생성
    final warmth = (state.warmth ?? 5).toDouble();
    final competence = (state.competence ?? 5).toDouble();
    final introversion = (state.introversion ?? 5).toDouble();

    return {
      "성격특성": {
        "온기": warmth * 10, // 1-10을 10-100으로 변환
        "능력": competence * 10,
        "외향성": (11 - introversion) * 10, // introversion 역변환
        "유머감각": 75.0, // 백엔드에서는 기본적으로 높음
        "창의성": 60 + (warmth * 4), // warmth 기반
        "신뢰성": 50 + (competence * 5), // competence 기반
      },
      "유머스타일": state.humorStyle.isNotEmpty ? state.humorStyle : "따뜻한 유머러스",
      "매력적결함": ["가끔 털이 엉킬까봐 걱정돼 :(", "완벽하게 정리되지 않으면 불안해함", "친구들과 함께 있을 때 더 빛남"],
    };
  }
}
