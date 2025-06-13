// import 'package:nompangs/models/nps_scores.dart'; // 존재하지 않는 파일 임포트 제거

class PersonalityProfile {
  final AiPersonalityProfile? aiPersonalityProfile;
  final PhotoAnalysis? photoAnalysis;
  final LifeStory? lifeStory;
  final HumorMatrix? humorMatrix;
  final List<String> attractiveFlaws;
  final List<String> contradictions;
  final CommunicationStyle? communicationStyle;
  final String structuredPrompt;
  final String? uuid;
  final String? greeting;
  final String? initialUserMessage;

  PersonalityProfile({
    this.aiPersonalityProfile,
    this.photoAnalysis,
    this.lifeStory,
    this.humorMatrix,
    this.attractiveFlaws = const [],
    this.contradictions = const [],
    this.communicationStyle,
    this.structuredPrompt = '',
    this.uuid,
    this.greeting,
    this.initialUserMessage,
  });

  factory PersonalityProfile.empty() => PersonalityProfile(
        aiPersonalityProfile: AiPersonalityProfile.empty(),
        photoAnalysis: PhotoAnalysis.empty(),
        lifeStory: LifeStory.empty(),
        humorMatrix: HumorMatrix.empty(),
        attractiveFlaws: [],
        contradictions: [],
        communicationStyle: CommunicationStyle.empty(),
        structuredPrompt: '',
      );

  Map<String, dynamic> toMap() {
    return {
      'aiPersonalityProfile': aiPersonalityProfile?.toMap(),
      'photoAnalysis': photoAnalysis?.toMap(),
      'lifeStory': lifeStory?.toMap(),
      'humorMatrix': humorMatrix?.toMap(),
      'attractiveFlaws': attractiveFlaws,
      'contradictions': contradictions,
      'communicationStyle': communicationStyle?.toMap(),
      'structuredPrompt': structuredPrompt,
      'uuid': uuid,
      'greeting': greeting,
      'initialUserMessage': initialUserMessage,
    };
  }

  factory PersonalityProfile.fromMap(Map<String, dynamic> map) {
    return PersonalityProfile(
      aiPersonalityProfile: map['aiPersonalityProfile'] != null
          ? AiPersonalityProfile.fromMap(map['aiPersonalityProfile'] as Map<String, dynamic>)
          : null,
      photoAnalysis: map['photoAnalysis'] != null
          ? PhotoAnalysis.fromMap(map['photoAnalysis'] as Map<String, dynamic>)
          : null,
      lifeStory: map['lifeStory'] != null
          ? LifeStory.fromMap(map['lifeStory'] as Map<String, dynamic>)
          : null,
      humorMatrix: map['humorMatrix'] != null
          ? HumorMatrix.fromMap(map['humorMatrix'] as Map<String, dynamic>)
          : null,
      attractiveFlaws: List<String>.from((map['attractiveFlaws'] as List<dynamic>? ?? []).map((e) => e.toString())),
      contradictions: List<String>.from((map['contradictions'] as List<dynamic>? ?? []).map((e) => e.toString())),
      communicationStyle: map['communicationStyle'] != null
          ? CommunicationStyle.fromMap(map['communicationStyle'] as Map<String, dynamic>)
          : null,
      structuredPrompt: map['structuredPrompt'] as String? ?? '',
      uuid: map['uuid'] as String?,
      greeting: map['greeting'] as String?,
      initialUserMessage: map['initialUserMessage'] as String?,
    );
  }
}

class AiPersonalityProfile {
  final String name;
  final String objectType;
  final List<String> personalityTraits;
  final int emotionalRange;
  final List<String> coreValues;
  final String relationshipStyle;
  final String summary;
  final Map<String, int> npsScores; // NpsScores 타입을 Map<String, int>으로 변경

  AiPersonalityProfile({
    required this.name,
    required this.objectType,
    required this.personalityTraits,
    required this.emotionalRange,
    required this.coreValues,
    required this.relationshipStyle,
    required this.summary,
    this.npsScores = const {}, // 생성자 수정
  });

  factory AiPersonalityProfile.empty() => AiPersonalityProfile(
        name: '',
        objectType: '',
        personalityTraits: [],
        emotionalRange: 5,
        coreValues: [],
        relationshipStyle: '',
        summary: '',
        npsScores: {}, // NpsScores.empty() 대신 빈 Map 사용
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'objectType': objectType,
        'personalityTraits': personalityTraits,
        'emotionalRange': emotionalRange,
        'coreValues': coreValues,
        'relationshipStyle': relationshipStyle,
        'summary': summary,
        'npsScores': npsScores, // toMap() 대신 직접 전달
      };

