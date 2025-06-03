import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/widgets/common/primary_button.dart';
import 'package:nompangs/theme/app_theme.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingCompletionScreen> createState() => _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _bounceController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // 축하 애니메이션 시작
    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _bounceController.dispose();
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
        title: const Text('완성!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, 
              '/home', 
              (route) => false,
            ),
            child: const Text('홈으로'),
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
              children: [
                const SizedBox(height: 20),
                
                // 축하 메시지
                AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _celebrationAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            '🎉',
                            style: TextStyle(
                              fontSize: 60 * _celebrationAnimation.value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '놈팽쓰가 완성되었어요!',
                            style: Theme.of(context).textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // 캐릭터 완성 카드
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _bounceAnimation.value,
                      child: _buildCharacterCard(character),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // QR 코드 섹션
                _buildQRSection(character),
                
                const SizedBox(height: 40),
                
                // 사용법 가이드
                _buildUsageGuide(),
                
                const SizedBox(height: 40),
                
                // 하단 액션 버튼들
                _buildBottomActions(character),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // 캐릭터 아바타
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _getCharacterColor(character.personality),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: _getCharacterColor(character.personality),
                width: 3,
              ),
            ),
            child: Icon(
              _getCharacterIcon(character.objectType),
              color: Colors.white,
              size: 50,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 이름과 타입
          Text(
            character.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            character.objectType,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 성격 지표
          _buildPersonalityIndicators(character.personality),
          
          const SizedBox(height: 16),
          
          // 특성 태그
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
          
          const SizedBox(height: 20),
          
          // 첫 인사말
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  '첫 인사',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6750A4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${character.greeting}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6750A4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityIndicators(Personality personality) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPersonalityBar('온기', personality.warmth, AppTheme.warmthHigh),
        _buildPersonalityBar('유능함', personality.competence, AppTheme.competenceHigh),
        _buildPersonalityBar('외향성', personality.extroversion, AppTheme.extroversionHigh),
      ],
    );
  }

  Widget _buildPersonalityBar(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Container(
                width: 60 * (value / 100),
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection(Character character) {
    final qrData = _generateQRData(character);
    
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
          Text(
            'QR 코드',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '이 QR을 사물에 붙여보세요!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // QR 코드
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // QR 액션 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _saveQRCode(),
                icon: const Icon(Icons.download, size: 20),
                label: const Text('저장'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _shareQRCode(character),
                icon: const Icon(Icons.share, size: 20),
                label: const Text('공유'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.info,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _printQRCode(),
                icon: const Icon(Icons.print, size: 20),
                label: const Text('인쇄'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.sectionBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사용법 가이드',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          
          const SizedBox(height: 16),
          
          _buildGuideStep('1', 'QR 스티커 출력', 'QR 코드를 스티커 용지에 인쇄하세요'),
          const SizedBox(height: 12),
          _buildGuideStep('2', '사물에 부착', '애착 사물에 QR 스티커를 붙여주세요'),
          const SizedBox(height: 12),
          _buildGuideStep('3', '스캔하여 대화', '언제든 QR을 스캔해서 대화를 시작하세요'),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF6750A4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(Character character) {
    return Column(
      children: [
        PrimaryButton(
          text: '지금 바로 대화하기',
          onPressed: () {
            // 첫 대화 시작
            Navigator.pushNamed(
              context, 
              '/chat/${character.id}',
              arguments: character,
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                // 다른 친구 만들기
                final provider = Provider.of<OnboardingProvider>(context, listen: false);
                provider.reset();
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/onboarding/intro', 
                  (route) => false,
                );
              },
              child: const Text(
                '다른 친구 만들기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/home', 
                  (route) => false,
                );
              },
              child: const Text(
                '홈으로 가기',
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

  String _generateQRData(Character character) {
    final data = {
      'characterId': character.id,
      'name': character.name,
      'objectType': character.objectType,
      'personality': {
        'warmth': character.personality.warmth,
        'competence': character.personality.competence,
        'extroversion': character.personality.extroversion,
      },
      'greeting': character.greeting,
      'traits': character.traits,
      'createdAt': character.createdAt?.toIso8601String(),
    };
    
    return 'nompangs://character?data=${base64Encode(utf8.encode(jsonEncode(data)))}';
  }

  Color _getCharacterColor(Personality personality) {
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

  IconData _getCharacterIcon(String objectType) {
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

  Future<void> _saveQRCode() async {
    try {
      // QR 코드 이미지 저장 (향후 구현)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR 코드가 갤러리에 저장되었습니다!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _shareQRCode(Character character) async {
    final qrData = _generateQRData(character);
    await Share.share(
      '${character.name}와 함께하세요! 놈팽쓰 QR: $qrData',
      subject: '놈팽쓰 친구 공유',
    );
  }

  void _printQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('인쇄 기능은 곧 구현될 예정입니다!'),
      ),
    );
  }
} 