import 'package:flutter/foundation.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'dart:math';

class OnboardingProvider extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();
  
  OnboardingState get state => _state;
  
  void nextStep() {
    _state = _state.copyWith(currentStep: _state.currentStep + 1);
    notifyListeners();
  }
  
  void setUserInput(UserInput input) {
    _state = _state.copyWith(userInput: input);
    notifyListeners();
  }
  
  void setPhotoPath(String path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
  }
  
  void setGeneratedCharacter(Character character) {
    _state = _state.copyWith(generatedCharacter: character);
    notifyListeners();
  }
  
  void setError(String error) {
    _state = _state.copyWith(errorMessage: error, isLoading: false);
    notifyListeners();
  }
  
  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
  
  Future<void> generateCharacter() async {
    if (_state.userInput == null) {
      setError('사용자 입력 정보가 없습니다.');
      return;
    }
    
    _state = _state.copyWith(
      isGenerating: true, 
      generationProgress: 0.0,
      generationMessage: "사물의 특징을 파악하고 있어요"
    );
    notifyListeners();
    
    try {
      // 단계별 시뮬레이션
      await _simulateProgress(0.4, "사물의 특징을 파악하고 있어요");
      await _simulateProgress(0.8, "당신만의 놈팽쓰 성격을 만들어요");
      
      // 실제 AI 호출 (향후 구현)
      final character = await _generateMockCharacter();
      
      await _simulateProgress(1.0, "놈팽쓰가 깨어났어요!");
      
      _state = _state.copyWith(
        generatedCharacter: character,
        isGenerating: false,
        generationProgress: 1.0,
      );
      notifyListeners();
      
    } catch (e) {
      _state = _state.copyWith(
        isGenerating: false,
        errorMessage: '캐릭터 생성 중 오류가 발생했습니다: $e'
      );
      notifyListeners();
    }
  }
  
  Future<void> _simulateProgress(double target, String message) async {
    while (_state.generationProgress < target) {
      await Future.delayed(const Duration(milliseconds: 200));
      _state = _state.copyWith(
        generationProgress: _state.generationProgress + 0.05,
        generationMessage: message,
      );
      notifyListeners();
    }
  }
  
  Future<Character> _generateMockCharacter() async {
    final userInput = _state.userInput!;
    final random = Random();
    
    // 임시 성격 생성 로직
    final personality = Personality(
      warmth: 50 + random.nextInt(40),
      competence: 30 + random.nextInt(50), 
      extroversion: 40 + random.nextInt(40),
    );
    
    final traits = _generateTraits(personality);
    final greeting = _generateGreeting(userInput.nickname, personality);
    
    return Character(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: userInput.nickname,
      objectType: userInput.objectType,
      personality: personality,
      greeting: greeting,
      traits: traits,
      createdAt: DateTime.now(),
    );
  }
  
  List<String> _generateTraits(Personality personality) {
    final traits = <String>[];
    
    if (personality.warmth > 70) {
      traits.add("따뜻한");
    } else if (personality.warmth < 30) {
      traits.add("차분한");
    }
    
    if (personality.competence > 70) {
      traits.add("유능한");
    } else if (personality.competence < 30) {
      traits.add("순수한");
    }
    
    if (personality.extroversion > 70) {
      traits.add("활발한");
    } else if (personality.extroversion < 30) {
      traits.add("내성적인");
    }
    
    return traits;
  }
  
  String _generateGreeting(String nickname, Personality personality) {
    if (personality.warmth > 70 && personality.extroversion > 70) {
      return "$nickname! 안녕! 나 정말 만나고 싶었어! 우리 친해지자!";
    } else if (personality.warmth > 70 && personality.extroversion < 30) {
      return "안녕... $nickname. 조용히 곁에 있어줄게. 언제든 말 걸어줘.";
    } else if (personality.warmth < 30 && personality.competence > 70) {
      return "네, $nickname님. 필요한 것이 있으면 효율적으로 도와드리겠습니다.";
    } else {
      return "음... $nickname아. 서서히 친해져보자. 서두르지 말고.";
    }
  }
  
  void updatePersonality(PersonalityType type, double value) {
    final currentCharacter = _state.generatedCharacter;
    if (currentCharacter == null) return;
    
    final intValue = value.round();
    Personality updatedPersonality;
    
    switch (type) {
      case PersonalityType.warmth:
        updatedPersonality = currentCharacter.personality.copyWith(warmth: intValue);
        break;
      case PersonalityType.competence:
        updatedPersonality = currentCharacter.personality.copyWith(competence: intValue);
        break;
      case PersonalityType.extroversion:
        updatedPersonality = currentCharacter.personality.copyWith(extroversion: intValue);
        break;
    }
    
    final updatedGreeting = _generateGreeting(currentCharacter.name, updatedPersonality);
    final updatedTraits = _generateTraits(updatedPersonality);
    
    final updatedCharacter = currentCharacter.copyWith(
      personality: updatedPersonality,
      greeting: updatedGreeting,
      traits: updatedTraits,
    );
    
    _state = _state.copyWith(generatedCharacter: updatedCharacter);
    notifyListeners();
  }
  
  void reset() {
    _state = const OnboardingState();
    notifyListeners();
  }
} 