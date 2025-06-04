import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';

/// 온보딩 사물 정보 입력 화면
/// Figma 노드: 14:3218, 14:3303, 14:3361 - 온보딩 - 사물 정보 입력
/// 사용자가 애착 사물에 대한 정보를 입력하는 화면
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

  // 위치 옵션 (Figma 기준)
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
      // 입력된 데이터를 UserInput 모델로 생성
      final userInput = UserInput(
        nickname: _nicknameController.text.trim(),
        location: _selectedLocation!,
        duration: _selectedDuration!,
        objectType: _objectTypeController.text.trim(),
      );

      // Provider에 사용자 입력 저장
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.setUserInput(userInput);

      // Step 3: 용도 입력 화면으로 이동 (Figma 6단계 플로우)
      Navigator.pushNamed(context, '/onboarding/purpose');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9), // Figma 배경색
      body: SafeArea(
        child: Column(
          children: [
            // 앱바 영역
            _buildAppBar(context),
            
            // 메인 콘텐츠 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // 메인 타이틀
                    _buildMainTitle(),
                    
                    const SizedBox(height: 40),
                    
                    // 입력 섹션
                    _buildInputSection(),
                    
                    const SizedBox(height: 20),
                    
                    // 검증 에러 메시지
                    if (_validationError != null) _buildValidationError(),
                    
                    const SizedBox(height: 40),
                    
                    // 하단 버튼
                    _buildFooterButton(),
                    
                    const SizedBox(height: 34), // HomeIndicator 공간
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 앱바 위젯
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF333333),
              size: 24,
            ),
          ),
          
          // 타이틀
          const Expanded(
            child: Text(
              '성격 조제 연금술!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // 건너뛰기 버튼
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFFBCBCBC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 메인 타이틀 위젯
  Widget _buildMainTitle() {
    return const Text(
      '말해줘!\n나는 어떤 사물이야?',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 1.5,
        color: Color(0xFF333333),
      ),
    );
  }

  /// 입력 섹션 위젯
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF57B3E6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 애칭 입력
          _buildNicknameInput(),
          
          const SizedBox(height: 16),
          
          // 위치 선택
          _buildLocationSelector(),
          
          const SizedBox(height: 16),
          
          // 기간 선택
          _buildDurationSelector(),
          
          const SizedBox(height: 16),
          
          // 사물 종류 입력
          _buildObjectTypeInput(),
        ],
      ),
    );
  }

  /// 애칭 입력 위젯
  Widget _buildNicknameInput() {
    return Row(
      children: [
        const Text(
          '애칭',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 55,
            child: TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: '털찐 말랑이',
                hintStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 위치 선택 위젯
  Widget _buildLocationSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedLocation,
            hint: const Text(
              '우리집 거실',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFFB0B0B0),
              ),
            ),
            items: _locationOptions.map((location) {
              return DropdownMenuItem(
                value: location,
                child: Text(location),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLocation = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '에서',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 기간 선택 위젯
  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDuration,
            hint: const Text(
              '3개월',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFFB0B0B0),
              ),
            ),
            items: _durationOptions.map((duration) {
              return DropdownMenuItem(
                value: duration,
                child: Text(duration),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDuration = value;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '정도 함께한',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 사물 종류 입력 위젯
  Widget _buildObjectTypeInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 55,
            child: TextField(
              controller: _objectTypeController,
              decoration: InputDecoration(
                hintText: '이 빠진 머그컵',
                hintStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '(이)에요.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 검증 에러 메시지 위젯
  Widget _buildValidationError() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Text(
        _validationError!,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
          color: Color(0xFFFF5252),
        ),
      ),
    );
  }

  /// 하단 버튼 위젯
  Widget _buildFooterButton() {
    return SizedBox(
      width: 343,
      height: 56,
      child: ElevatedButton(
        onPressed: _proceedToNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: const Text(
          '다음',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
} 