import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/widgets/common/personality_slider.dart';
import 'package:nompangs/widgets/common/primary_button.dart';
import 'package:nompangs/theme/app_theme.dart';

class OnboardingPersonalityScreen extends StatefulWidget {
  const OnboardingPersonalityScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingPersonalityScreen> createState() => _OnboardingPersonalityScreenState();
}

class _OnboardingPersonalityScreenState extends State<OnboardingPersonalityScreen>
    with TickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    
    _avatarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _avatarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
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
        title: const Text('성격 조정'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/onboarding/completion'),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          final character = provider.state.generatedCharacter;
          
          if (character == null) {
            return const Center(
              child: Text('캐릭터 정보를 불러올 수 없습니다.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // 상단 타이틀
                Text(
                  '${character.name}의 성격을\n미세 조정해보세요',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // 캐릭터 프리뷰 카드
                _buildCharacterPreviewCard(character),
                
                const SizedBox(height: 40),
                
                // 성격 슬라이더들
                _buildPersonalitySliders(character, provider),
                
                const SizedBox(height: 40),
                
                // 하단 버튼들
                _buildBottomActions(provider),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterPreviewCard(Character character) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // 캐릭터 아바타
          AnimatedBuilder(
            animation: _avatarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, sin(_avatarAnimation.value * 2 * 3.14159) * 5),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getAvatarColor(character.personality),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: _getAvatarColor(character.personality),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getAvatarIcon(character.objectType),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // 이름
          Text(
            character.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 성격 태그들
          Wrap(
            spacing: 8,
            children: character.traits.map((trait) => Chip(
              label: Text(
                '#$trait',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.getPersonalityColor(trait).withOpacity(0.2),
              side: BorderSide.none,
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // 첫 인사말
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${character.greeting}"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF6750A4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySliders(Character character, OnboardingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성격 지표',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '슬라이더를 조정해서 성격을 미세 조정할 수 있어요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 온기 슬라이더
        PersonalitySlider(
          label: '온기',
          color: AppTheme.warmthHigh,
          value: character.personality.warmth.toDouble(),
          leftLabel: '차가운',
          rightLabel: '따뜻한',
          onChanged: (value) {
            provider.updatePersonality(PersonalityType.warmth, value);
          },
        ),
        
        const SizedBox(height: 24),
        
        // 유능함 슬라이더
        PersonalitySlider(
          label: '유능함',
          color: AppTheme.competenceHigh,
          value: character.personality.competence.toDouble(),
          leftLabel: '순수한',
          rightLabel: '유능한',
          onChanged: (value) {
            provider.updatePersonality(PersonalityType.competence, value);
          },
        ),
        
        const SizedBox(height: 24),
        
        // 외향성 슬라이더
        PersonalitySlider(
          label: '외향성',
          color: AppTheme.extroversionHigh,
          value: character.personality.extroversion.toDouble(),
          leftLabel: '내성적',
          rightLabel: '활발한',
          onChanged: (value) {
            provider.updatePersonality(PersonalityType.extroversion, value);
          },
        ),
      ],
    );
  }

  Widget _buildBottomActions(OnboardingProvider provider) {
    return Column(
      children: [
        PrimaryButton(
          text: '이 성격으로 완성',
          onPressed: () {
            Navigator.pushNamed(context, '/onboarding/completion');
          },
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () {
                // 새로운 성격 재생성
                provider.generateCharacter();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                '다시 생성',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            TextButton.icon(
              onPressed: () {
                // 음성으로 들어보기 (향후 구현)
                _playGreeting(provider.state.generatedCharacter!.greeting);
              },
              icon: const Icon(Icons.volume_up, size: 20),
              label: const Text(
                '음성 듣기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getAvatarColor(Personality personality) {
    // 성격에 따른 아바타 색상 결정
    if (personality.warmth > 70) {
      return AppTheme.warmthHigh;
    } else if (personality.competence > 70) {
      return AppTheme.competenceHigh;
    } else if (personality.extroversion > 70) {
      return AppTheme.extroversionHigh;
    } else {
      return AppTheme.accent;
    }
  }

  IconData _getAvatarIcon(String objectType) {
    // 사물 타입에 따른 아이콘 결정
    if (objectType.contains('컵') || objectType.contains('머그')) {
      return Icons.local_cafe;
    } else if (objectType.contains('책')) {
      return Icons.book;
    } else if (objectType.contains('인형') || objectType.contains('곰')) {
      return Icons.toys;
    } else if (objectType.contains('폰') || objectType.contains('핸드폰')) {
      return Icons.phone_android;
    } else if (objectType.contains('식물') || objectType.contains('화분')) {
      return Icons.local_florist;
    } else {
      return Icons.favorite;
    }
  }

  void _playGreeting(String greeting) {
    // 향후 TTS 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('음성 기능은 곧 구현될 예정입니다: "$greeting"'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double sin(double value) {
    return (value % (2 * 3.14159) - 3.14159).abs() > 1.5708 
        ? -1 * (value % (2 * 3.14159) > 3.14159 ? -1 : 1) * 
          (1 - (value % (2 * 3.14159) - (value % (2 * 3.14159) > 3.14159 ? 3.14159 : 0)).abs() / 1.5708)
        : (value % (2 * 3.14159) > 3.14159 ? -1 : 1) * 
          (value % (2 * 3.14159) - (value % (2 * 3.14159) > 3.14159 ? 3.14159 : 0)) / 1.5708;
  }
} 