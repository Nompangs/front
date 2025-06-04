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
    
    // 새로운 필드들 추가 (6단계 플로우에 맞춤)
    @Default("") String purpose,        // Step 3: 사물의 용도
    @Default("") String humorStyle,     // Step 3: 유머 스타일
    @Default(null) int? introversion,   // Step 6: 내외향성 (1-10)
    @Default(null) int? warmth,         // Step 6: 감정표현 (1-10)
    @Default(null) int? competence,     // Step 6: 유능함 (1-10)
    @Default(null) String? qrCodeUrl,   // 완료: QR 코드 URL
    @Default(null) FinalPersonality? finalPersonality, // 최종 성격
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

// 새로운 최종 성격 모델 (1-10 슬라이더용)
@freezed
class FinalPersonality with _$FinalPersonality {
  const factory FinalPersonality({
    required int introversion,  // 1(수줍음) ~ 10(활발함)
    required int warmth,        // 1(차가움) ~ 10(따뜻함)
    required int competence,    // 1(서툼) ~ 10(능숙함)
    @Default(false) bool userAdjusted, // 사용자가 수정했는지
  }) = _FinalPersonality;

  factory FinalPersonality.fromJson(Map<String, dynamic> json) =>
      _$FinalPersonalityFromJson(json);
}

enum OnboardingStep {
  intro,      // Step 1: 서비스 소개
  input,      // Step 2: 기본 정보 입력
  purpose,    // Step 3: 용도 + 유머스타일 입력 (새로 추가)
  photo,      // Step 4: 사진 촬영
  generation, // Step 5: AI 생성 (3단계 로딩)
  personality,// Step 6: 성격 조정 (3가지 슬라이더)
  completion, // 완료: QR 코드 + 완성
}

enum PersonalityType {
  warmth,
  competence,
  extroversion,
} 