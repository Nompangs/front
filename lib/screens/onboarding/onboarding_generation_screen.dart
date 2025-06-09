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
    GenerationStep(0.5, '개성을 찾고 있어요', '입력하신 정보를 바탕으로 고유한 성격을 만들어요'),
    GenerationStep(0.75, '마음을 열고 있어요', '당신만의 특별한 캐릭터가 탄생하고 있어요'),
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

          return Column(
            children: [
              // 상단 여백 (화면의 6%)
              SizedBox(height: screenHeight * 0.06),

              // 중앙 애니메이션 영역 (화면의 약 38%)
              SizedBox(
                height: screenHeight * 0.38,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 원형 확산 애니메이션 (최적 비율로 조정)
                      SizedBox(
                        width: 320,
                        height: 320,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 배경 원형 확산 애니메이션
                            AnimatedBuilder(
                              animation: _circleAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(320, 320),
                                  painter: CircleAnimationPainter(
                                    _circleAnimation.value,
                                  ),
                                );
                              },
                            ),

                            // 중앙에 촬영한 사진 표시 (더 세련된 디자인)
                            Container(
                              width: 135, // 130에서 135로 증가
                              height: 135,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3, // 4에서 3으로 줄임
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      0.04,
                                    ), // 아주 미묘한 그림자
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
                                          width: 135,
                                          height: 135,
                                        )
                                        : Container(
                                          color: const Color(
                                            0xFFFAFAFA,
                                          ), // 더 세련된 배경색
                                          child: const Icon(
                                            Icons
                                                .camera_alt_outlined, // outlined 버전으로 변경
                                            size: 42, // 45에서 42로 조정
                                            color: Color(
                                              0xFF9CA3AF,
                                            ), // 더 세련된 그레이
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 텍스트 영역 (화면의 약 22%)
              SizedBox(
                height: screenHeight * 0.22,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 현재 단계 표시 (더 세련된 타이포그래피)
                    Text(
                      state.generationMessage,
                      style: const TextStyle(
                        fontSize: 24, // 22에서 24로 증가
                        fontWeight: FontWeight.w700, // w600에서 w700으로 증가
                        color: Color(0xFF1F2937), // 더 세련된 다크 그레이
                        letterSpacing: -0.8, // -0.5에서 -0.8로 조정
                        height: 1.2, // 줄 간격 추가
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20), // 16에서 20으로 증가
                    // 설명 텍스트 (더 세련된 스타일)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                      ), // 40에서 50으로 증가
                      child: Text(
                        _getCurrentStepDescription(state.generationProgress),
                        style: const TextStyle(
                          fontSize: 14, // 15에서 14로 줄임
                          fontWeight: FontWeight.w400, // w300에서 w400으로 조정
                          color: Color(0xFF6B7280), // 더 세련된 그레이
                          height: 1.6, // 1.4에서 1.6으로 증가
                          letterSpacing: -0.1, // -0.2에서 -0.1로 조정
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 프로그레스바 영역 (화면의 하단 12%)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.12,
                  0,
                  screenWidth * 0.12,
                  screenHeight * 0.12,
                ),
                child: _buildProgressIndicator(state.generationProgress),
              ),
            ],
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
          height: 3, // 5에서 3으로 더 얇게
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // 투명도 더 낮춤
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 1200,
                ), // 800에서 1200으로 더 부드럽게
                curve: Curves.easeOutQuart, // 더 세련된 곡선
                width: MediaQuery.of(context).size.width * 0.76 * progress,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6366F1), // 더 모던한 인디고 블루
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(1.5),
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
    const maxRadius = 140.0; // 120.0에서 140.0으로 조정 (새로운 영역에 맞춤)
    const ringCount = 4; // 동심원 개수

    for (int i = 0; i < ringCount; i++) {
      // 각 링마다 다른 시작 시간을 가지도록 오프셋 적용
      final ringOffset = i * 0.2;
      final adjustedAnimation = ((animationValue + ringOffset) % 1.0);

      // 큰 원과 작은 원을 번갈아 표시 (크기 조정)
      final isLargeCircle = i % 2 == 0;
      final baseSize = isLargeCircle ? 10.0 : 6.0; // 12.0과 8.0에서 10.0과 6.0으로 조정

      // 원의 반지름 - 중앙에서 바깥으로 확장
      final radius = maxRadius * adjustedAnimation;

      // 투명도 - 시작할 때 불투명하고 퍼지면서 투명해짐
      final opacity =
          adjustedAnimation < 0.15
              ? 1.0 // 시작할 때는 완전 불투명
              : (1.0 - (adjustedAnimation - 0.15) / 0.85) * 0.85; // 더 자연스러운 페이드

      if (radius > 67.5) {
        // 중앙 사진 영역은 피하기 (135px 원이므로 67.5px 반지름)
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
                ..color = Colors.white.withOpacity(opacity * 0.9) // 약간 더 부드럽게
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
