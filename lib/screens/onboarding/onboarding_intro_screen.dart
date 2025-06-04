import 'package:flutter/material.dart';

/// 온보딩 인트로 화면
/// Figma 노드: 14:3266 - 온보딩 - 인트로
/// "지금부터 당신의 애착 사물을 깨워볼께요." 메시지와 함께 서비스 소개
class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9), // Figma 배경색
      body: SafeArea(
        child: Column(
          children: [
            // 앱바 영역
            _buildAppBar(context),
            
            // 메인 콘텐츠 영역
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 40),
                    
                    // 캐릭터 이미지들
                    _buildCharacterImages(),
                    
                    const SizedBox(height: 40),
                    
                    // 메인 텍스트
                    _buildMainText(),
                    
                    const SizedBox(height: 20),
                    
                    // 로딩 텍스트
                    _buildLoadingText(),
                    
                    const Spacer(),
                    
                    // 하단 버튼
                    _buildFooterButton(context),
                    
                    const SizedBox(height: 34), // HomeIndicator 공간
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 앱바 위젯
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
          
          // 타이틀
          const Expanded(
            child: Text(
              '성격 조제 연금술!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // 건너뛰기 버튼
          TextButton(
            onPressed: () {
              // 건너뛰기 로직 - 메인 화면으로 이동
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFFBCBCBC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 캐릭터 이미지들 위젯
  Widget _buildCharacterImages() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCharacterImage(Colors.orange),
        _buildCharacterImage(Colors.blue),
        _buildCharacterImage(Colors.green),
      ],
    );
  }

  /// 개별 캐릭터 이미지 위젯
  Widget _buildCharacterImage(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.star,
        color: color,
        size: 40,
      ),
    );
  }

  /// 메인 텍스트 위젯
  Widget _buildMainText() {
    return const Text(
      '지금부터 당신의\n애착 사물을 깨워볼께요.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 1.5, // 간단한 line height
        color: Color(0xFF333333),
      ),
    );
  }

  /// 로딩 텍스트 위젯 (애니메이션 포함)
  Widget _buildLoadingText() {
    return const Text(
      '기억을 소환하고 있어요..',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Color(0xFFBCBCBC),
      ),
    );
  }

  /// 하단 버튼 위젯
  Widget _buildFooterButton(BuildContext context) {
    return SizedBox(
      width: 343, // Figma 스펙
      height: 56,  // Figma 스펙
      child: ElevatedButton(
        onPressed: () {
          // 다음 화면으로 이동 (사물 정보 입력 화면)
          Navigator.pushNamed(context, '/onboarding/input');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4), // primary 색상
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Figma cornerRadius
          ),
        ),
        child: const Text(
          '캐릭터 깨우기',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 