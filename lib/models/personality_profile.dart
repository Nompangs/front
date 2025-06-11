class PersonalityProfile {
  final String aiPersonalityProfile;
  final String photoAnalysis;
  final String lifeStory;
  final String humorMatrix;
  final String attractiveFlaws;
  final String contradictions;
  final String communicationStyle;
  final String structuredPrompt;

  const PersonalityProfile({
    required this.aiPersonalityProfile,
    required this.photoAnalysis,
    required this.lifeStory,
    required this.humorMatrix,
    required this.attractiveFlaws,
    required this.contradictions,
    required this.communicationStyle,
    required this.structuredPrompt,
  });

  factory PersonalityProfile.empty() => const PersonalityProfile(
        aiPersonalityProfile: '',
        photoAnalysis: '',
        lifeStory: '',
        humorMatrix: '',
        attractiveFlaws: '',
        contradictions: '',
        communicationStyle: '',
        structuredPrompt: '',
      );

  Map<String, String> toMap() => {
        'aiPersonalityProfile': aiPersonalityProfile,
        'photoAnalysis': photoAnalysis,
        'lifeStory': lifeStory,
        'humorMatrix': humorMatrix,
        'attractiveFlaws': attractiveFlaws,
        'contradictions': contradictions,
        'communicationStyle': communicationStyle,
        'structuredPrompt': structuredPrompt,
      };
}
