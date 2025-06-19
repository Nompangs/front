import 'package:flutter/material.dart';
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
  double? extroversionValue;
  double? warmthValue;
  double? competenceValue;

  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 Provider 값으로 슬라이더 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();
      setState(() {
        // 1-10 범위의 int 값을 0.0-1.0 범위의 double로 변환
        extroversionValue = (provider.state.extroversion ?? 5) / 10.0;
        warmthValue = (provider.state.warmth ?? 5) / 10.0;
        competenceValue = (provider.state.competence ?? 5) / 10.0;
      });
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
                  title: '외향성',
                  value: extroversionValue ?? 0.5,
                  leftLabel: '수줍음',
                  rightLabel: '활발함',
                  onChanged: (value) {
                    setState(() => extroversionValue = value);
                    final intValue = (value * 10).round();
                    debugPrint("🎯 [성격화면] 외향성 슬라이더 변경: $value → $intValue");
                    // 슬라이더를 움직일 때마다 Provider 상태 업데이트
                    Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    ).updatePersonalitySlider('extroversion', intValue);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildPersonalitySection(
                  screenWidth: screenWidth,
                  color: const Color(0xFFFF8C42),
                  title: '감정표현',
                  value: warmthValue ?? 0.5,
                  leftLabel: '차가운',
                  rightLabel: '따뜻한',
                  onChanged: (value) {
                    setState(() => warmthValue = value);
                    final intValue = (value * 10).round();
                    debugPrint("🎯 [성격화면] 따뜻함 슬라이더 변경: $value → $intValue");
                    Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    ).updatePersonalitySlider('warmth', intValue);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildPersonalitySection(
                  screenWidth: screenWidth,
                  color: const Color(0xFF90EE90),
                  title: '유능함',
                  value: competenceValue ?? 0.5,
                  leftLabel: '서툰',
                  rightLabel: '능숙한',
                  onChanged: (value) {
                    setState(() => competenceValue = value);
                    final intValue = (value * 10).round();
                    debugPrint("🎯 [성격화면] 유능함 슬라이더 변경: $value → $intValue");
                    Provider.of<OnboardingProvider>(
                      context,
                      listen: false,
                    ).updatePersonalitySlider('competence', intValue);
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
                onPressed: () {
                  // 현재 슬라이더 값으로 최종 업데이트 보장
                  final provider = context.read<OnboardingProvider>();
                  final introVal = ((extroversionValue ?? 0.5) * 10).round();
                  final warmthVal = ((warmthValue ?? 0.5) * 10).round();
                  final compVal = ((competenceValue ?? 0.5) * 10).round();

                  debugPrint("🎯 [성격화면] 성격 저장하기 버튼 클릭:");
                  debugPrint("  - 외향성: ${extroversionValue} → $introVal");
                  debugPrint("  - 따뜻함: ${warmthValue} → $warmthVal");
                  debugPrint("  - 유능함: ${competenceValue} → $compVal");

                  provider.updatePersonalitySlider('extroversion', introVal);
                  provider.updatePersonalitySlider('warmth', warmthVal);
                  provider.updatePersonalitySlider('competence', compVal);

                  // 최종 완료 화면으로 이동
                  Navigator.pushNamed(context, '/onboarding/completion');
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
