import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';

/// 온보딩 사물 정보 입력 화면
class OnboardingInputScreen extends StatefulWidget {
  const OnboardingInputScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingInputScreen> createState() => _OnboardingInputScreenState();
}

class _OnboardingInputScreenState extends State<OnboardingInputScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _objectTypeController = TextEditingController();

  String? _selectedLocation;
  String? _selectedDuration;
  String? _validationError;

  // 사용자가 실제로 입력했는지 추적하는 변수들
  bool _hasNicknameInput = false;
  bool _hasObjectTypeInput = false;

  // 검증 시도 여부 - 다음 버튼을 눌렀을 때만 경고문 표시
  bool _showValidationErrors = false;

  // 위치 옵션 (캡처 이미지 기준)
  final List<String> _locationOptions = [
    '내 방',
    '우리집 안방',
    '우리집 거실',
    '사무실',
    '단골 카페',
  ];

  // 기간 옵션
  final List<String> _durationOptions = [
    '1개월',
    '3개월',
    '6개월',
    '1년',
    '2년',
    '3년 이상',
  ];

  @override
  void initState() {
    super.initState();
    // 기본값 설정하지 않음 - 처음엔 모두 회색으로 표시
    // 사용자가 입력하면 그때 검은색으로 변경
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _objectTypeController.dispose();
    super.dispose();
  }

  /// 입력 검증
  bool _validateInputs() {
    setState(() {
      _validationError = null;
      _showValidationErrors = true; // 검증 시도했음을 표시
    });

    // 닉네임 검증 - 실제 입력이 있거나 기본값 사용 (선택사항)
    final nickname =
        _hasNicknameInput && _nicknameController.text.isNotEmpty
            ? _nicknameController.text.trim()
            : '털찐 말랑이';

    if (nickname.isEmpty) {
      setState(() {
        _validationError = '이름을 입력해주세요!';
      });
      return false;
    }

    if (_selectedLocation == null) {
      setState(() {
        _validationError = '위치를 선택해주세요!';
      });
      return false;
    }

    if (_selectedDuration == null) {
      setState(() {
        _validationError = '함께한 기간을 선택해주세요!';
      });
      return false;
    }

    // 사물 종류 검증 - 반드시 사용자가 입력해야 함
    if (!_hasObjectTypeInput || _objectTypeController.text.trim().isEmpty) {
      setState(() {
        _validationError = '사물의 종류를 입력해주세요!';
      });
      return false;
    }

    return true;
  }

  /// 다음 단계로 이동
  void _proceedToNext() {
    if (_validateInputs()) {
      // 실제 입력값 또는 기본값 사용 (닉네임만 기본값 허용)
      final nickname =
          _hasNicknameInput && _nicknameController.text.isNotEmpty
              ? _nicknameController.text.trim()
              : '털찐 말랑이';

      // 사물 종류는 반드시 사용자 입력값 사용
      final objectType = _objectTypeController.text.trim();

      final userInput = UserInput(
        nickname: nickname,
        location: _selectedLocation!,
        duration: _selectedDuration!,
        objectType: objectType,
      );

      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.setUserInput(userInput);

      Navigator.pushNamed(context, '/onboarding/purpose');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따른 반응형 높이 계산
    final blueHeight = screenHeight * 0.16; // 화면 높이의 16% (최소 120, 최대 150)
    final pinkHeight = screenHeight * 0.35; // 화면 높이의 35% (최소 280, 최대 320)

    return Scaffold(
      backgroundColor: Colors.white, // 기본 배경을 흰색으로 설정
      resizeToAvoidBottomInset: true, // 키보드 오버플로우 방지
      // 일반적인 AppBar 사용
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E9),
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
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        // 스크롤 가능하도록 수정
        child: Column(
          children: [
            // 아이보리 섹션 (100% 폭) - Material 3 여백 최적화
            Container(
              width: double.infinity,
              color: const Color(0xFFFDF7E9),
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.1,
                32,
                screenWidth * 0.05,
                32,
              ), // 상하 패딩 증가 (24 → 32)
              child: Text(
                '궁금해!\n나는 어떤 사물이야?',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: screenWidth * 0.06, // 폰트 크기 줄임 (0.07 → 0.06)
                  fontWeight: FontWeight.w600, // Material 3 표준 (bold → w600)
                  color: Colors.black,
                  height: 1.5, // 줄 간격 넓게 (1.3 → 1.5)
                ),
              ),
            ),

            // 하늘색 섹션 (100% 폭) - 반응형 높이
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: blueHeight.clamp(120.0, 150.0), // 최소 120, 최대 150
                  decoration: BoxDecoration(
                    color: const Color(0xFF57B3E6), // 단색으로 변경
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
                ),

                // 이름 입력 floating 카드
                Positioned(
                  top:
                      (blueHeight.clamp(120.0, 150.0) - 56) / 2 -
                      10, // 중앙 배치 (카드 높이 56 고려)
                  left: screenWidth * 0.1, // 반응형 좌우 여백
                  right: screenWidth * 0.1,
                  child: Column(
                    children: [
                      _buildNameInputCard(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _showValidationErrors &&
                                  (!_hasNicknameInput ||
                                      _nicknameController.text.isEmpty)
                              ? '이름을 입력해주세요'
                              : '',
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
              ],
            ),

            // 분홍색 섹션 (100% 폭 + 테두리 겹치기) - 반응형 높이
            Transform.translate(
              offset: const Offset(0, -1), // 테두리 겹치기
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: pinkHeight.clamp(
                      320.0,
                      380.0,
                    ), // 400→320, 460→380으로 줄임 (상하 균일하게)
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD8F1), // 색상 변경
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
                  ),

                  // 입력 폼 floating 카드 - 상하 중앙 배치
                  Positioned(
                    top: 48, // 56→48로 조정 (상하 여백 균일하게)
                    left: screenWidth * 0.1, // 반응형 좌우 여백
                    right: screenWidth * 0.1,
                    child: _buildInputFormCard(),
                  ),
                ],
              ),
            ),

            // 오류 메시지
            if (_validationError != null)
              Container(
                width: double.infinity,
                color: Colors.white, // 아이보리에서 흰색으로 변경
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ), // 16은 8배수로 유지
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.red,
                    fontSize: 14, // Material 3 Body Small
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 하단 흰색 배경 - Material 3 최적화
            Container(
              width: double.infinity,
              color: Colors.white, // Color(0xFFFDF7E9)에서 Colors.white로 변경
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                24,
                screenWidth * 0.06,
                48,
              ), // 반응형 패딩
              child: _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputCard() {
    return GestureDetector(
      onTap: () => _showNicknameDialog(),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.transparent, width: 0),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              '애칭',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _hasNicknameInput && _nicknameController.text.isNotEmpty
                      ? _nicknameController.text
                      : '털찐 말랑이',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color:
                        _hasNicknameInput && _nicknameController.text.isNotEmpty
                            ? Colors.black
                            : Colors.grey.shade500,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFormCard() {
    return Column(
      children: [
        // 위치 드롭다운
        _buildDropdownRow(_selectedLocation, _locationOptions, '에서', '우리집 거실', (
          value,
        ) {
          setState(() {
            _selectedLocation = value;
          });
        }),

        const SizedBox(height: 8),
        // 기간 드롭다운
        _buildDropdownRow(
          _selectedDuration,
          _durationOptions,
          '정도 함께한',
          '3개월',
          (value) {
            setState(() {
              _selectedDuration = value;
            });
          },
        ),

        const SizedBox(height: 8),
        // 사물 종류 입력
        _buildObjectTypeCard(),
      ],
    );
  }

  Widget _buildObjectTypeCard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showObjectTypeDialog(),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.transparent, width: 0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _hasObjectTypeInput &&
                                _objectTypeController.text.isNotEmpty
                            ? _objectTypeController.text
                            : '이 빠진 머그컵',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          color:
                              _hasObjectTypeInput &&
                                      _objectTypeController.text.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey.shade500,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '(이)에요.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _showValidationErrors &&
                    (!_hasObjectTypeInput || _objectTypeController.text.isEmpty)
                ? '입력해주세요'
                : '',
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: Colors.red.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    String? selectedValue,
    List<String> options,
    String suffix,
    String preview,
    Function(String?) onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    () => _showCustomDropdown(
                      context,
                      options,
                      selectedValue,
                      onChanged,
                      offsetY: options == _locationOptions ? 98 : 124,
                    ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.transparent, width: 0),
                  ),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedValue ?? preview,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              color:
                                  selectedValue != null
                                      ? Colors.black
                                      : Colors.grey.shade500,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
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
            ),
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _showValidationErrors && selectedValue == null ? '선택해주세요' : '',
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: Colors.red.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // 커스텀 드롭다운 표시 (성능 최적화)
  void _showCustomDropdown(
    BuildContext context,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged, {
    double offsetY = 80,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black26, // 미리 정의된 상수 사용
      useSafeArea: false, // 성능 최적화
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            // 배경 터치하면 닫기
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 드롭다운 박스 - 성능 최적화된 버전
            Positioned(
              left: 40,
              right: 40,
              top: MediaQuery.of(context).size.height * 0.3, // 고정 위치로 성능 개선
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
                    children: List.generate(options.length, (index) {
                      final option = options[index];
                      final isSelected = selectedValue == option;

                      return InkWell(
                        // GestureDetector 대신 InkWell 사용 (성능 개선)
                        onTap: () {
                          onChanged(option);
                          Navigator.of(dialogContext).pop();
                        },
                        borderRadius: BorderRadius.only(
                          topLeft:
                              index == 0
                                  ? const Radius.circular(24)
                                  : Radius.zero,
                          topRight:
                              index == 0
                                  ? const Radius.circular(24)
                                  : Radius.zero,
                          bottomLeft:
                              index == options.length - 1
                                  ? const Radius.circular(24)
                                  : Radius.zero,
                          bottomRight:
                              index == options.length - 1
                                  ? const Radius.circular(24)
                                  : Radius.zero,
                        ),
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
                                      ? const Radius.circular(24)
                                      : Radius.zero,
                              topRight:
                                  index == 0
                                      ? const Radius.circular(24)
                                      : Radius.zero,
                              bottomLeft:
                                  index == options.length - 1
                                      ? const Radius.circular(24)
                                      : Radius.zero,
                              bottomRight:
                                  index == options.length - 1
                                      ? const Radius.circular(24)
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
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56, // Material 3 표준 높이로 통일
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // 높이에 맞는 라운딩
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ), // 회색 외곽선으로 변경
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
            fontSize: 16, // Material 3 body large로 통일
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    _showFastDialog(
      context: context,
      title: '애칭 설정',
      controller: _nicknameController,
      hintText: '애칭을 입력해주세요',
      onSave: () {
        setState(() {
          _hasNicknameInput = true;
        });
      },
    );
  }

  void _showObjectTypeDialog() {
    _showFastDialog(
      context: context,
      title: '사물 종류 설정',
      controller: _objectTypeController,
      hintText: '사물의 종류를 입력해주세요',
      onSave: () {
        setState(() {
          _hasObjectTypeInput = true;
        });
      },
    );
  }

  // 즉시 표시되는 빠른 다이얼로그
  void _showFastDialog({
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onSave,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Material(
            color: Colors.black26,
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(40),
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
                      title,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(28),
                        ),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            color: Colors.grey.shade500,
                            fontSize: 18,
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
                        ),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        autofocus: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => overlayEntry.remove(),
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
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              onSave();
                              overlayEntry.remove();
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
  }
}
