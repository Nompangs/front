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
              padding: const EdgeInsets.fromLTRB(40, 32, 20, 32), // Material 3 표준 32dp
              child: const Text(
                '궁금해!\n나는 어떤 사람이야?',
                style: TextStyle(
                  fontSize: 28, // Material 3 Headline Medium
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),
            
            // 하늘색 섹션 (100% 폭) - 최적화된 높이
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 144, // Material 3 기준 최적화 (150 → 144)
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                  top: 44, // 중앙 배치 최적화
                  left: 40,
                  right: 40,
                  child: Column(
                    children: [
                      _buildNameInputCard(),
                      const SizedBox(height: 4),
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
            
            // 분홍색 섹션 (100% 폭 + 테두리 겹치기) - 최적화된 높이
            Transform.translate(
              offset: const Offset(0, -1), // 테두리 겹치기
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 310, // 입력 필드 개수에 맞춰 최적화
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1BEE7),
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
                  
                  // 입력 폼 floating 카드
                  Positioned(
                    top: 48, // Material 3 기준 최적화
                    left: 40,
                    right: 40,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Material 3 표준
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), // Material 3 표준
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
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              '애칭',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
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
                    fontSize: 20, // 텍스트 크기 증가 (16 → 20)
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
        
        const SizedBox(height: 8), // 12 → 8로 더 좁게 (Material 3 최소 간격)
        
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
        
        const SizedBox(height: 8), // 12 → 8로 더 좁게 (Material 3 최소 간격)
        
        // 사물 종류 입력 (애칭과 같은 형태로 변경)
        _buildObjectTypeCard(),
      ],
    );
  }

  Widget _buildDropdownRow(String? selectedValue, List<String> options, String suffix, String preview, Function(String?) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28), // 다음 버튼과 동일한 라운딩
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Container(
                  height: 56, // 다음 버튼과 동일한 높이
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28), // 다음 버튼과 동일한 라운딩
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 24),
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          preview,
                          style: const TextStyle(
                            color: Colors.grey, // 건너뛰기와 같은 색상
                            fontSize: 18, // Material 3 Body Large+ (16 → 18)
                            fontWeight: FontWeight.w500, // 약간 더 굵게
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18, // Material 3 Body Large+ (16 → 18)
                        fontWeight: FontWeight.w500, // 약간 더 굵게
                      ),
                      items: options.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 16, // Material 3 Body Large
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4), // 작은 간격
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            selectedValue == null ? '선택해주세요' : '',
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
                    border: Border.all(color: Colors.grey.shade300, width: 1), // 다른 필드와 동일한 테두리
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        '종류',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16, // Material 3 Body Large
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _objectTypeController.text.isNotEmpty 
                              ? _objectTypeController.text 
                              : '이 빨간 머그컵', // 미리보기 텍스트
                          style: TextStyle(
                            color: _objectTypeController.text.isNotEmpty 
                                ? Colors.black 
                                : Colors.grey, // 건너뛰기와 같은 색상
                            fontSize: 18, // Material 3 Body Large+ (16 → 18)
                            fontWeight: FontWeight.w500, // 약간 더 굵게
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
        const SizedBox(height: 4), // 작은 간격
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

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56, // Material 3 표준 높이로 통일
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // 높이에 맞는 라운딩
        border: Border.all(color: Colors.grey.shade300, width: 1), // 다른 입력 필드와 통일
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Material 3 그림자로 통일
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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

  // 사물 종류 입력 다이얼로그
  void _showObjectTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사물 종류 설정'),
        content: TextField(
          controller: _objectTypeController,
          decoration: const InputDecoration(
            hintText: '사물의 종류를 입력해주세요',
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
              setState(() {}); // 텍스트 업데이트
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
} 