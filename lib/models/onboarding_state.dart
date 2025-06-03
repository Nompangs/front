import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(null) UserInput? userInput,
    @Default(null) String? photoPath,
    @Default(null) Character? generatedCharacter,
    @Default(false) bool isLoading,
    @Default(null) String? errorMessage,
    @Default(false) bool isGenerating,
    @Default(0.0) double generationProgress,
    @Default("") String generationMessage,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);
}

@freezed
class UserInput with _$UserInput {
  const factory UserInput({
    required String nickname,
    required String location,
    required String duration,
    required String objectType,
    @Default("") String additionalInfo,
  }) = _UserInput;

  factory UserInput.fromJson(Map<String, dynamic> json) =>
      _$UserInputFromJson(json);
}

@freezed
class Character with _$Character {
  const factory Character({
    required String id,
    required String name,
    required String objectType,
    required Personality personality,
    required String greeting,
    required List<String> traits,
    @Default("") String systemPrompt,
    @Default("") String qrCode,
    DateTime? createdAt,
  }) = _Character;

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);
}

@freezed
class Personality with _$Personality {
  const factory Personality({
    @Default(50) int warmth,        // 온기 (0-100)
    @Default(50) int competence,    // 유능함 (0-100)  
    @Default(50) int extroversion,  // 외향성 (0-100)
  }) = _Personality;

  factory Personality.fromJson(Map<String, dynamic> json) =>
      _$PersonalityFromJson(json);
}

enum OnboardingStep {
  intro,      // 서비스 소개
  input,      // 정보 입력
  photo,      // 사진 촬영
  generation, // AI 생성
  personality,// 성격 조정
  completion, // 완성 & QR
}

enum PersonalityType {
  warmth,
  competence,
  extroversion,
} 