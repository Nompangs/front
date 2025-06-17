import 'package:flutter/foundation.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/personality_service.dart';
import 'dart:math';
import 'dart:convert';

class OnboardingProvider extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();
  PersonalityProfile _profile = PersonalityProfile.empty();
  AIPersonalityDraft? _draft;
  PersonalityProfile? _generatedCharacter;

  PersonalityProfile get personalityProfile => _profile;

  OnboardingState get state => _state;

  // 페르소나 생성 과정을 위한 상태 변수들
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String _generationMessage = '';
  String get generationMessage => _generationMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AIPersonalityDraft? get draft => _draft;

  PersonalityProfile? get generatedCharacter => _generatedCharacter;

  OnboardingProvider() {
    _logStatus('OnboardingProvider 생성됨');
  }

  void _logStatus(String action) {
    // debugPrint('=== Onboarding Status [$action] ===');
    // debugPrint(jsonEncode(_state.toJson()));
    // debugPrint(jsonEncode(_profile.toMap()));
    // debugPrint('===============================');
  }
  
  void updateUserBasicInfo({
    required String nickname,
    required String location,
    required String duration,
    required String objectType,
  }) {
    _state = _state.copyWith(
      nickname: nickname,
      location: location,
      duration: duration,
      objectType: objectType,
    );
    notifyListeners();
    _logStatus('updateUserBasicInfo');
  }
  
  /// 용도 업데이트 (Step 3)
  void updatePurpose(String purpose) {
    _state = _state.copyWith(purpose: purpose);
    notifyListeners();
    _logStatus('updatePurpose');
  }
  
  /// 유머스타일 업데이트 (Step 3)
  void updateHumorStyle(String style) {
    _state = _state.copyWith(humorStyle: style);
    notifyListeners();
    _logStatus('updateHumorStyle');
  }
  
  /// 사진 경로 업데이트 (Step 4)
  void updatePhotoPath(String? path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
    _logStatus('updatePhotoPath');
  }
  
  /// 성격 슬라이더 업데이트 (Step 6)
  void updatePersonalitySlider(String type, int value) {
    switch (type) {
      case 'introversion':
        _state = _state.copyWith(introversion: value);
        break;
      case 'warmth':
        _state = _state.copyWith(warmth: value);
        break;
      case 'competence':
        _state = _state.copyWith(competence: value);
        break;
    }
    notifyListeners();
    _logStatus('updatePersonalitySlider');
  }
  
  void setPhotoPath(String path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
    _logStatus('setPhotoPath');
  }
  
  void setGeneratedCharacter(PersonalityProfile profile) {
    _generatedCharacter = profile;
    notifyListeners();
    _logStatus('setGeneratedCharacter');
  }
  
  void setError(String error) {
    _state = _state.copyWith(errorMessage: error, isLoading: false);
    notifyListeners();
    _logStatus('setError');
  }
  
  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
    _logStatus('clearError');
  }
  
  /// 서버 전송용 사용자 입력 데이터를 Map으로 변환합니다.
  Map<String, dynamic> getUserInputAsMap() {
    return {
      'photoPath': state.photoPath,
      'objectType': state.objectType,
      'purpose': state.purpose,
      'nickname': state.nickname,
      'location': state.location,
      'duration': state.duration,
      'humorStyle': state.humorStyle,
      'warmth': state.warmth,
      'introversion': state.introversion,
      'competence': state.competence,
    };
  }
  
  /*
  // 이 함수는 personality_service로 대체되었으므로 주석 처리합니다.
  Future<void> generateCharacter() async {
    if (_state.nickname.isEmpty) {
      setError('사용자 입력 정보가 없습니다.');
      return;
    }
    
    _state = _state.copyWith(
      isGenerating: true, 
      generationProgress: 0.0,
      generationMessage: "캐릭터 깨우는 중..."
    );
    notifyListeners();
    _logStatus('startGenerateCharacter');
    
    try {
      // 3단계 시뮬레이션 (Figma 정확)
      await _simulateProgress(0.3, "캐릭터 깨우는 중...");
      await _simulateProgress(0.7, "개성을 찾고 있어요");
      await _simulateProgress(1.0, "마음을 열고 있어요");
      
      // 실제 AI 호출 (향후 구현)
      final character = await _generateMockCharacter();
      
      _generatedCharacter = character;
      _state = _state.copyWith(
        isGenerating: false,
        generationProgress: 1.0,
      );
      notifyListeners();
      _logStatus('generateCharacterComplete');
      
    } catch (e) {
      _state = _state.copyWith(
        isGenerating: false,
        errorMessage: '캐릭터 생성 중 오류가 발생했습니다: $e'
      );
      notifyListeners();
      _logStatus('generateCharacterError');
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
      _logStatus('simulateProgress');
    }
  }
  
  Future<PersonalityProfile> _generateMockCharacter() async {
    final random = Random();
    
    // 사용자가 입력한 용도와 유머스타일을 반영한 성격 생성
    final aiProfile = AiPersonalityProfile(
      name: _state.nickname,
      objectType: _state.objectType,
      emotionalRange: 50 + random.nextInt(40),
      coreValues: ['신뢰', '재미'],
      relationshipStyle: '조력자',
      summary: '이것은 목업 데이터입니다.'
    );
    
    return PersonalityProfile(
      aiPersonalityProfile: aiProfile,
      greeting: "만나서 반가워요! 저는 목업 캐릭터입니다.",
      contradictions: [],
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
  
  String _generateGreeting(String name, Personality personality) {
    if (personality.warmth > 70) {
      return "안녕, $name! 만나서 정말 반가워. 무슨 재미있는 이야기 해볼까?";
    } else {
      return "반가워, $name. 나는 네가 필요할 때 곁에 있을게.";
    }
  }
  */
  
  void setPersonalityProfile(PersonalityProfile profile) {
    _profile = profile;
    notifyListeners();
    _logStatus('setPersonalityProfile');
  }

  void reset() {
    _state = const OnboardingState();
    _profile = PersonalityProfile.empty();
    _draft = null;
    _generatedCharacter = null;
    _isGenerating = false;
    _generationMessage = '';
    _errorMessage = null;
    notifyListeners();
    _logStatus('reset');
  }

  // 생성 과정 상태를 업데이트하는 메서드
  void setGenerating(bool generating, String message) {
    _isGenerating = generating;
    _generationMessage = message;
    if (generating) {
      _errorMessage = null; // 생성을 시작하면 이전 에러 메시지는 초기화
    }
    notifyListeners();
  }

  void setErrorMessage(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 최종 생성된 페르소나 프로필을 저장하는 메서드
  void setFinalPersonality(PersonalityProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  // AI 초안 데이터를 저장하는 메소드
  void setAiDraft(AIPersonalityDraft draft) {
    _draft = draft;
    // AI 추천값으로 state 업데이트
    _state = _state.copyWith(
      warmth: draft.initialWarmth,
      introversion: draft.initialIntroversion,
      competence: draft.initialCompetence,
    );
    notifyListeners();
    _logStatus('setAiDraft');
  }

  void updateGenerationStatus(double progress, String message) {
    _state = _state.copyWith(
      generationProgress: progress,
      generationMessage: message,
    );
    notifyListeners();
  }
}
