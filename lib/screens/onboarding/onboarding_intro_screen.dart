import 'package:flutter/material.dart';
import 'dart:async';

/// 온보딩 인트로 화면
/// Figma 노드: 14:3266 - 온보딩 - 인트로
/// "지금부터 당신의 애착 사물을 깨워볼께요." 메시지와 함께 서비스 소개
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _scrollController;
  late AnimationController _dotsController;
  late Animation<double> _scrollAnimation;

  Timer? _textTimer;
  int _currentTextIndex = 0;

  final List<String> loadingTexts = [
    '기억을 소환하고 있어요..',
    '특별한 순간을 찾고 있어요..',
    '감정을 읽어내고 있어요..',
    '마법을 준비하고 있어요..',
  ];

  @override
  void initState() {
    super.initState();

    // 가로 스크롤 애니메이션
    _scrollController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _scrollAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scrollController, curve: Curves.linear));

    // 점 애니메이션
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // 텍스트 순환 타이머
    _textTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % loadingTexts.length;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dotsController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 아이보리 섹션 (원래 Expanded 방식으로 복원)
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF7E9),
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1),
                      right: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 앱바 영역 (SafeArea 포함)
                      SafeArea(bottom: false, child: _buildAppBar(context)),

                      // 메인 콘텐츠 (세로 중앙 배치)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 상단 고정 이미지
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, -20),
                                  child: _buildTopImage(),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 메인 텍스트
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: _buildMainTextWithDots(),
                              ),

                              const SizedBox(height: 90),

                              // 가로 스크롤 이미지들
                              Transform.translate(
                                offset: const Offset(0, 10),
                                child: _buildScrollingImages(),
                              ),

                              const SizedBox(height: 40),

                              // 로딩 텍스트
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, 10),
                                  child: _buildRotatingLoadingText(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 투명한 스페이서 박스 (아이보리와 버튼 사이 간격 유지)
              Container(
                height: 15, // 30에서 15로 절반으로 줄임
                color: Colors.transparent,
              ),

              // 하단 흰색 여백 (버튼 공간 확보)
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24 + 56),
            ],
          ),

          // 플로팅 다음 버튼 (completion_screen과 정확히 동일한 위치)
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
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/onboarding/input');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 앱바 위젯 (배경 제거)
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      // 배경색 제거
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),

          // 빈 공간
          const Spacer(),

          // 건너뛰기 버튼
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상단 고정 이미지 (50% 축소) - 개별 패딩
  Widget _buildTopImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/ui_assets/placeHolder_4@2x.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 가로 스크롤 이미지들 (20% 더 증가: 120 -> 144)
  Widget _buildScrollingImages() {
    return SizedBox(
      height: 144, // 120 -> 144로 증가
      child: AnimatedBuilder(
        animation: _scrollAnimation,
        builder: (context, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Transform.translate(
              offset: Offset(
                -_scrollAnimation.value * 720,
                0,
              ), // 이미지 크기 증가에 맞춰 오프셋 조정 (600 -> 720)
              child: Row(
                children: [
                  // 첫 번째 세트
                  _buildImageSet(),
                  // 두 번째 세트 (반복용)
                  _buildImageSet(),
                  // 세 번째 세트 (반복용)
                  _buildImageSet(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 이미지 세트 (4개 이미지) - 20% 더 증가
  Widget _buildImageSet() {
    return Row(
      children: [
        _buildGroupImage('assets/ui_assets/gr_0.png'),
        const SizedBox(width: 36), // 간격도 20% 증가 (30 -> 36)
        _buildGroupImage('assets/ui_assets/gr_1.png'),
        const SizedBox(width: 36),
        _buildGroupImage('assets/ui_assets/gr_2.png'),
        const SizedBox(width: 36),
        _buildGroupImage('assets/ui_assets/gr_3.png'),
        const SizedBox(width: 36),
      ],
    );
  }

  /// 개별 그룹 이미지 (20% 더 증가: 120 -> 144)
  Widget _buildGroupImage(String imagePath) {
    return Container(
      width: 144, // 120 -> 144로 증가
      height: 144, // 120 -> 144로 증가
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 메인 텍스트 (점 애니메이션 제거) - 중앙정렬
  Widget _buildMainTextWithDots() {
    return const Text(
      '지금부터 당신의\n애착 사물을 깨워볼게요',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 22, // 26 -> 22로 축소
        height: 1.5,
        color: Colors.black,
      ),
    );
  }

  /// 순환하는 로딩 텍스트
  Widget _buildRotatingLoadingText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        loadingTexts[_currentTextIndex],
        key: ValueKey(_currentTextIndex),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
