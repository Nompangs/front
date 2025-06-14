import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';

class OnboardingPersonalityScreen extends StatefulWidget {
  const OnboardingPersonalityScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingPersonalityScreen> createState() =>
      _OnboardingPersonalityScreenState();
}

class _OnboardingPersonalityScreenState
    extends State<OnboardingPersonalityScreen> {
  double introversionValue = 0.5;
  double emotionalValue = 0.7;
  double competenceValue = 0.3;

  @override
  void initState() {
    super.initState();

    // 초기 상태 로깅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      _logPersonalityState('초기 상태', provider);
    });
  }

  /// 성격 상태 변화 로깅
  void _logPersonalityState(String action, OnboardingProvider provider) {
    if (!kDebugMode) return;

    debugPrint('🎭 [$action] 성격 조정 화면 상태:');
    debugPrint('   📊 슬라이더 값:');
    debugPrint(
      '      - 내향성: ${introversionValue.toStringAsFixed(2)} (${(introversionValue * 10).round()}/10)',
    );
    debugPrint(
      '      - 감정표현: ${emotionalValue.toStringAsFixed(2)} (${(emotionalValue * 10).round()}/10)',
    );
    debugPrint(
      '      - 유능함: ${competenceValue.toStringAsFixed(2)} (${(competenceValue * 10).round()}/10)',
    );

    final state = provider.state;
    debugPrint('   🔧 Provider 상태:');
    debugPrint('      - 내향성: ${state.introversion}/10');
    debugPrint('      - 온기: ${state.warmth}/10');
    debugPrint('      - 능력: ${state.competence}/10');

    final profile = provider.personalityProfile;
    final variablesCount = profile.personalityVariables.length;
    debugPrint('   🧬 성격 변수: ${variablesCount}개');

    if (variablesCount > 0) {
      final categoryAverages = profile.getCategoryAverages();
      debugPrint('   📈 카테고리별 평균:');
      categoryAverages.forEach((category, average) {
        debugPrint('      - $category: ${average.toStringAsFixed(1)}점');
      });
    }
    debugPrint('');
  }

  /// 성격 변수 변동 사항 상세 로깅
  void _logPersonalityVariableChanges(
    String sliderType,
    double oldValue,
    double newValue,
    OnboardingProvider provider,
  ) {
    if (!kDebugMode) return;

    final oldProfile = provider.personalityProfile;
    final oldAverages = oldProfile.getCategoryAverages();

    debugPrint('🔄 성격 변수 변동 분석 [$sliderType]:');
    debugPrint(
      '   📊 슬라이더 변화: ${oldValue.toStringAsFixed(2)} → ${newValue.toStringAsFixed(2)}',
    );
    debugPrint(
      '   🎯 변화량: ${(newValue - oldValue).toStringAsFixed(2)} (${((newValue - oldValue) * 10).toStringAsFixed(1)}점)',
    );

    // 변동 후 상태는 Provider에서 자동으로 로깅됨
    Future.delayed(const Duration(milliseconds: 100), () {
      final newProfile = provider.personalityProfile;
      final newAverages = newProfile.getCategoryAverages();

      debugPrint('   📈 카테고리별 변화:');
      newAverages.forEach((category, newAvg) {
        final oldAvg = oldAverages[category] ?? 0;
        final change = newAvg - oldAvg;
        if (change.abs() > 0.1) {
          // 0.1점 이상 변화만 표시
          final changeStr =
              change > 0
                  ? '+${change.toStringAsFixed(1)}'
                  : change.toStringAsFixed(1);
          debugPrint(
            '      - $category: ${oldAvg.toStringAsFixed(1)} → ${newAvg.toStringAsFixed(1)} ($changeStr)',
          );
        }
      });
      debugPrint('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.pushNamed(context, '/onboarding/completion'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 상단 베이지 섹션 (이미지)
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5DC),
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.1,
                    20,
                    screenWidth * 0.05,
                    24,
                  ),
                  child: Center(
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.6,
                      child: Image.asset(
                        'assets/ui_assets/placeHolder_1@2x.png',
                        width: screenWidth * 0.6,
                        height: screenWidth * 0.6,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              // 3개 조절 섹션 (동일 높이)
              Expanded(
                flex: 2,
                child: _buildPersonalitySection(
                  screenWidth: screenWidth,
                  color: const Color(0xFFFFD700),
                  title: '내향성',
                  value: introversionValue,
                  leftLabel: '수줍음',
                  rightLabel: '활발함',
                  onChanged: (value) {
                    final oldValue = introversionValue;
                    setState(() => introversionValue = value);

                    final provider = Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    );

                    // 변동 사항 로깅
                    _logPersonalityVariableChanges(
                      '내향성',
                      oldValue,
                      value,
                      provider,
                    );

                    provider.updatePersonalitySlider(
                      'introversion',
                      (value * 10).round(),
                    );

                    // 업데이트 후 상태 로깅
                    _logPersonalityState('내향성 조정 후', provider);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildPersonalitySection(
                  screenWidth: screenWidth,
                  color: const Color(0xFFFF8C42),
                  title: '감정표현',
                  value: emotionalValue,
                  leftLabel: '차가운',
                  rightLabel: '따뜻한',
                  onChanged: (value) {
                    final oldValue = emotionalValue;
                    setState(() => emotionalValue = value);

                    final provider = Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    );

                    // 변동 사항 로깅
                    _logPersonalityVariableChanges(
                      '감정표현',
                      oldValue,
                      value,
                      provider,
                    );

                    provider.updatePersonalitySlider(
                      'warmth',
                      (value * 10).round(),
                    );

                    // 업데이트 후 상태 로깅
                    _logPersonalityState('감정표현 조정 후', provider);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildPersonalitySection(
                  screenWidth: screenWidth,
                  color: const Color(0xFF90EE90),
                  title: '유능함',
                  value: competenceValue,
                  leftLabel: '서툰',
                  rightLabel: '능숙한',
                  onChanged: (value) {
                    final oldValue = competenceValue;
                    setState(() => competenceValue = value);

                    final provider = Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    );

                    // 변동 사항 로깅
                    _logPersonalityVariableChanges(
                      '유능함',
                      oldValue,
                      value,
                      provider,
                    );

                    provider.updatePersonalitySlider(
                      'competence',
                      (value * 10).round(),
                    );

                    // 업데이트 후 상태 로깅
                    _logPersonalityState('유능함 조정 후', provider);
                  },
                ),
              ),
              // 투명 스페이서
              Container(height: 15, color: Colors.transparent),
              // 하단 여백
              SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
            ],
          ),
          // 플로팅 저장 버튼
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
                onPressed: () async {
                  final provider = context.read<OnboardingProvider>();

                  debugPrint('💾 성격 저장 버튼 클릭');
                  debugPrint('   📊 최종 슬라이더 값:');
                  debugPrint(
                    '      - 내향성: ${(introversionValue * 10).round()}/10',
                  );
                  debugPrint(
                    '      - 감정표현: ${(emotionalValue * 10).round()}/10',
                  );
                  debugPrint(
                    '      - 유능함: ${(competenceValue * 10).round()}/10',
                  );

                  // 최종 슬라이더 값들을 Provider에 저장
                  provider.updatePersonalitySlider(
                    'warmth',
                    (emotionalValue * 10).round(),
                  );
                  provider.updatePersonalitySlider(
                    'introversion',
                    (introversionValue * 10).round(),
                  );
                  provider.updatePersonalitySlider(
                    'emotional',
                    (emotionalValue * 10).round(),
                  );
                  provider.updatePersonalitySlider(
                    'competence',
                    (competenceValue * 10).round(),
                  );

                  // 최종 상태 로깅
                  _logPersonalityState('최종 저장', provider);

                  // AI 기반 분석 생성
                  try {
                    await provider.generateAiAnalysis();
                    debugPrint('✅ AI 분석 생성 완료');
                  } catch (e) {
                    debugPrint('⚠️ AI 분석 생성 실패: $e');
                    // 실패해도 계속 진행
                  }

                  final finalProfile = provider.personalityProfile;
                  debugPrint('🎯 최종 성격 프로필 요약:');
                  debugPrint(
                    '   - 성격 변수: ${finalProfile.personalityVariables.length}개',
                  );
                  debugPrint(
                    '   - AI 프로필: ${finalProfile.aiPersonalityProfile?.name ?? '없음'}',
                  );
                  debugPrint(
                    '   - 매력적 결함: ${finalProfile.attractiveFlaws.length}개',
                  );
                  debugPrint(
                    '   - 모순적 특성: ${finalProfile.contradictions.length}개',
                  );

                  if (mounted) {
                    Navigator.pushNamed(context, '/onboarding/completion');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  '성격 저장하기',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection({
    required double screenWidth,
    required Color color,
    required String title,
    required double value,
    required String leftLabel,
    required String rightLabel,
    required Function(double) onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목 (중앙)
                Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 슬라이더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: Colors.white,
                      thumbColor: Colors.black,
                      thumbShape: RectangularSliderThumbShape(
                        borderColor: color,
                      ),
                      trackHeight: 8,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: value,
                      onChanged: onChanged,
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // 라벨들 (슬라이더 아래 양 끝)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        leftLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w200,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        rightLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w200,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 커스텀 썸 모양 (얇은 둥근사각형)
class RectangularSliderThumbShape extends SliderComponentShape {
  const RectangularSliderThumbShape({this.borderColor});

  final Color? borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(6, 26); // 높이를 22에서 26으로 증가
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // 테두리 그리기
    if (borderColor != null) {
      final borderPaint =
          Paint()
            ..color = borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

      final borderRect = Rect.fromCenter(center: center, width: 6, height: 26);
      final borderRRect = RRect.fromRectAndRadius(
        borderRect,
        const Radius.circular(3),
      );
      canvas.drawRRect(borderRRect, borderPaint);
    }

    // 썸 본체 그리기
    final paint =
        Paint()
          ..color = sliderTheme.thumbColor ?? Colors.black
          ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: 4, height: 24);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    canvas.drawRRect(rrect, paint);
  }
}
