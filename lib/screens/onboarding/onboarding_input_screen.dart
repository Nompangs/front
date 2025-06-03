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
    _nicknameController.text = '딥찐 말랑이';
    _selectedLocation = '우리집 거실';
    _selectedDuration = '3개월';
    _objectTypeController.text = '이 빨간 머그컵';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9), // 아이보리색 배경
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
      body: SafeArea(
        child: Stack(
          children: [
            // 배경 섹션들
            _buildBackgroundSections(),
            
            // 위에 floating되는 카드들
            _buildFloatingCards(),
            
            // 하단 다음 버튼
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSections() {
    return Column(
      children: [
        // 아이보리색 상단 섹션
        Container(
          height: 200,
          width: double.infinity,
          color: const Color(0xFFFDF7E9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '궁금해!\n나는 어떤 사람이야?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 파란색 중간 섹션
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
        // 보라색 하단 섹션 (테두리와 라운딩 추가)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE1BEE7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Container(), // 내용은 floating 카드가 담당
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCards() {
    return Column(
      children: [
        const SizedBox(height: 180), // 타이틀 아래 위치
        
        // 이름 입력 floating 카드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildNameInputCard(),
        ),
        
        const SizedBox(height: 20),
        
        // 오류 메시지
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _validationError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        const SizedBox(height: 40),
        
        // 입력 폼 floating 카드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildInputFormCard(),
        ),
      ],
    );
  }

  Widget _buildNameInputCard() {
    return GestureDetector(
      onTap: () => _showNicknameDialog(),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '애칭',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    _nicknameController.text.isNotEmpty 
                        ? _nicknameController.text 
                        : '딥찐 말랑이', // 회색 미리보기
                    style: TextStyle(
                      color: _nicknameController.text.isNotEmpty 
                          ? Colors.black 
                          : Colors.grey, // 건너뛰기와 동일한 색상
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 20,
              child: Text(
                '이름을 입력해주세요', // 변경된 텍스트
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            // 위치 드롭다운
            _buildDropdownRow(
              _selectedLocation, 
              _locationOptions, 
              '에서', 
              '우리집 거실', // 미리보기 텍스트
              (value) {
                setState(() {
                  _selectedLocation = value;
                });
              }
            ),
            
            const SizedBox(height: 20),
            
            // 기간 드롭다운
            _buildDropdownRow(
              _selectedDuration, 
              _durationOptions, 
              '정도 함께한', 
              '3개월', // 미리보기 텍스트
              (value) {
                setState(() {
                  _selectedDuration = value;
                });
              }
            ),
            
            const SizedBox(height: 20),
            
            // 사물 입력
            _buildTextInputRow(_objectTypeController, '(이)에요.', '이 빨간 머그컵'),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String? selectedValue, List<String> options, String suffix, String preview, Function(String?) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    preview,
                    style: const TextStyle(
                      color: Colors.grey, // 건너뛰기와 동일한 색상
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black, // 선택 후 검은색
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: options.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(value),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          suffix,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputRow(TextEditingController controller, String suffix, String preview) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.black, // 입력 후 검은색
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintText: preview,
                hintStyle: const TextStyle(
                  color: Colors.grey, // 건너뛰기와 동일한 색상
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          suffix,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: _buildNextButton(),
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _proceedToNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          '다음',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('애칭 설정'),
        content: TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(
            hintText: '애칭을 입력해주세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // 버튼 텍스트 업데이트
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
} 