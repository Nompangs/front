// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingStateImpl _$$OnboardingStateImplFromJson(
  Map<String, dynamic> json,
) => _$OnboardingStateImpl(
  currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
  userInput:
      json['userInput'] == null
          ? null
          : UserInput.fromJson(json['userInput'] as Map<String, dynamic>),
  photoPath: json['photoPath'] as String? ?? null,
  generatedCharacter:
      json['generatedCharacter'] == null
          ? null
          : Character.fromJson(
            json['generatedCharacter'] as Map<String, dynamic>,
          ),
  isLoading: json['isLoading'] as bool? ?? false,
  errorMessage: json['errorMessage'] as String? ?? null,
  isGenerating: json['isGenerating'] as bool? ?? false,
  generationProgress: (json['generationProgress'] as num?)?.toDouble() ?? 0.0,
  generationMessage: json['generationMessage'] as String? ?? "",
  purpose: json['purpose'] as String? ?? "",
  humorStyle: json['humorStyle'] as String? ?? "",
  introversion: (json['introversion'] as num?)?.toInt() ?? null,
  warmth: (json['warmth'] as num?)?.toInt() ?? null,
  competence: (json['competence'] as num?)?.toInt() ?? null,
  qrCodeUrl: json['qrCodeUrl'] as String? ?? null,
  finalPersonality:
      json['finalPersonality'] == null
          ? null
          : FinalPersonality.fromJson(
            json['finalPersonality'] as Map<String, dynamic>,
          ),
);

Map<String, dynamic> _$$OnboardingStateImplToJson(
  _$OnboardingStateImpl instance,
) => <String, dynamic>{
  'currentStep': instance.currentStep,
  'userInput': instance.userInput,
  'photoPath': instance.photoPath,
  'generatedCharacter': instance.generatedCharacter,
  'isLoading': instance.isLoading,
  'errorMessage': instance.errorMessage,
  'isGenerating': instance.isGenerating,
  'generationProgress': instance.generationProgress,
  'generationMessage': instance.generationMessage,
  'purpose': instance.purpose,
  'humorStyle': instance.humorStyle,
  'introversion': instance.introversion,
  'warmth': instance.warmth,
  'competence': instance.competence,
  'qrCodeUrl': instance.qrCodeUrl,
  'finalPersonality': instance.finalPersonality,
};

_$UserInputImpl _$$UserInputImplFromJson(Map<String, dynamic> json) =>
    _$UserInputImpl(
      nickname: json['nickname'] as String,
      location: json['location'] as String,
      duration: json['duration'] as String,
      objectType: json['objectType'] as String,
      additionalInfo: json['additionalInfo'] as String? ?? "",
    );

Map<String, dynamic> _$$UserInputImplToJson(_$UserInputImpl instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
      'location': instance.location,
      'duration': instance.duration,
      'objectType': instance.objectType,
      'additionalInfo': instance.additionalInfo,
    };

_$CharacterImpl _$$CharacterImplFromJson(Map<String, dynamic> json) =>
    _$CharacterImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      objectType: json['objectType'] as String,
      personality: Personality.fromJson(
        json['personality'] as Map<String, dynamic>,
      ),
      greeting: json['greeting'] as String,
      traits:
          (json['traits'] as List<dynamic>).map((e) => e as String).toList(),
      systemPrompt: json['systemPrompt'] as String? ?? "",
      qrCode: json['qrCode'] as String? ?? "",
      createdAt:
          json['createdAt'] == null
              ? null
              : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CharacterImplToJson(_$CharacterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'objectType': instance.objectType,
      'personality': instance.personality,
      'greeting': instance.greeting,
      'traits': instance.traits,
      'systemPrompt': instance.systemPrompt,
      'qrCode': instance.qrCode,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$PersonalityImpl _$$PersonalityImplFromJson(Map<String, dynamic> json) =>
    _$PersonalityImpl(
      warmth: (json['warmth'] as num?)?.toInt() ?? 50,
      competence: (json['competence'] as num?)?.toInt() ?? 50,
      extroversion: (json['extroversion'] as num?)?.toInt() ?? 50,
    );

Map<String, dynamic> _$$PersonalityImplToJson(_$PersonalityImpl instance) =>
    <String, dynamic>{
      'warmth': instance.warmth,
      'competence': instance.competence,
      'extroversion': instance.extroversion,
    };

_$FinalPersonalityImpl _$$FinalPersonalityImplFromJson(
  Map<String, dynamic> json,
) => _$FinalPersonalityImpl(
  introversion: (json['introversion'] as num).toInt(),
  warmth: (json['warmth'] as num).toInt(),
  competence: (json['competence'] as num).toInt(),
  userAdjusted: json['userAdjusted'] as bool? ?? false,
);

Map<String, dynamic> _$$FinalPersonalityImplToJson(
  _$FinalPersonalityImpl instance,
) => <String, dynamic>{
  'introversion': instance.introversion,
  'warmth': instance.warmth,
  'competence': instance.competence,
  'userAdjusted': instance.userAdjusted,
};
