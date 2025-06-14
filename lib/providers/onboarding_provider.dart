import 'package:flutter/foundation.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/personality_variables_service.dart';
import 'package:nompangs/services/ai_personality_service.dart';
import 'dart:math';
import 'dart:convert';

class OnboardingProvider extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();
  PersonalityProfile _profile = PersonalityProfile.empty();

  PersonalityProfile get personalityProfile => _profile;

  OnboardingState get state => _state;

  // 페르소나 생성 과정을 위한 상태 변수들
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String _generationMessage = '';
  String get generationMessage => _generationMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _logStatus(String action) {
    debugPrint('=== Onboarding Status [$action] ===');
    debugPrint(jsonEncode(_state.toJson()));
    debugPrint(jsonEncode(_profile.toMap()));
    debugPrint('===============================');
  }

  void nextStep() {
    _state = _state.copyWith(currentStep: _state.currentStep + 1);
    notifyListeners();
    _logStatus('nextStep');
  }

  void setUserInput(UserInput input) {
    _state = _state.copyWith(userInput: input);
    notifyListeners();
    _logStatus('setUserInput');
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

  /// 성격 슬라이더 업데이트 (Step 6) - 127개 성격 변수 자동 연동
  void updatePersonalitySlider(String type, int value) {
    final oldState = _state;

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

    debugPrint('🎛️ 성격 슬라이더 업데이트 [$type]:');
    debugPrint('   📊 값 변화: ${_getOldValue(oldState, type)} → $value');
    debugPrint(
      '   🔧 현재 상태: 온기=${_state.warmth}, 능력=${_state.competence}, 내향성=${_state.introversion}',
    );

    // 3가지 핵심 특성이 모두 설정되었을 때 151개 성격 변수 자동 생성
    if (_state.warmth != null &&
        _state.competence != null &&
        _state.introversion != null) {
      debugPrint('🔧 3가지 핵심 특성 모두 설정됨 → 151개 성격 변수 자동 생성 시작');
      _updatePersonalityVariables();
    } else {
      debugPrint(
        '⏳ 아직 설정되지 않은 특성이 있음 (온기: ${_state.warmth}, 능력: ${_state.competence}, 내향성: ${_state.introversion})',
      );
    }

    notifyListeners();
    _logStatus('updatePersonalitySlider');
  }

  /// 이전 값 조회 헬퍼 메서드
  int? _getOldValue(OnboardingState oldState, String type) {
    switch (type) {
      case 'introversion':
        return oldState.introversion;
      case 'warmth':
        return oldState.warmth;
      case 'competence':
        return oldState.competence;
      default:
        return null;
    }
  }

  /// 성격 변수 업데이트 (151개 자동 생성)
  void _updatePersonalityVariables() {
    if (_state.warmth == null ||
        _state.competence == null ||
        _state.introversion == null) {
      debugPrint('⚠️ 핵심 특성이 모두 설정되지 않아 성격 변수 생성 불가');
      return;
    }

    final startTime = DateTime.now();
    debugPrint('🚀 성격 변수 업데이트 시작');

    // 이전 성격 변수 상태 저장
    final oldVariables = Map<String, double>.from(
      _profile.personalityVariables,
    );

    // 새로운 151개 성격 변수 생성
    final newVariables =
        PersonalityVariablesService.generatePersonalityVariables(
          warmth: _state.warmth!.toDouble(),
          competence: _state.competence!.toDouble(),
          introversion: _state.introversion!.toDouble(),
        );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;

    debugPrint('✅ 성격 변수 업데이트 완료 (${duration}ms)');
    debugPrint('   📊 생성된 변수 개수: ${newVariables.length}개');

    if (newVariables.length != 151) {
      debugPrint('⚠️ 예상과 다른 변수 개수: ${newVariables.length}개 (151개 예상)');
    } else {
      debugPrint('✅ 성격 변수 개수 정상: 151개');
    }

    // 카테고리별 평균 계산 시작
    final categoryStartTime = DateTime.now();
    final categoryAverages =
        PersonalityVariablesService.calculateCategoryAverages(newVariables);
    final categoryEndTime = DateTime.now();
    final categoryDuration =
        categoryEndTime.difference(categoryStartTime).inMilliseconds;

    debugPrint('📊 카테고리별 평균 점수 계산 완료 (${categoryDuration}ms):');
    categoryAverages.forEach((category, average) {
      debugPrint('   - $category: ${average.toStringAsFixed(1)}점');
    });

    // 이전 프로필과 비교 분석
    if (oldVariables.isNotEmpty) {
      final oldAverages = PersonalityVariablesService.calculateCategoryAverages(
        oldVariables,
      );
      debugPrint('🔄 카테고리별 변화량:');
      categoryAverages.forEach((category, newAvg) {
        final oldAvg = oldAverages[category] ?? 0;
        final change = newAvg - oldAvg;
        if (change.abs() > 0.1) {
          final changeStr =
              change > 0
                  ? '+${change.toStringAsFixed(1)}'
                  : change.toStringAsFixed(1);
          debugPrint(
            '   - $category: ${oldAvg.toStringAsFixed(1)} → ${newAvg.toStringAsFixed(1)} ($changeStr)',
          );
        }
      });
    }

    // PersonalityProfile 업데이트
    final updateStartTime = DateTime.now();
    _profile = PersonalityProfile(
      aiPersonalityProfile: _profile.aiPersonalityProfile,
      photoAnalysis: _profile.photoAnalysis,
      lifeStory: _profile.lifeStory,
      humorMatrix: _profile.humorMatrix,
      attractiveFlaws: _profile.attractiveFlaws,
      contradictions: _profile.contradictions,
      communicationStyle: _profile.communicationStyle,
      structuredPrompt: _profile.structuredPrompt,
      personalityVariables: newVariables,
      uuid: _profile.uuid,
      greeting: _profile.greeting,
      initialUserMessage: _profile.initialUserMessage,
    );
    final updateEndTime = DateTime.now();
    final updateDuration =
        updateEndTime.difference(updateStartTime).inMilliseconds;

    debugPrint('🎯 PersonalityProfile 업데이트 완료 (${updateDuration}ms)');

    // 전체 처리 시간 요약
    final totalDuration = updateEndTime.difference(startTime).inMilliseconds;
    debugPrint('⚡ 전체 성격 변수 처리 시간: ${totalDuration}ms');
    debugPrint('   - 변수 생성: ${duration}ms');
    debugPrint('   - 카테고리 계산: ${categoryDuration}ms');
    debugPrint('   - 프로필 업데이트: ${updateDuration}ms');
  }

  /// 성격 변수 강제 재생성 (디버깅/테스트용)
  void regeneratePersonalityVariables() {
    if (_state.warmth != null &&
        _state.competence != null &&
        _state.introversion != null) {
      _updatePersonalityVariables();
      notifyListeners();
      _logStatus('regeneratePersonalityVariables');
    }
  }

  /// 특정 카테고리의 성격 변수들 조회
  Map<String, double> getPersonalityVariablesByCategory(String category) {
    return _profile.getVariablesByCategory(category);
  }

  /// 모든 성격 변수의 카테고리별 분류 조회
  Map<String, Map<String, double>> getCategorizedPersonalityVariables() {
    return _profile.getCategorizedVariables();
  }

  /// 카테고리별 평균 점수 조회
  Map<String, double> getPersonalityCategoryAverages() {
    return _profile.getCategoryAverages();
  }

  /// QR 코드 URL 업데이트 (완료 단계)
  void updateQRCodeUrl(String url) {
    _state = _state.copyWith(qrCodeUrl: url);
    notifyListeners();
    _logStatus('updateQRCodeUrl');
  }

  void setPhotoPath(String path) {
    _state = _state.copyWith(photoPath: path);
    notifyListeners();
    _logStatus('setPhotoPath');
  }

  void setGeneratedCharacter(Character character) {
    _state = _state.copyWith(generatedCharacter: character);
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

  Future<void> generateCharacter() async {
    if (_state.userInput == null) {
      setError('사용자 입력 정보가 없습니다.');
      return;
    }

    _state = _state.copyWith(
      isGenerating: true,
      generationProgress: 0.0,
      generationMessage: "캐릭터 깨우는 중...",
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

      _state = _state.copyWith(
        generatedCharacter: character,
        isGenerating: false,
        generationProgress: 1.0,
      );
      notifyListeners();
      _logStatus('generateCharacterComplete');
    } catch (e) {
      _state = _state.copyWith(
        isGenerating: false,
        errorMessage: '캐릭터 생성 중 오류가 발생했습니다: $e',
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

  Future<Character> _generateMockCharacter() async {
    final userInput = _state.userInput!;
    final random = Random();

    // 사용자가 입력한 용도와 유머스타일을 반영한 성격 생성
    final personality = Personality(
      warmth: _state.warmth ?? (50 + random.nextInt(40)),
      competence: _state.competence ?? (30 + random.nextInt(50)),
      extroversion: _state.introversion ?? (40 + random.nextInt(40)),
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
    // 유머스타일에 따른 인사말 생성
    final humorStyle = _state.humorStyle ?? '';

    if (humorStyle == '따뜻한') {
      return "$nickname아~ 안녕! 따뜻하게 함께하자 💕";
    } else if (humorStyle == '날카로운 관찰자적') {
      return "흠... $nickname. 너에 대해 관찰해보겠어. 흥미롭군.";
    } else if (humorStyle == '위트있는') {
      return "$nickname! 나와 함께라면 재미있을 거야. 위트 한 스푼 넣어서! 😂";
    } else if (humorStyle == '자기비하적') {
      return "어... $nickname? 나 같은 거랑 친해져도 괜찮을까? 😅";
    } else if (humorStyle == '장난꾸러기') {
      return "앗! $nickname 발견! 나랑 장난치자~ 헤헤 😝";
    } else {
      return "안녕 $nickname! 잘 부탁해 😊";
    }
  }

  void updatePersonality(PersonalityType type, double value) {
    final currentCharacter = _state.generatedCharacter;
    if (currentCharacter == null) return;

    final intValue = value.round();
    Personality updatedPersonality;

    switch (type) {
      case PersonalityType.warmth:
        updatedPersonality = currentCharacter.personality.copyWith(
          warmth: intValue,
        );
        break;
      case PersonalityType.competence:
        updatedPersonality = currentCharacter.personality.copyWith(
          competence: intValue,
        );
        break;
      case PersonalityType.extroversion:
        updatedPersonality = currentCharacter.personality.copyWith(
          extroversion: intValue,
        );
        break;
    }

    final updatedGreeting = _generateGreeting(
      currentCharacter.name,
      updatedPersonality,
    );
    final updatedTraits = _generateTraits(updatedPersonality);

    final updatedCharacter = currentCharacter.copyWith(
      personality: updatedPersonality,
      greeting: updatedGreeting,
      traits: updatedTraits,
    );

    _state = _state.copyWith(generatedCharacter: updatedCharacter);
    notifyListeners();
    _logStatus('updatePersonality');
  }

  void setPersonalityProfile(PersonalityProfile profile) {
    _profile = profile;
    notifyListeners();
    _logStatus('setPersonalityProfile');
  }

  void reset() {
    _state = const OnboardingState();
    _profile = PersonalityProfile.empty();
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

  Future<void> generateAiAnalysis() async {
    debugPrint('�� AI 기반 분석 생성 시작');

    try {
      // AI 기반 매력적 특성 생성
      final attractiveFlaws =
          await AiPersonalityService.generateAttractiveFlaws(
            state: _state,
            profile: _profile,
          );

      // AI 기반 모순적 특성 생성
      final contradictions = await AiPersonalityService.generateContradictions(
        state: _state,
        profile: _profile,
      );

      // AI 기반 성격 태그 생성
      final personalityTags =
          await AiPersonalityService.generatePersonalityTags(
            state: _state,
            profile: _profile,
          );

      // AI 기반 인사말 생성
      final greeting = await AiPersonalityService.generateGreeting(
        state: _state,
        profile: _profile,
      );

      // 프로필에 AI 분석 결과 추가
      _profile = PersonalityProfile(
        aiPersonalityProfile: _profile.aiPersonalityProfile,
        photoAnalysis: _profile.photoAnalysis,
        lifeStory: _profile.lifeStory,
        humorMatrix: _profile.humorMatrix,
        attractiveFlaws: attractiveFlaws,
        contradictions: contradictions,
        communicationStyle: _profile.communicationStyle,
        structuredPrompt: _profile.structuredPrompt,
        personalityVariables: _profile.personalityVariables,
        uuid: _profile.uuid,
        greeting: greeting, // AI 생성 인사말 추가
        initialUserMessage: _profile.initialUserMessage,
      );

      debugPrint('✅ AI 분석 생성 완료:');
      debugPrint('   - 매력적 특성: ${attractiveFlaws.length}개');
      debugPrint('   - 모순적 특성: ${contradictions.length}개');
      debugPrint('   - 성격 태그: ${personalityTags.length}개');
      debugPrint('   - 인사말: $greeting');

      notifyListeners();
    } catch (e) {
      debugPrint('🚨 AI 분석 생성 오류: $e');
      // 오류 시에도 기본값으로 설정
      _profile = PersonalityProfile(
        aiPersonalityProfile: _profile.aiPersonalityProfile,
        photoAnalysis: _profile.photoAnalysis,
        lifeStory: _profile.lifeStory,
        humorMatrix: _profile.humorMatrix,
        attractiveFlaws: ['완벽하지 않은 귀여운 면'],
        contradictions: ['복합적인 매력'],
        communicationStyle: _profile.communicationStyle,
        structuredPrompt: _profile.structuredPrompt,
        personalityVariables: _profile.personalityVariables,
        uuid: _profile.uuid,
        greeting: '안녕하세요! 만나서 반가워요!',
        initialUserMessage: _profile.initialUserMessage,
      );
      notifyListeners();
    }
  }
}
