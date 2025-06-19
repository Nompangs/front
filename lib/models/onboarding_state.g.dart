// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingStateImpl _$$OnboardingStateImplFromJson(
  Map<String, dynamic> json,
) => _$OnboardingStateImpl(
  nickname: json['nickname'] as String? ?? '',
  humorStyle: json['humorStyle'] as String? ?? '',
  purpose: json['purpose'] as String? ?? '',
  location: json['location'] as String? ?? '',
  duration: json['duration'] as String? ?? '',
  objectType: json['objectType'] as String? ?? '',
  photoPath: json['photoPath'] as String?,
  isLoading: json['isLoading'] as bool? ?? false,
  errorMessage: json['errorMessage'] as String? ?? null,
  isGenerating: json['isGenerating'] as bool? ?? false,
  generationProgress: (json['generationProgress'] as num?)?.toDouble() ?? 0.0,
  generationMessage: json['generationMessage'] as String? ?? '',
  warmth: (json['warmth'] as num?)?.toInt() ?? 5,
  competence: (json['competence'] as num?)?.toInt() ?? 5,
  extroversion: (json['extroversion'] as num?)?.toInt() ?? 5,
);

Map<String, dynamic> _$$OnboardingStateImplToJson(
  _$OnboardingStateImpl instance,
) => <String, dynamic>{
  'nickname': instance.nickname,
  'humorStyle': instance.humorStyle,
  'purpose': instance.purpose,
  'location': instance.location,
  'duration': instance.duration,
  'objectType': instance.objectType,
  'photoPath': instance.photoPath,
  'isLoading': instance.isLoading,
  'errorMessage': instance.errorMessage,
  'isGenerating': instance.isGenerating,
  'generationProgress': instance.generationProgress,
  'generationMessage': instance.generationMessage,
  'warmth': instance.warmth,
  'competence': instance.competence,
  'extroversion': instance.extroversion,
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
  extroversion: (json['extroversion'] as num).toInt(),
  warmth: (json['warmth'] as num).toInt(),
  competence: (json['competence'] as num).toInt(),
  userAdjusted: json['userAdjusted'] as bool? ?? false,
);

Map<String, dynamic> _$$FinalPersonalityImplToJson(
  _$FinalPersonalityImpl instance,
) => <String, dynamic>{
  'extroversion': instance.extroversion,
  'warmth': instance.warmth,
  'competence': instance.competence,
  'userAdjusted': instance.userAdjusted,
};
