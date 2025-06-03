import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';

class OnboardingGenerationScreen extends StatefulWidget {
  const OnboardingGenerationScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingGenerationScreen> createState() => _OnboardingGenerationScreenState();
}

class _OnboardingGenerationScreenState extends State<OnboardingGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  final List<GenerationStep> steps = [
    GenerationStep(0.4, '사물의 특징을 파악하고 있어요', '사진 속 사물의 특성을 분석하고 있어요'),
    GenerationStep(0.8, '당신만의 놈팽쓰 성격을 만들어요', '입력하신 정보를 바탕으로 고유한 성격을 생성해요'),
    GenerationStep(1.0, '놈팽쓰가 깨어났어요!', '당신만의 특별한 놈팽쓰가 탄생했어요'),
  ];

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Provider 상태 확인 후 생성 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartGeneration();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkAndStartGeneration() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    
    // 사용자 입력이 없는 경우 에러 처리
    if (provider.state.userInput == null) {
      provider.setError('사용자 입력 정보가 없습니다. 이전 단계로 돌아가서 정보를 입력해주세요.');
      return;
    }
    
    // 이미 생성 중이거나 완성된 경우가 아니라면 생성 시작
    if (!provider.state.isGenerating && provider.state.generatedCharacter == null) {
      _startGeneration();
    }
  }

  void _startGeneration() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    await provider.generateCharacter();
    
    if (mounted && provider.state.generatedCharacter != null) {
      Navigator.pushReplacementNamed(context, '/onboarding/personality');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('놈팽쓰 생성'),
      ),
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          final state = provider.state;
          
          if (state.errorMessage != null) {
            return _buildErrorScreen(state.errorMessage!);
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 진행률 표시
                  _buildProgressIndicator(state.generationProgress),
                  
                  const SizedBox(height: 40),
                  
                  // 로딩 스피너
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6750A4),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 현재 단계 표시
                  Text(
                    state.generationMessage,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _getCurrentStepDescription(state.generationProgress),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 입력 정보 요약
                  if (state.userInput != null)
                    _buildInputSummary(state.userInput!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        // 진행률 바
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: MediaQuery.of(context).size.width * 0.7 * progress,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 퍼센트 표시
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6750A4),
          ),
        ),
      ],
    );
  }

  String _getCurrentStepDescription(double progress) {
    int currentStepIndex = ((progress * steps.length).floor()).clamp(0, steps.length - 1);
    return steps[currentStepIndex].description;
  }

  Widget _buildInputSummary(UserInput userInput) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${userInput.nickname}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${userInput.location} • ${userInput.duration} • ${userInput.objectType}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            
            const SizedBox(height: 24),
            
            Text(
              '생성 중 오류가 발생했어요',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            Consumer<OnboardingProvider>(
              builder: (context, provider, child) {
                final hasUserInput = provider.state.userInput != null;
                
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        
                        if (hasUserInput) {
                          _startGeneration();
                        } else {
                          Navigator.pushReplacementNamed(context, '/onboarding/input');
                        }
                      },
                      child: Text(hasUserInput ? '다시 시도' : '정보 입력하러 가기'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/input'),
                      child: const Text('이전으로 돌아가기'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GenerationStep {
  final double progress;
  final String title;
  final String description;

  GenerationStep(this.progress, this.title, this.description);
} 