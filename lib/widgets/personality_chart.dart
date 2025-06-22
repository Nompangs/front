import 'package:flutter/material.dart';
import 'dart:math' as math;

class PersonalityChart extends StatefulWidget {
  final double warmth;
  final double competence;
  final double extroversion;
  final double creativity;
  final double humour;
  final double reliability;
  final Map<String, dynamic>? realtimeSettings;
  final List<String>? attractiveFlaws;
  final List<String>? contradictions;
  final String? communicationPrompt;
  // 🆕 AI 생성 추가 필드들
  final List<String>? coreTraits;
  final String? personalityDescription;

  const PersonalityChart({
    super.key,
    required this.warmth,
    required this.competence,
    required this.extroversion,
    this.creativity = 50,
    this.humour = 75,
    this.reliability = 50,
    this.realtimeSettings,
    this.attractiveFlaws,
    this.contradictions,
    this.communicationPrompt,
    // 🆕 AI 생성 추가 필드들
    this.coreTraits,
    this.personalityDescription,
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
      widget.humour,
      widget.reliability,
    ];
    final labels = ['온기', '능력', '외향성', '창의성', '유머', '신뢰성'];

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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFA9121),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '차트를 터치해서 수치를 확인해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
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
        // A. 성격 요약
        _buildSectionDivider(),
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '성격 요약',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Text(
            _generatePersonalityDescription(),
            style: const TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
          ),
        ),

        const SizedBox(height: 32),

        // B. 말투 (커뮤니케이션 스타일)
        _buildSectionDivider(),
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '말투 (커뮤니케이션 스타일)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 20),
        _buildCommunicationSection(),

        const SizedBox(height: 32),

        // C. 매력적 특성
        _buildSectionDivider(),
        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            '매력적 특성',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 20),
        _buildAttractiveSection(),

        const SizedBox(height: 32),

        // D. 모순적 특성
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
    // 🔥 최우선: AI가 생성한 모순적 특성 사용
    List<String> traits =
        widget.contradictions?.isNotEmpty == true
            ? widget.contradictions!
            : _generateContradictoryTraits();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            traits.asMap().entries.map((entry) {
              int index = entry.key;
              String trait = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 12, top: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        trait,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black,
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
    // 실제 데이터가 있으면 사용, 없으면 생성된 데이터 사용
    List<String> traits =
        widget.attractiveFlaws?.isNotEmpty == true
            ? widget.attractiveFlaws!
            : _generateCharmingTraits();

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

  Widget _buildVoiceCharacteristics() {
    if (widget.realtimeSettings == null) return const SizedBox.shrink();

    final settings = widget.realtimeSettings!;
    List<String> characteristics = [];

    // 🎵 저장된 realtimeSettings에서 정보 추출
    final voice = settings['voice'] ?? 'alloy';
    final voiceRationale = settings['voiceRationale'] ?? '';
    final emotionalTone = settings['emotionalTone'] ?? '';
    final speechRhythm = settings['speechRhythm'] ?? '';
    final interactionStyle = settings['interactionStyle'] ?? '';
    final pronunciation = settings['pronunciation'] ?? '';

    // 음성 정보가 있으면 추가
    if (voice.isNotEmpty && voiceRationale.isNotEmpty) {
      characteristics.add('🎤 선택된 음성: $voice ($voiceRationale)');
    }

    // 감정 톤 정보가 있으면 추가
    if (emotionalTone.isNotEmpty) {
      characteristics.add('🎭 감정 표현: $emotionalTone');
    }

    // 말하기 리듬 정보가 있으면 추가
    if (speechRhythm.isNotEmpty) {
      characteristics.add('🎵 말하기 리듬: $speechRhythm');
    }

    // 상호작용 스타일 정보가 있으면 추가
    if (interactionStyle.isNotEmpty) {
      characteristics.add('💬 소통 방식: $interactionStyle');
    }

    // 발음 스타일 정보가 있으면 추가
    if (pronunciation.isNotEmpty) {
      characteristics.add('🗣️ 발음 특성: $pronunciation');
    }

    // 정보가 없으면 기본 메시지
    if (characteristics.isEmpty) {
      characteristics.add('음성 특성 정보가 설정되지 않았습니다.');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            characteristics.map((characteristic) {
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
                        characteristic,
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

  Widget _buildCommunicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전반적인 소통 방식 (communicationPrompt)
        if (widget.communicationPrompt?.isNotEmpty == true) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.communicationPrompt!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],

        // 폴백: 정보가 없을 때
        if (widget.communicationPrompt?.isEmpty ?? true) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '말투 정보가 생성되지 않았습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttractiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 매력적 결함 (attractiveFlaws)
        if (widget.attractiveFlaws?.isNotEmpty == true) ...[
          _buildAttractiveFlaws(),
        ],

        // 폴백: 정보가 없을 때
        if (widget.attractiveFlaws?.isEmpty ?? true) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '매력적 특성 정보가 생성되지 않았습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttractiveFlaws() {
    if (widget.attractiveFlaws?.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children:
            widget.attractiveFlaws!.asMap().entries.map((entry) {
              int index = entry.key;
              String flaw = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 12, top: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        flaw,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black,
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
      case '유머':
        return '재치있고\n유머러스한 면';
      case '신뢰성':
        return '믿을 수 있고\n의지할 수 있는 정도';
      default:
        return '성격 특성';
    }
  }

  String _generatePersonalityDescription() {
    // 🔥 최우선: AI가 생성한 성격 설명 사용
    if (widget.personalityDescription?.isNotEmpty == true) {
      return widget.personalityDescription!;
    }

    // 🔥 차선: 소통 스타일 프롬프트 사용
    if (widget.communicationPrompt?.isNotEmpty == true) {
      return widget.communicationPrompt!;
    }

    // 🔥 폴백: 기존 로직 사용
    if (widget.warmth >= 70 && widget.extroversion >= 70) {
      return "따뜻하고 활발한 성격으로, 주변 사람들에게 긍정적인 에너지를 전달해요. 새로운 사람들과도 쉽게 친해지며, 항상 밝은 분위기를 만들어가는 분위기 메이커예요.";
    } else if (widget.warmth >= 70 && widget.extroversion < 40) {
      return "따뜻하지만 조용한 성격으로, 깊이 있는 대화를 좋아해요. 소수의 친구들과 진솔한 관계를 맺는 것을 선호하며, 상대방의 마음을 세심하게 배려해요.";
    } else if (widget.competence >= 70 && widget.warmth < 40) {
      return "능력 있고 체계적인 성격으로, 일을 정확하고 효율적으로 처리해요. 완벽주의적 성향이 있어 높은 품질의 결과물을 만들어내지만, 때로는 융통성이 필요할 수도 있어요.";
    } else if (widget.humour >= 80) {
      return "유머 감각이 뛰어나 주변을 항상 웃게 만들어요. 어떤 상황에서도 재치 있는 말로 분위기를 밝게 만들며, 스트레스가 많은 순간에도 긍정적인 관점을 유지해요.";
    } else if (widget.creativity >= 70) {
      return "창의적이고 독창적인 아이디어를 가진 성격이에요. 기존의 틀에 얽매이지 않고 새로운 방식으로 문제를 해결하며, 예술적 감각도 뛰어나요.";
    } else {
      return "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요. 안정적이면서도 적응력이 뛰어나 다양한 환경에서 자신만의 매력을 발휘할 수 있어요.";
    }
  }

  List<String> _generateCoreTraits() {
    // 🔥 최우선: AI가 생성한 핵심 특성 사용
    if (widget.coreTraits?.isNotEmpty == true) {
      return widget.coreTraits!;
    }

    // 🔥 차선: 기존 로직으로 폴백
    List<String> traits = [];

    if (widget.warmth >= 60) {
      traits.add("따뜻한 온기로 주변을 포근하게 만드는 능력이 뛰어나요");
    }

    if (widget.competence >= 60) {
      traits.add("높은 능력치로 맡은 업무를 완벽하게 처리해내요");
    }

    if (widget.extroversion >= 60) {
      traits.add("외향적 성격으로 사람들과의 소통을 즐겨해요");
    } else {
      traits.add("내향적 성격으로 깊이 있는 사고를 즐겨해요");
    }

    if (widget.creativity >= 60) {
      traits.add("창의적 사고로 새로운 아이디어를 제시해요");
    }

    if (widget.humour >= 60) {
      traits.add("유머 감각으로 어떤 상황도 즐겁게 만들어요");
    }

    while (traits.length < 5) {
      traits.add("균형 잡힌 성격으로 다양한 상황에 잘 적응해요");
    }

    return traits.take(5).toList();
  }

  List<String> _generateContradictoryTraits() {
    List<String> traits = [];

    if (widget.warmth >= 70 && widget.competence <= 40) {
      traits.add("따뜻하지만 때로는 완벽함을 추구하지 않아 아쉬워요");
    }

    if (widget.competence >= 70 && widget.warmth <= 40) {
      traits.add("능력은 뛰어나지만 감정 표현이 서툴 때가 있어요");
    }

    if (widget.extroversion >= 70 && widget.reliability <= 40) {
      traits.add("활발하지만 가끔 약속을 깜빡할 때가 있어요");
    }

    if (widget.creativity >= 70 && widget.reliability >= 70) {
      traits.add("창의적이면서도 신뢰할 수 있어 독특한 매력이 있어요");
    }

    if (traits.isEmpty) {
      traits.addAll([
        "완벽하지 않기 때문에 더욱 인간적이고 매력적이에요",
        "강점과 약점이 공존해서 더욱 복합적인 매력을 가져요",
      ]);
    }

    return traits.take(2).toList();
  }

  List<String> _generateCharmingTraits() {
    List<String> traits = [];

    if (widget.warmth >= 70) {
      traits.add("진심 어린 관심과 배려로 상대방을 편안하게 만들어줘요");
    }

    if (widget.competence >= 70) {
      traits.add("맡은 일은 끝까지 책임지는 믿음직한 모습을 보여줘요");
    }

    if (widget.extroversion >= 70) {
      traits.add("에너지 넘치는 모습으로 주변을 활기차게 만들어요");
    } else if (widget.extroversion < 40) {
      traits.add("조용하지만 깊이 있는 대화로 특별한 순간을 만들어요");
    }

    if (widget.humour >= 80) {
      traits.add("적절한 타이밍의 유머로 어색한 분위기도 금세 풀어버려요");
    }

    if (widget.creativity >= 60) {
      traits.add("예상치 못한 독특한 아이디어로 새로운 재미를 선사해요");
    }

    if (widget.reliability >= 60) {
      traits.add("약속은 꼭 지키고, 비밀도 잘 지켜주는 신뢰할 수 있는 친구예요");
    }

    if (traits.isEmpty) {
      traits.addAll([
        "자신만의 독특한 매력으로 사람들에게 기억에 남아요",
        "상황에 맞게 유연하게 대처하는 지혜로운 모습을 보여줘요",
        "겸손하면서도 자신감 있는 균형 잡힌 성격이에요",
      ]);
    }

    return traits.take(3).toList();
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
