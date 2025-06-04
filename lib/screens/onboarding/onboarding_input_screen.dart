import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';

/// 온보딩 사물 정보 입력 화면
/// 캡처된 이미지 디자인을 참조하여 새롭게 구현
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
    // 기본값 설정 (캡처 이미지 기준)
    _nicknameController.text = '털찐 말랑이';
    _selectedLocation = '우리집 거실';
    _selectedDuration = '3개월';
    _objectTypeController.text = '이 빠진 머그컵';
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
    });

    if (_nicknameController.text.trim().isEmpty) {
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

    if (_objectTypeController.text.trim().isEmpty) {
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
      final userInput = UserInput(
        nickname: _nicknameController.text.trim(),
        location: _selectedLocation!,
        duration: _selectedDuration!,
        objectType: _objectTypeController.text.trim(),
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
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // 스크롤 가능하도록 수정
        child: Column(
          children: [
            // 아이보리 섹션 (100% 폭) - Material 3 여백 최적화
            Container(
              width: double.infinity,
              color: const Color(0xFFFDF7E9),
              padding: EdgeInsets.fromLTRB(screenWidth * 0.1, 32, screenWidth * 0.05, 32), // 상하 패딩 증가 (24 → 32)
              child: Text(
                '궁금해!\n나는 어떤 사물이야?',
                style: TextStyle(
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
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
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
                  top: (blueHeight.clamp(120.0, 150.0) - 56) / 2 - 10, // 중앙 배치 (카드 높이 56 고려)
                  left: screenWidth * 0.1, // 반응형 좌우 여백
                  right: screenWidth * 0.1,
                  child: Column(
                    children: [
                      _buildNameInputCard(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '이름을 입력해주세요',
                          style: TextStyle(
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
                    height: pinkHeight.clamp(320.0, 380.0), // 400→320, 460→380으로 줄임 (상하 균일하게)
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD8F1), // 색상 변경
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
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
                color: const Color(0xFFFDF7E9),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // 16은 8배수로 유지
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14, // Material 3 Body Small
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // 하단 아이보리 배경 - Material 3 최적화
            Container(
              width: double.infinity,
              color: const Color(0xFFFDF7E9),
              padding: EdgeInsets.fromLTRB(screenWidth * 0.06, 24, screenWidth * 0.06, 48), // 반응형 패딩
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
        height: 56, // 다음 버튼과 동일한 높이
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 다음 버튼과 동일한 라운딩
          border: Border.all(color: Colors.transparent, width: 0), // 테두리 제거
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              '애칭',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14, // 16 → 14로 축소 (애칭 레이블 작게)
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Center( // 중앙정렬
                child: Text(
                  _nicknameController.text.isNotEmpty 
                      ? _nicknameController.text 
                      : '', // 애칭란은 비워둠
                  style: TextStyle(
                    color: _nicknameController.text.isNotEmpty 
                        ? Colors.black 
                        : Colors.grey, // 건너뛰기와 같은 색상
                    fontSize: 20, // 14 → 20으로 복원 (예시 텍스트 크기 원래대로)
                    fontWeight: FontWeight.w600, // 더 굵게
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
        _buildDropdownRow(
          _selectedLocation, 
          _locationOptions, 
          '에서', 
          '우리집 거실',
          (value) {
            setState(() {
              _selectedLocation = value;
            });
          }
        ),
        
        const SizedBox(height: 8), // 4 → 8 (8배수 간격)
        
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
          }
        ),
        
        const SizedBox(height: 8), // 4 → 8 (8배수 간격)
        
        // 사물 종류 입력 (애칭과 같은 형태로 변경)
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
                  height: 56, // 다음 버튼과 동일한 높이
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28), // 다음 버튼과 동일한 라운딩
                    border: Border.all(color: Colors.transparent, width: 0), // 테두리 제거
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _objectTypeController.text.isNotEmpty 
                            ? _objectTypeController.text 
                            : '이 빠진 머그컵', // 미리보기 텍스트
                        style: TextStyle(
                          color: _objectTypeController.text.isNotEmpty 
                              ? Colors.grey  // Colors.black → Colors.grey로 변경
                              : Colors.grey, // 건너뛰기와 같은 색상
                          fontSize: 18, // Material 3 Body Large+ (16 → 18)
                          fontWeight: FontWeight.w500, // 약간 더 굵게
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8), // 12 → 8 (8배수 간격)
            Text(
              '(이)에요.',
              style: const TextStyle(
                fontSize: 16, // Material 3 Body Large
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // 8배수 간격
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _objectTypeController.text.isEmpty ? '입력해주세요' : '',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 10, // Material 3 Caption
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(String? selectedValue, List<String> options, String suffix, String preview, Function(String?) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showCustomDropdown(context, options, selectedValue, onChanged, offsetY: options == _locationOptions ? 98 : 124),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.transparent, width: 0), // 테두리 제거
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
                              color: selectedValue != null ? Colors.black : Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24),
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
            selectedValue == null ? '선택해주세요' : '',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // 커스텀 드롭다운 표시 (오버레이 방식) - 개별 설정 가능
  void _showCustomDropdown(BuildContext context, List<String> options, String? selectedValue, Function(String?) onChanged, {double offsetY = 80}) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // 배경 흐리게
      builder: (BuildContext context) {
        return Stack(
          children: [
            // 배경 터치하면 닫기
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
            // 드롭다운 박스 - 개별 오프셋 적용
            Positioned(
              left: 40,
              right: 40,
              top: position.dy + offsetY, // 개별 오프셋 적용
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.black, width: 1), // 검은색 테두리 1px
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = selectedValue == option;
                      
                      return GestureDetector(
                        onTap: () {
                          onChanged(option);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFDAB7FA) : Colors.white, // 선택된 항목 #DAB7FA
                            borderRadius: BorderRadius.only(
                              topLeft: index == 0 ? const Radius.circular(10) : Radius.zero,
                              topRight: index == 0 ? const Radius.circular(10) : Radius.zero,
                              bottomLeft: index == options.length - 1 ? const Radius.circular(10) : Radius.zero,
                              bottomRight: index == options.length - 1 ? const Radius.circular(10) : Radius.zero,
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
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

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56, // Material 3 표준 높이로 통일
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // 높이에 맞는 라운딩
        border: Border.all(color: Colors.grey.shade400, width: 1), // 회색 외곽선으로 변경
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
            color: Colors.black,
            fontSize: 16, // Material 3 body large로 통일
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000), // Colors.black.withOpacity(0.3) → const로 최적화
      barrierDismissible: true, // 성능 개선
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(40), // 기본값 명시로 최적화
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(25)), // const로 최적화
            border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 1)), // const로 최적화
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '애칭 설정',
                style: TextStyle(
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
                  borderRadius: const BorderRadius.all(Radius.circular(28)), // const로 최적화
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: _nicknameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '애칭을 입력해주세요',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    border: const OutlineInputBorder( // const로 최적화
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    isDense: true,
                  ),
                  style: const TextStyle( // const로 최적화
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: const BorderRadius.only( // const로 최적화
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
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAB7FA).withOpacity(0.7),
                            border: Border.all(color: const Color(0xFFDAB7FA).withOpacity(0.7), width: 1),
                            borderRadius: const BorderRadius.only( // const로 최적화
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

  // 사물 종류 입력 다이얼로그
  void _showObjectTypeDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000), // Colors.black.withOpacity(0.3) → const로 최적화
      barrierDismissible: true, // 성능 개선
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(40), // 기본값 명시로 최적화
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(25)), // const로 최적화
            border: Border.fromBorderSide(BorderSide(color: Colors.black, width: 1)), // const로 최적화
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '사물 종류 설정',
                style: TextStyle(
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
                  borderRadius: const BorderRadius.all(Radius.circular(28)), // const로 최적화
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: TextField(
                  controller: _objectTypeController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '사물의 종류를 입력해주세요',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    border: const OutlineInputBorder( // const로 최적화
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    isDense: true,
                  ),
                  style: const TextStyle( // const로 최적화
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: const BorderRadius.only( // const로 최적화
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
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDAB7FA).withOpacity(0.7),
                            border: Border.all(color: const Color(0xFFDAB7FA).withOpacity(0.7), width: 1),
                            borderRadius: const BorderRadius.only( // const로 최적화
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
} 