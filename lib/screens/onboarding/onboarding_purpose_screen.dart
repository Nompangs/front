import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

/// 온보딩 용도 설정 화면
/// 첨부 이미지 디자인과 onboarding_input_screen.dart 규정을 따라 새롭게 구현
class OnboardingPurposeScreen extends StatefulWidget {
  const OnboardingPurposeScreen({super.key});

  @override
  State<OnboardingPurposeScreen> createState() =>
      _OnboardingPurposeScreenState();
}

class _OnboardingPurposeScreenState extends State<OnboardingPurposeScreen> {
  final TextEditingController _purposeController = TextEditingController();
  String? _selectedHumorStyle;
  String? _validationError;

  // 사용자가 실제로 입력했는지 추적하는 변수들
  bool _hasPurposeInput = false;
  bool _hasHumorStyleInput = false;

  // 검증 시도 여부 - 다음 버튼을 눌렀을 때만 경고문 표시
  bool _showValidationErrors = false;

  // 유머 스타일 옵션
  final List<String> _humorStyles = [
    "따뜻한",
    "날카로운 관찰자적",
    "위트있는",
    "자기비하적",
    "유쾌한",
  ];

  @override
  void initState() {
    super.initState();
    // 기본값 설정하지 않음 - 처음엔 모두 회색으로 표시
    // 사용자가 입력하면 그때 검은색으로 변경
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  /// 입력 검증
  bool _validateInputs() {
    setState(() {
      _validationError = null;
      _showValidationErrors = true; // 검증 시도했음을 표시
    });

    // 용도 검증 - 반드시 사용자가 입력해야 함
    if (!_hasPurposeInput || _purposeController.text.trim().isEmpty) {
      setState(() {
        _validationError = '구체적인 역할을 입력해주세요!';
      });
      return false;
    }

    // 유머 스타일 검증 - 반드시 사용자가 선택해야 함
    if (!_hasHumorStyleInput || _selectedHumorStyle == null) {
      setState(() {
        _validationError = '유머 스타일을 선택해주세요!';
      });
      return false;
    }

    return true;
  }

  /// 다음 단계로 이동
  void _proceedToNext() {
    if (_validateInputs()) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updatePurpose(_purposeController.text.trim());
      provider.updateHumorStyle(_selectedHumorStyle!);

      Navigator.pushNamed(context, '/onboarding/photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 플로팅 버튼 위치 계산 (기존 하단 패딩 비율 유지)
    final buttonBottomPosition =
        MediaQuery.of(context).padding.bottom +
        (screenHeight * 0.06); // 화면 높이의 6%

    // 가용 높이 계산 (앱바, 버튼 영역 제외)
    final availableHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        56 // 앱바 높이
        -
        buttonBottomPosition -
        56 // 버튼 높이
        -
        16; // 버튼 여백

    // 기존 비율 유지한 섹션 높이 계산
    final ivoryHeight = 64; // 고정 높이 (32px 상하 패딩)
    final greenHeight = (availableHeight * 0.35).clamp(250.0, 300.0); // 35%
    final pinkHeight = (availableHeight * 0.30).clamp(200.0, 280.0); // 30%

    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final objectName = provider.state.nickname.isNotEmpty ? provider.state.nickname : "털찐 말랑이";

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFFFDF7E9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/home'),
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
          body: Stack(
            children: [
              Column(
                children: [
                  // 아이보리 섹션 (제목)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFDF7E9),
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.1,
                      32,
                      screenWidth * 0.05,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 하얀색 플레이스홀더로 사용자 이름 감싸기
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 0,
                                ),
                              ),
                              child: Text(
                                objectName,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '라니..! 😂',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '너에게 나는 어떤 존재야?',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 초록색 섹션 (말풍선)
                  Expanded(
                    flex: 7,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3FCB80),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 120,
                                  maxHeight: 180,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 0,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '용도',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showPurposeDialog(),
                                          child: SingleChildScrollView(
                                            child: Text(
                                              _purposeController.text.isNotEmpty
                                                  ? _purposeController.text
                                                  : '구체적인 역할을 입력해주세요.\n예: 운동 루틴 관리, 일정 알림, 감정 상담 등\n어떤 도움이 필요한지 자세히 적어주세요.',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                color:
                                                    _hasPurposeInput &&
                                                            _purposeController
                                                                .text
                                                                .isNotEmpty
                                                        ? Colors.black87
                                                        : Colors.grey.shade500,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '200자 내외로 상세히 입력해주세요',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    color: Colors.red.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (_showValidationErrors &&
                                  (!_hasPurposeInput ||
                                      _purposeController.text.isEmpty))
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '구체적인 역할을 입력해주세요',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      color: Colors.red.shade400,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 분홍색 섹션 (유머 스타일)
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD8F1),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildHumorStyleCard(),
                              const SizedBox(height: 8),
                              if (_showValidationErrors &&
                                  (!_hasHumorStyleInput ||
                                      _selectedHumorStyle == null))
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '유머 스타일을 선택해주세요!',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      color: Colors.red.shade400,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 섹션과 버튼 사이 간격
                  Container(height: 15, color: Colors.transparent),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 24 + 56,
                  ),
                ],
              ),
              // 플로팅 다음 버튼
              Positioned(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: _buildNextButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: ElevatedButton(
        onPressed: _proceedToNext,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 커스텀 유머 스타일 드롭다운
  void _showHumorStyleDropdown(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000),
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            Positioned(
              left: 40,
              right: 40,
              top: position.dy + 200,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        _humorStyles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = _selectedHumorStyle == option;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedHumorStyle = option;
                                _hasHumorStyleInput = true;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFFDAB7FA)
                                        : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft:
                                      index == 0
                                          ? const Radius.circular(10)
                                          : Radius.zero,
                                  topRight:
                                      index == 0
                                          ? const Radius.circular(10)
                                          : Radius.zero,
                                  bottomLeft:
                                      index == _humorStyles.length - 1
                                          ? const Radius.circular(10)
                                          : Radius.zero,
                                  bottomRight:
                                      index == _humorStyles.length - 1
                                          ? const Radius.circular(10)
                                          : Radius.zero,
                                ),
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 용도 입력 다이얼로그
  void _showPurposeDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000),
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(40),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(25)),
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '구체적인 역할 설정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 100, // 56 → 100으로 변경 (약 1.8배)
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: TextField(
                      controller: _purposeController,
                      maxLines: 4,
                      maxLength: 300,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '구체적인 역할을 입력해주세요\n예: 운동을 까먹지 않게 채찍질해주는 조교',
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        isDense: true,
                        counterText: '', // 글자 수 카운터 숨김
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  topRight: Radius.zero,
                                  bottomRight: Radius.zero,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _hasPurposeInput = true; // 사용자가 입력했음을 표시
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDAB7FA).withOpacity(0.7),
                                border: Border.all(
                                  color: const Color(
                                    0xFFDAB7FA,
                                  ).withOpacity(0.7),
                                  width: 1,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.zero,
                                  bottomLeft: Radius.zero,
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '확인',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHumorStyleCard() {
    return Row(
      children: [
        // 드롭다운 선택값 (왼쪽)
        Expanded(
          child: GestureDetector(
            onTap: () => _showHumorStyleDropdown(context),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.transparent, width: 0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedHumorStyle ?? '위트있는',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color:
                            _hasHumorStyleInput && _selectedHumorStyle != null
                                ? Colors.black
                                : Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 오른쪽 라벨
        Text(
          '유머스타일',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