  factory AiPersonalityProfile.fromMap(Map<String, dynamic> map) {
    return AiPersonalityProfile(
      name: map['name'] as String? ?? '',
      objectType: map['objectType'] as String? ?? '',
      personalityTraits: List<String>.from((map['personalityTraits'] as List<dynamic>? ?? []).map((e) => e.toString())),
      emotionalRange: map['emotionalRange'] as int? ?? 5,
      coreValues: List<String>.from((map['coreValues'] as List<dynamic>? ?? []).map((e) => e.toString())),
      relationshipStyle: map['relationshipStyle'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      npsScores: Map<String, int>.from(map['npsScores'] ?? {}), // NpsScores 파싱 로직 대신 Map 파싱
    );
  }
}

class PhotoAnalysis {
  final String objectType;
  final String visualDescription;
  final String location;
  final String condition;
  final String estimatedAge;
  final List<String> historicalSignificance;
  final List<String> culturalContext;

  PhotoAnalysis({
    required this.objectType,
    required this.visualDescription,
    required this.location,
    required this.condition,
    required this.estimatedAge,
    required this.historicalSignificance,
    required this.culturalContext,
  });

  factory PhotoAnalysis.empty() => PhotoAnalysis(
        objectType: '',
        visualDescription: '',
        location: '',
        condition: '',
        estimatedAge: '',
        historicalSignificance: [],
        culturalContext: [],
      );

  Map<String, dynamic> toMap() => {
        'objectType': objectType,
        'visualDescription': visualDescription,
        'location': location,
        'condition': condition,
        'estimatedAge': estimatedAge,
        'historicalSignificance': historicalSignificance,
        'culturalContext': culturalContext,
      };

  factory PhotoAnalysis.fromMap(Map<String, dynamic> map) {
    return PhotoAnalysis(
      objectType: map['objectType'] as String? ?? '',
      visualDescription: map['visualDescription'] as String? ?? '',
      location: map['location'] as String? ?? '',
      condition: map['condition'] as String? ?? '',
      estimatedAge: map['estimatedAge'] as String? ?? '',
      historicalSignificance: List<String>.from((map['historicalSignificance'] as List<dynamic>? ?? []).map((e) => e.toString())),
      culturalContext: List<String>.from((map['culturalContext'] as List<dynamic>? ?? []).map((e) => e.toString())),
    );
  }
}

class LifeStory {
  final String background;
  final List<String> keyEvents;
  final List<String> secretWishes;
  final List<String> innerComplaints;

  LifeStory({
    required this.background,
    required this.keyEvents,
    required this.secretWishes,
    required this.innerComplaints,
  });

  factory LifeStory.empty() => LifeStory(
        background: '',
        keyEvents: [],
        secretWishes: [],
        innerComplaints: [],
      );

  Map<String, dynamic> toMap() => {
        'background': background,
        'keyEvents': keyEvents,
        'secretWishes': secretWishes,
        'innerComplaints': innerComplaints,
      };

  factory LifeStory.fromMap(Map<String, dynamic> map) {
    return LifeStory(
      background: map['background'] as String? ?? '',
      keyEvents: List<String>.from((map['keyEvents'] as List<dynamic>? ?? []).map((e) => e.toString())),
      secretWishes: List<String>.from((map['secretWishes'] as List<dynamic>? ?? []).map((e) => e.toString())),
      innerComplaints: List<String>.from((map['innerComplaints'] as List<dynamic>? ?? []).map((e) => e.toString())),
    );
  }
}

class HumorMatrix {
  final String style;
  final String frequency;
  final List<String> topics;
  final List<String> avoidance;

  HumorMatrix({
    required this.style,
    required this.frequency,
    required this.topics,
    required this.avoidance,
  });

  factory HumorMatrix.empty() => HumorMatrix(
        style: '',
        frequency: '',
        topics: [],
        avoidance: [],
      );

  Map<String, dynamic> toMap() => {
        'style': style,
        'frequency': frequency,
        'topics': topics,
        'avoidance': avoidance,
      };

  factory HumorMatrix.fromMap(Map<String, dynamic> map) {
    return HumorMatrix(
      style: map['style'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      topics: List<String>.from((map['topics'] as List<dynamic>? ?? []).map((e) => e.toString())),
      avoidance: List<String>.from((map['avoidance'] as List<dynamic>? ?? []).map((e) => e.toString())),
    );
  }
}

class CommunicationStyle {
  final String tone;
  final String formality;
  final String responseLength;
  final List<String> preferredTopics;
  final String expressionStyle;

  CommunicationStyle({
    required this.tone,
    required this.formality,
    required this.responseLength,
    required this.preferredTopics,
    required this.expressionStyle,
  });

  factory CommunicationStyle.empty() => CommunicationStyle(
        tone: '',
        formality: '',
        responseLength: '',
        preferredTopics: [],
        expressionStyle: '',
      );

  Map<String, dynamic> toMap() => {
        'tone': tone,
        'formality': formality,
        'responseLength': responseLength,
        'preferredTopics': preferredTopics,
        'expressionStyle': expressionStyle,
      };

  factory CommunicationStyle.fromMap(Map<String, dynamic> map) {
    return CommunicationStyle(
      tone: map['tone'] as String? ?? '',
      formality: map['formality'] as String? ?? '',
      responseLength: map['responseLength'] as String? ?? '',
      preferredTopics: List<String>.from((map['preferredTopics'] as List<dynamic>? ?? []).map((e) => e.toString())),
      expressionStyle: map['expressionStyle'] as String? ?? '',
    );
  }
}
