import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'dart:math' as math;
import 'dart:io';

class OnboardingGenerationScreen extends StatefulWidget {
  const OnboardingGenerationScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingGenerationScreen> createState() =>
      _OnboardingGenerationScreenState();
}

class _OnboardingGenerationScreenState extends State<OnboardingGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _circleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _circleAnimation;

  final List<GenerationStep> steps = [
    GenerationStep(0.25, '캐릭터 깨우는 중...', '사물의 기본 특성을 분석하고 있어요'),
    GenerationStep(0.5, '개성을 찾고 있어요', '사물의 고유한 성격을 만들어요'),
    GenerationStep(0.75, '마음을 열고 있어요', '당신만의 특별한 친구가 탄생하고 있어요'),
    GenerationStep(1.0, '거의 완성되었어요', '마지막 손질을 하고 있어요'),
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _circleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // Provider 상태 확인 후 생성 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartGeneration();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  void _checkAndStartGeneration() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);

    // 사용자 입력이 없는 경우 에러 처리
    if (provider.state.userInput == null) {
      provider.setError('사용자 입력 정보가 없습니다. 이전 단계로 돌아가서 정보를 입력해주세요.');
      return;
    }

    // 이미 생성 중이거나 완성된 경우가 아니라면 생성 시작
    if (!provider.state.isGenerating &&
        provider.state.generatedCharacter == null) {
      _startGeneration();
    }
  }

  void _startGeneration() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    await provider.generateCharacter();

    if (mounted && provider.state.generatedCharacter != null) {
      Navigator.pushReplacementNamed(context, '/onboarding/personality');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFD8F1), // 분홍색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD8F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          final state = provider.state;

          if (state.errorMessage != null) {
            return _buildErrorScreen(state.errorMessage!);
          }

          return SingleChildScrollView(
            // 스택 오버플로우 방지
            child: Column(
              children: [
                // 상단 여백 (애니메이션이 앱바에 잘리지 않도록)
                SizedBox(height: screenHeight * 0.08),

                // 중앙 애니메이션 영역
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 배경 원형 확산 애니메이션
                      AnimatedBuilder(
                        animation: _circleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(240, 240),
                            painter: CircleAnimationPainter(
                              _circleAnimation.value,
                            ),
                          );
                        },
                      ),

                      // 중앙에 촬영한 사진 표시
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              state.photoPath != null
                                  ? Image.file(
                                    File(state.photoPath!),
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  )
                                  : Container(
                                    color: const Color(0xFFFAFAFA),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 38,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 작은 간격 (동심원과 작은 텍스트 사이)
                SizedBox(height: screenHeight * 0.03),

                // 작은글씨 (설명 텍스트) - 동심원 바로 아래
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    _getCurrentStepDescription(state.generationProgress),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.6,
                      letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),

                // 프로그레스바가 화면 2/3 지점에 오도록 하는 간격
                // 현재까지 사용된 높이: 0.08 + 240px + 0.03 + 작은텍스트높이
                // 프로그레스바 위치: 0.67 * screenHeight
                // 큰 텍스트와 프로그레스바 간격을 고려한 계산
                SizedBox(
                  height:
                      screenHeight * 0.70 -
                      screenHeight * 0.08 -
                      240 -
                      screenHeight * 0.03 -
                      60 -
                      screenHeight * 0.03, // 큰 텍스트 높이와 간격 고려
                ),

                // 큰글씨 (메인 텍스트) - 프로그레스바 조금 위
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.generationMessage.isNotEmpty
                        ? state.generationMessage
                        : '캐릭터 깨우는 중...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 큰 텍스트와 프로그레스바 사이 간격
                SizedBox(height: screenHeight * 0.03),

                // 프로그레스바 영역 (화면의 3/4 지점)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.12),
                  child: _buildProgressIndicator(state.generationProgress),
                ),

                // 하단 여백
                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        // 세련된 프로그레스바
        Container(
          width: double.infinity,
          height: 6, // 4에서 6으로 더 두껍게
          decoration: BoxDecoration(
            color: Colors.white, // 투명도 제거하고 순수한 흰색으로 변경
            borderRadius: BorderRadius.circular(3), // 2에서 3으로 조정
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 1200,
                ), // 800에서 1200으로 더 부드럽게
                curve: Curves.easeOutQuart, // 더 세련된 곡선
                width: MediaQuery.of(context).size.width * 0.76 * progress,
                height: 6, // 4에서 6으로 변경
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4), // gradient에서 단일 색상으로 변경
                  borderRadius: BorderRadius.circular(3), // 2에서 3으로 조정
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCurrentStepDescription(double progress) {
    // 문구 변경을 더 천천히 하기 위해 약간의 지연 적용
    final adjustedProgress = (progress * 0.9 + 0.1).clamp(0.0, 1.0);
    int currentStepIndex = ((adjustedProgress * steps.length).floor()).clamp(
      0,
      steps.length - 1,
    );
    return steps[currentStepIndex].description;
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),

            const SizedBox(height: 24),

            Text(
              '생성 중 오류가 발생했어요',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            Consumer<OnboardingProvider>(
              builder: (context, provider, child) {
                final hasUserInput = provider.state.userInput != null;

                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();

                        if (hasUserInput) {
                          _startGeneration();
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            '/onboarding/input',
                          );
                        }
                      },
                      child: Text(hasUserInput ? '다시 시도' : '정보 입력하러 가기'),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed:
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/onboarding/input',
                          ),
                      child: const Text('이전으로 돌아가기'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CircleAnimationPainter extends CustomPainter {
  final double animationValue;

  CircleAnimationPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 동심원 애니메이션 - 중앙에서 바깥으로 퍼져나가는 원들
    const maxRadius = 120.0; // 130.0에서 120.0으로 조정 (새로운 240 영역에 맞춤)
    const ringCount = 4; // 동심원 개수

    for (int i = 0; i < ringCount; i++) {
      // 각 링마다 다른 시작 시간을 가지도록 오프셋 적용
      final ringOffset = i * 0.2;
      final adjustedAnimation = ((animationValue + ringOffset) % 1.0);

      // 큰 원과 작은 원을 번갈아 표시 (크기 조정)
      final isLargeCircle = i % 2 == 0;
      final baseSize =
          isLargeCircle ? 14.0 : 10.0; // 10.0과 6.0에서 14.0과 10.0으로 더 크게

      // 원의 반지름 - 중앙에서 바깥으로 확장
      final radius = maxRadius * adjustedAnimation;

      if (radius > 70.0) {
        // 중앙 사진 영역은 피하기 (140px 원이므로 70px 반지름)
        // 동심원 위에 작은 원들을 배치
        const pointCount = 12;
        for (int j = 0; j < pointCount; j++) {
          final angle = (2 * math.pi * j / pointCount);

          final pointCenter = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );

          final circlePaint =
              Paint()
                ..color =
                    Colors
                        .white // 투명도 제거하여 완전 불투명
                ..style = PaintingStyle.fill;

          canvas.drawCircle(pointCenter, baseSize, circlePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CircleAnimationPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

class GenerationStep {
  final double progress;
  final String title;
  final String description;

  GenerationStep(this.progress, this.title, this.description);
}
