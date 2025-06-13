import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/services/personality_service.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';

class OnboardingGenerationScreen extends StatefulWidget {
  const OnboardingGenerationScreen({super.key});

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

  // 타임아웃 관련 변수 추가
  Timer? _timeoutTimer;
  bool _isTimedOut = false;
  int _remainingSeconds = 6;
  Timer? _countdownTimer;
  Timer? _longRunningTimer;

  final List<GenerationStep> steps = [
    GenerationStep(0.25, '캐릭터 깨우는 중...', '사물의 기본 특성을 분석하고 있어요'),
    GenerationStep(0.5, '개성을 찾고 있어요', '사물의 고유한 성격을 만들어요'),
    GenerationStep(0.75, '마음을 열고 있어요', '당신만의 특별한 친구가 탄생하고 있어요'),
    GenerationStep(1.0, '거의 완성되었어요', '마지막 손질을 하고 있어요'),
  ];

  final PersonalityService _personalityService = const PersonalityService();

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
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _longRunningTimer?.cancel();
    super.dispose();
  }

  void _checkAndStartGeneration() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);

    // 사용자 입력이 없는 경우 에러 처리
    if (provider.state.userInput == null) {
      provider.setError('사용자 입력 정보가 없습니다. 이전 단계로 돌아가서 정보를 입력해주세요.');
      return;
    }

    // 이미 생성된 캐릭터가 있는 경우 바로 다음 페이지로 이동
    if (provider.state.generatedCharacter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding/personality');
        }
      });
      return;
    }

    // 생성 중이 아니고 캐릭터가 없는 경우에만 생성 시작
    if (!provider.state.isGenerating) {
      _startGeneration();
      _startTimeoutTimer(); // 타임아웃 타이머 시작
    }
  }

  void _startTimeoutTimer() {
    // 6초 후 타임아웃 처리
    _timeoutTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_isTimedOut) {
        setState(() {
          _isTimedOut = true;
        });
        _showTimeoutDialog();
      }
    });

    // 카운트다운 타이머 (UI 표시용)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                '시간이 오래 걸리고 있어요',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: const Text(
            '캐릭터 생성이 예상보다 오래 걸리고 있어요.\n사진을 다시 촬영하거나 잠시 후 다시 시도해보세요.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _goBackToPhoto(); // 사진 촬영 화면으로 이동
              },
              child: const Text(
                '사진 다시 촬영',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _retryGeneration(); // 다시 시도
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD8F1),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _goBackToPhoto() {
    // 캐시 클린업
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.clearError();

    // 사진 촬영 화면으로 이동
    Navigator.pushReplacementNamed(context, '/onboarding/photo');
  }

  void _retryGeneration() {
    // 상태 초기화
    setState(() {
      _isTimedOut = false;
      _remainingSeconds = 6;
    });

    // 타이머 재시작
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();

    // 생성 다시 시도
    _startGeneration();
    _startTimeoutTimer();
  }

  Future<void> _startGeneration() async {
    final provider = context.read<OnboardingProvider>();
    if (provider.isGenerating) return;

    provider.setGenerating(true, "페르소나 분석을 시작합니다...");

    // 15초 후에 메시지를 변경하는 타이머를 설정합니다.
    _longRunningTimer = Timer(const Duration(seconds: 15), () {
      if (provider.isGenerating && mounted) {
        provider.setGenerating(true, "꼼꼼하게 분석 중이에요.\n시간이 조금 더 걸릴 수 있어요...");
      }
    });

    try {
      final PersonalityProfile generatedProfile =
          await _personalityService.generateProfile(provider.state);
      
      _longRunningTimer?.cancel(); // 성공 시 타이머 취소

      if (generatedProfile.aiPersonalityProfile == null ||
          generatedProfile.aiPersonalityProfile!.summary.isEmpty ||
          generatedProfile.structuredPrompt.isEmpty) {
        throw Exception("생성된 프로필의 핵심 데이터가 비어있습니다.");
      }

      debugPrint("✅ 페르소나 생성 성공! 요약: ${generatedProfile.aiPersonalityProfile!.summary}");

      // 3. Provider에 최종 결과 저장
      provider.setFinalPersonality(generatedProfile);
      provider.setGenerating(false, "생성 완료!");

      // 4. 완료 화면으로 이동
      Navigator.pushNamed(context, '/onboarding/completion');

    } catch (e, s) {
      _longRunningTimer?.cancel(); // 실패 시에도 타이머 취소
      debugPrint("🚨 페르소나 생성 실패: $e");
      debugPrint("   - StackTrace: $s");
      provider.setErrorMessage("페르소나 생성에 실패했습니다. 다시 시도해주세요.");
      provider.setGenerating(false, "오류 발생");
      // 필요하다면 에러 팝업 후 이전 화면으로 이동
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text('페르소나 생성 중 오류가 발생했습니다.\n\n$message'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 이전 화면으로 돌아가기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFD8F1), // 전체 배경을 분홍색으로 설정
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 앱바 배경을 투명하게 하여 통합된 느낌
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // 타이머 정리
            _timeoutTimer?.cancel();
            _countdownTimer?.cancel();

            // 캐시 클린업
            final provider = Provider.of<OnboardingProvider>(
              context,
              listen: false,
            );
            provider.clearError();

            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey,
                fontSize: 16,
              ),
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

          // 별도의 Container 없이 직접 Column 사용하여 통합된 배경 구현
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
                      fontFamily: 'Pretendard',
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
                      fontFamily: 'Pretendard',
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
                  child: Column(
                    children: [
                      _buildProgressIndicator(state.generationProgress),

                      // 남은 시간 표시 (자연스럽게)
                      if (!_isTimedOut &&
                          _remainingSeconds > 0 &&
                          state.isGenerating)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '잠시만 기다려주세요... ($_remainingSeconds초)',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
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
    return Container(
      color: Colors.white, // 에러 화면 배경도 흰색
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[400]),

              const SizedBox(height: 24),

              Text(
                '생성 중 오류가 발생했어요',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                error,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
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
                        child: Text(
                          hasUserInput ? '다시 시도' : '정보 입력하러 가기',
                          style: const TextStyle(fontFamily: 'Pretendard'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/onboarding/input',
                            ),
                        child: const Text(
                          '이전으로 돌아가기',
                          style: TextStyle(fontFamily: 'Pretendard'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
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
