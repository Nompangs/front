import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// 온보딩 사물 정보 입력 화면
class OnboardingInputScreen extends StatefulWidget {
  const OnboardingInputScreen({super.key});

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
    // 닉네임 컨트롤러 리스너 추가
    _nicknameController.addListener(() {
      if (_nicknameController.text.isNotEmpty) {
        setState(() {
          _hasNicknameInput = true;
          // 이름 관련 경고 메시지가 표시된 경우, 이를 지웁니다.
          if (_validationError == '이름을 입력해주세요!') {
            _validationError = null;
          }
        });
      }
    });

    // 사물 종류 컨트롤러 리스너 추가
    _objectTypeController.addListener(() {
      if (_objectTypeController.text.isNotEmpty) {
        setState(() {
          _hasObjectTypeInput = true;
          // 사물 종류 관련 경고 메시지가 표시된 경우, 이를 지웁니다.
          if (_validationError == '사물의 종류를 입력해주세요!') {
            _validationError = null;
          }
        });
      }
    });
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

    // 닉네임 검증 - 반드시 사용자가 입력해야 함
    if (!_hasNicknameInput || _nicknameController.text.trim().isEmpty) {
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
      // 사용자가 실제로 입력한 값들만 사용
      final nickname = _nicknameController.text.trim();
      final objectType = _objectTypeController.text.trim();

      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.updateUserBasicInfo(
        nickname: nickname,
        location: _selectedLocation!,
        duration: _selectedDuration!,
        objectType: objectType,
      );

      Navigator.pushNamed(context, '/onboarding/purpose');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFDF7E9),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false, // 키보드가 올라와도 화면 크기가 조정되지 않도록 설정
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: SafeArea(
            child: Container(
              height: 60,
              color: const Color(0xFFFDF7E9),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: () => _showSkipConfirmationDialog(context),
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // 메인 레이아웃 (intro_screen과 동일한 구조)
            Column(
              children: [
                // 아이보리 섹션 (고정 높이 -> 유연 높이)
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFFDF7E9),
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.16,
                      40,
                      screenWidth * 0.05,
                      14,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                      mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
                      children: [
                        Text(
                          '궁금해!\n나는 어떤 사물이야?',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 파란 섹션 (고정 높이 -> 유연 높이)
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.none, // 카드가 밖으로 나가도 보이게
                    decoration: BoxDecoration(
                      color: const Color(0xFF57B3E6),
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    // 파란 섹션의 콘텐츠를 중앙에 배치
                    child: Center(
                      child: SizedBox(
                        width: screenWidth * 0.7,
                        child: _buildNameInputCard(),
                      ),
                    ),
                  ),
                ),

                // 분홍 섹션 (Expanded로 남은 공간 활용)
                Expanded(
                  flex: 12,
                  child: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD8F1),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.fromLTRB(55, 20, 95, 20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30), // 여백 추가하여 아래로 내림
                            // 위치 선택
                            _buildDropdownRow(
                              _selectedLocation,
                              _locationOptions,
                              '에서',
                              '우리집 거실',
                              (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                            ),

                            const SizedBox(height: 16),
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

                            const SizedBox(height: 16),
                            // 사물 종류 입력
                            _buildObjectTypeCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 투명한 스페이서 박스 (아이보리와 버튼 사이 간격 유지)
                Container(height: 20, color: Colors.transparent),

                // 하단 흰색 여백 (버튼 공간 확보)
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 30 + 56,
                ),
              ],
            ),

            // 플로팅 다음 버튼 (intro_screen과 동일한 위치)
            Positioned(
              left: screenWidth * 0.06,
              right: screenWidth * 0.06,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: ElevatedButton(
                  onPressed: _proceedToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
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
              ),
            ),
            // 경고 메시지를 최상위 레이어에 고정 위치로 표시
            if (_validationError != null)
              Positioned(
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    94, // 버튼(60) + 여백(24) + 추가 여백(10)
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400, // 배경색을 다른 경고색과 통일
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          color: Colors.white, // 텍스트 색상 변경
                          fontSize: 14,
                          fontWeight: FontWeight.w400, // 굵기 변경
                        ),
                      ),
                    ),
                  ),
                ),
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
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.transparent, width: 0),
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
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

        const SizedBox(height: 12),
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

        const SizedBox(height: 12),
        // 사물 종류 입력
        _buildObjectTypeCard(),

        // 오류 메시지 (입력 필드들과 함께 움직임)
        if (_validationError != null) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                _validationError!,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
                    padding: const EdgeInsets.only(left: 24, right: 16),
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
                          fontWeight: FontWeight.w600,
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
                      padding: const EdgeInsets.only(left: 24, right: 16),
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
                              fontWeight: FontWeight.w600,
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
              left: 80,
              right: 80,
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

  /// 건너뛰기 확인 및 기본값 설정 다이얼로그
  void _showSkipConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('건너뛰기'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('아래 기본값으로 설정하고 다음으로 이동합니다.\n'),
              Text('이름: 내 소중한 친구'),
              Text('위치: 내 방'),
              Text('함께한 기간: 1년'),
              Text('종류: 인형'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                final provider = Provider.of<OnboardingProvider>(
                  context,
                  listen: false,
                );
                provider.updateUserBasicInfo(
                  nickname: "내 소중한 친구",
                  location: "내 방",
                  duration: "1년",
                  objectType: "인형",
                );
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
                Navigator.pushNamed(context, '/onboarding/photo');
              },
            ),
          ],
        );
      },
    );
  }

  /// 공용 드롭다운 위젯 빌더
  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          hint,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w400, // 기본 두께
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        items:
            items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w400, // 드롭다운 목록 항목 두께
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return items.map((item) {
            return Center(
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // 선택된 항목 두께
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList();
        },
        buttonStyleData: ButtonStyleData(
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 48, // 메뉴 아이템 높이
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 공통 텍스트 필드 위젯 빌더
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required bool showError,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 16,
        fontWeight: FontWeight.w400, // 입력된 텍스트는 보통 굵기
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w100,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              showError
                  ? const BorderSide(color: Colors.red, width: 1)
                  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              showError
                  ? const BorderSide(color: Colors.red, width: 1)
                  : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        constraints: const BoxConstraints(
          maxHeight: 56, // 높이 증가
          minHeight: 56,
        ),
      ),
    );
  }
}
