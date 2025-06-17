import 'package:flutter/material.dart';
import 'dart:math' as math;

class PersonalityChart extends StatefulWidget {
  final double warmth;
  final double competence;
  final double extroversion;
  final double creativity;
  final double stability;
  final double conscientiousness;

  // PersonalityService에서 실제 생성되는 데이터만
  final List<String>? attractiveFlaws;
  final List<String>? contradictions;
  final String? communicationPrompt;

  const PersonalityChart({
    super.key,
    required this.warmth,
    required this.competence,
    required this.extroversion,
    required this.creativity,
    required this.stability,
    required this.conscientiousness,
    this.attractiveFlaws,
    this.contradictions,
    this.communicationPrompt,
  });

  @override
  State<PersonalityChart> createState() => _PersonalityChartState();
}

class _PersonalityChartState extends State<PersonalityChart> {
  String? selectedLabel;
  double? selectedValue;
  Offset? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final values = [
      widget.warmth,
      widget.competence,
      widget.extroversion,
      widget.creativity,
      widget.stability,
      widget.conscientiousness,
    ];
    final labels = ['온기', '능력', '외향성', '창의성', '안정성', '성실성'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 15),

        const Text(
          '성격 차트',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 30),

        // 터치 가능한 차트
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTapDown: (details) {
                _handleChartTap(details.localPosition, values, labels);
              },
              child: SizedBox(
                height: 280,
                width: 280,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: RadarChartPainter(values: values, labels: labels),
                ),
              ),
            ),

            // 툴팁 표시
            if (selectedLabel != null && tooltipPosition != null)
              Positioned(
                left: (tooltipPosition!.dx - 70).clamp(0.0, 140.0),
                top: (tooltipPosition!.dy - 100).clamp(-50.0, 100.0),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedValue!.toInt()}점',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getPersonalityDescription(selectedLabel!),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.3,
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

        const SizedBox(height: 30),

        Text(
          '차트를 터치해서 수치를 확인해보세요',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),

        const SizedBox(height: 40),

        // 성격 설명 섹션들
        _buildPersonalityDescription(),

        const SizedBox(height: 30),
      ],
    );
  }

  void _handleChartTap(
    Offset localPosition,
    List<double> values,
    List<String> labels,
  ) {
    final center = const Offset(140, 140);
    final radius = 90;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > radius + 30) return;

    var angle = math.atan2(dy, dx);
    angle = (angle + math.pi / 2) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;

    final sectionAngle = 2 * math.pi / 6;
    int sectionIndex = ((angle + sectionAngle / 2) / sectionAngle).floor() % 6;

    setState(() {
      selectedLabel = labels[sectionIndex];
      selectedValue = values[sectionIndex];
      tooltipPosition = localPosition;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          selectedLabel = null;
          selectedValue = null;
          tooltipPosition = null;
        });
      }
    });
  }

  Widget _buildPersonalityDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 번째 섹션: 소통 방식
        if (widget.communicationPrompt != null &&
            widget.communicationPrompt!.isNotEmpty) ...[
          _buildSectionDivider(),
          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              '소통 방식',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.communicationPrompt!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ),

          const SizedBox(height: 32),
        ],

        // 두 번째 섹션: 매력적인 결점들 (attractiveFlaws 사용)
        _buildSectionDivider(),
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '매력적인 결점',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 20),
        _buildAttractiveFlaws(),

        const SizedBox(height: 32),

        // 세 번째 섹션: 모순적 특성
        _buildSectionDivider(),
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '모순적 특성',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 20),
        _buildContradictoryTraits(),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Container(width: double.infinity, height: 1, color: Colors.black);
  }

  Widget _buildTraitDescription() {
    String description = _generatePersonalityDescription();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 17,
          height: 1.7,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildCoreTraits() {
    List<String> traits = _generateCoreTraits();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            traits.asMap().entries.map((entry) {
              int index = entry.key;
              String trait = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      child: const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trait,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContradictoryTraits() {
    List<String> traits = _generateContradictoryTraits();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            traits.asMap().entries.map((entry) {
              int index = entry.key;
              String trait = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      child: const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trait,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCharmingTraits() {
    List<String> traits = _generateCharmingTraits();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            traits.asMap().entries.map((entry) {
              int index = entry.key;
              String trait = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      child: const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trait,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Color _getAccentColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B), // 빨강
      const Color(0xFF4ECDC4), // 터콰이즈
      const Color(0xFF45B7D1), // 파랑
      const Color(0xFF96CEB4), // 민트
      const Color(0xFFFECE2F), // 노랑
      const Color(0xFFDDA0DD), // 라벤더
    ];
    return colors[index % colors.length];
  }

  String _getPersonalityDescription(String label) {
    switch (label) {
      case '온기':
        return '따뜻함과 친근함을\n표현하는 정도';
      case '능력':
        return '업무나 과제를\n처리하는 능력';
      case '외향성':
        return '사교적이고\n활발한 성향';
      case '창의성':
        return '독창적이고\n새로운 아이디어';
      case '안정성':
        return '안정적이고\n일관성이 있는 정도';
      case '성실성':
        return '책임감과 신뢰성이\n뛰어난 정도';
      default:
        return '성격 특성';
    }
  }

  String _generatePersonalityDescription() {
    // 기본 설명 반환 (summary나 personalityDescription 없이)
    return "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요. 안정적이면서도 적응력이 뛰어나 다양한 환경에서 자신만의 매력을 발휘할 수 있어요.";
  }

  List<String> _generateCoreTraits() {
    // 기본 특성 반환 (coreTraits 없이)
    return [
      "자신만의 독특한 개성을 가지고 있어요",
      "상황에 맞게 유연하게 대응해요",
      "균형 잡힌 관점으로 세상을 바라봐요",
      "소중한 것들을 지키려고 노력해요",
      "자연스러운 매력으로 사람들에게 영향을 줘요",
    ];
  }

  List<String> _generateContradictoryTraits() {
    return widget.contradictions ??
        [
          "겉으로는 차분해 보이지만 속으로는 열정적이에요",
          "논리적으로 생각하지만 가끔 감정에 따라 행동해요",
          "독립적이면서도 다른 사람과의 연결을 소중히 여겨요",
        ];
  }

  List<String> _generateCharmingTraits() {
    return widget.attractiveFlaws ??
        [
          "완벽해 보이려고 노력하지만 가끔 실수를 해요",
          "생각이 너무 많아서 결정을 내리기 어려워해요",
          "너무 솔직해서 가끔 눈치가 없어요",
          "지나치게 열정적이어서 쉬는 것을 잊을 때가 있어요",
        ];
  }

  Widget _buildAttractiveFlaws() {
    List<String> flaws =
        widget.attractiveFlaws ??
        [
          "완벽하지 않기 때문에 더욱 인간적이고 매력적이에요",
          "자신만의 독특한 매력으로 사람들에게 기억에 남아요",
          "겸손하면서도 자신감 있는 균형 잡힌 모습이에요",
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            flaws.asMap().entries.map((entry) {
              int index = entry.key;
              String flaw = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      child: const Text(
                        '•',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        flaw,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  RadarChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 60;
    final sides = values.length;

    _drawGridLines(canvas, center, radius, sides);
    _drawDataArea(canvas, center, radius, sides);
    _drawLabels(canvas, center, radius, sides);
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius, int sides) {
    final gridPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (int i = 1; i <= 5; i++) {
      final currentRadius = (radius / 5) * i;
      canvas.drawCircle(center, currentRadius, gridPaint);
    }

    final axisPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, axisPaint);
    }
  }

  void _drawDataArea(Canvas canvas, Offset center, double radius, int sides) {
    final dataPath = Path();
    final dataPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i - math.pi / 2;
      final value = values[i] / 100;
      final pointRadius = radius * value;

      final point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, borderPaint);

    final pointPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final pointBorderPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;

    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i - math.pi / 2;
      final value = values[i] / 100;
      final pointRadius = radius * value;

      final point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );

      canvas.drawCircle(point, 8, pointBorderPaint);
      canvas.drawCircle(point, 6, pointPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, int sides) {
    for (int i = 0; i < sides; i++) {
      final angle = (2 * math.pi / sides) * i - math.pi / 2;
      final labelRadius = radius + 40;

      final labelPosition = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final offset = Offset(
        labelPosition.dx - textPainter.width / 2,
        labelPosition.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * f).round(),
      (green * f).round(),
      (blue * f).round(),
    );
  }
}
