import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class OnboardingPurposeScreen extends StatefulWidget {
  const OnboardingPurposeScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingPurposeScreen> createState() => _OnboardingPurposeScreenState();
}

class _OnboardingPurposeScreenState extends State<OnboardingPurposeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _purposeController = TextEditingController();
  String _selectedHumorStyle = "";
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleAnimation;

  // 유머 스타일 옵션 (Figma 문서 기준)
  final List<String> _humorStyles = [
    "따뜻한",
    "날카로운 관찰자적", 
    "위트있는",
    "자기비하적",
    "유쾌한"
  ];

  @override
  void initState() {
    super.initState();
    
    _bubbleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bubbleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _bubbleAnimationController.forward();
    
    // 기본값 설정 (Figma 예시)
    _selectedHumorStyle = "위트있는";
    _purposeController.text = "내가 운동 까먹지 않게 인정사정없이 채찍질해줘. 착하게 굴지마. 너는 조교야.";
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    final provider = context.read<OnboardingProvider>();
    
    if (_purposeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("용도를 입력해주세요")),
      );
      return;
    }
    
    if (_selectedHumorStyle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("유머 스타일을 선택해주세요")),
      );
      return;
    }

    // Step 3 데이터 저장
    provider.updatePurpose(_purposeController.text.trim());
    provider.updateHumorStyle(_selectedHumorStyle);
    
    // Step 4로 이동
    Navigator.pushNamed(context, '/onboarding/photo');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final userInput = provider.state.userInput;
        final objectName = userInput?.nickname ?? "사물";
        
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                child: const Text(
                  "건너뛰기",
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 메인 타이틀 (Figma: Step 3)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: objectName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const TextSpan(
                          text: " 라니..! 😂",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "너에게 나는 어떤 존재야?",
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 캐릭터 말풍선 (초록색 버블 - 실시간 업데이트)
                  AnimatedBuilder(
                    animation: _bubbleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bubbleAnimation.value,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _purposeController.text.isNotEmpty 
                                ? _purposeController.text 
                                : "여기에 당신의 역할이 표시됩니다...",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 스크롤 가능한 입력 영역
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 용도 입력 (자유 텍스트)
                          const Text(
                            "구체적인 역할을 알려주세요",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: TextField(
                              controller: _purposeController,
                              maxLines: 3,
                              maxLength: 300,
                              onChanged: (value) {
                                setState(() {}); // 실시간 말풍선 업데이트
                              },
                              decoration: const InputDecoration(
                                hintText: "예: 운동을 까먹지 않게 채찍질해주는 조교\n내 일정을 관리해주는 비서",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                counterText: "",
                                hintStyle: TextStyle(fontSize: 14),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_purposeController.text.length}/300",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // 유머 스타일 선택
                          const Text(
                            "유머 스타일",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedHumorStyle.isNotEmpty ? _selectedHumorStyle : null,
                              decoration: const InputDecoration(
                                hintText: "유머 스타일을 선택해주세요",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(16),
                              ),
                              items: _humorStyles.map((style) {
                                return DropdownMenuItem(
                                  value: style,
                                  child: Text("$style 유머 스타일"),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedHumorStyle = value ?? "";
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  // 다음 버튼
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: "다음",
                      onPressed: (_purposeController.text.trim().isNotEmpty && 
                                _selectedHumorStyle.isNotEmpty) 
                                ? _onNextPressed 
                                : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 