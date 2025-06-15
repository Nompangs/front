// import 'package:nompangs/models/nps_scores.dart'; // 존재하지 않는 파일 임포트 제거

class PersonalityProfile {
  final AiPersonalityProfile? aiPersonalityProfile;
  final PhotoAnalysis? photoAnalysis;
  final HumorMatrix? humorMatrix;
  final List<String> attractiveFlaws;
  final List<String> contradictions;
  final String? greeting;
  final String? initialUserMessage;
  final String communicationPrompt;

  PersonalityProfile({
    this.aiPersonalityProfile,
    this.photoAnalysis,
    this.humorMatrix,
    this.attractiveFlaws = const [],
    required this.contradictions,
    this.greeting,
    this.initialUserMessage,
    this.communicationPrompt = '',
  });

  factory PersonalityProfile.empty() => PersonalityProfile(
        aiPersonalityProfile: AiPersonalityProfile.empty(),
        photoAnalysis: PhotoAnalysis.empty(),
        humorMatrix: HumorMatrix.empty(),
        attractiveFlaws: [],
        contradictions: [],
        greeting: null,
        initialUserMessage: null,
      );

  Map<String, dynamic> toMap() {
    return {
      'aiPersonalityProfile': aiPersonalityProfile?.toMap(),
      'photoAnalysis': photoAnalysis?.toMap(),
      'humorMatrix': humorMatrix?.toMap(),
      'attractiveFlaws': attractiveFlaws,
      'contradictions': contradictions,
      'greeting': greeting,
      'initialUserMessage': initialUserMessage,
      'communicationPrompt': communicationPrompt,
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
      humorMatrix: map['humorMatrix'] != null
          ? HumorMatrix.fromMap(map['humorMatrix'] as Map<String, dynamic>)
          : null,
      attractiveFlaws: List<String>.from((map['attractiveFlaws'] as List<dynamic>? ?? []).map((e) => e.toString())),
      contradictions: List<String>.from((map['contradictions'] as List<dynamic>? ?? []).map((e) => e.toString())),
      greeting: map['greeting'] as String?,
      initialUserMessage: map['initialUserMessage'] as String?,
      communicationPrompt: map['communicationPrompt'] as String? ?? '',
    );
  }
}

class AiPersonalityProfile {
  final String name;
  final String objectType;
  final int emotionalRange;
  final List<String> coreValues;
  final String relationshipStyle;
  final String summary;
  final Map<String, int> npsScores; // NpsScores 타입을 Map<String, int>으로 변경

  AiPersonalityProfile({
    required this.name,
    required this.objectType,
    required this.emotionalRange,
    required this.coreValues,
    required this.relationshipStyle,
    required this.summary,
    this.npsScores = const {}, // 생성자 수정
  });

  factory AiPersonalityProfile.empty() => AiPersonalityProfile(
        name: '',
        objectType: '',
        emotionalRange: 5,
        coreValues: [],
        relationshipStyle: '',
        summary: '',
        npsScores: {}, // NpsScores.empty() 대신 빈 Map 사용
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'objectType': objectType,
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

class HumorMatrix {
  final int warmthVsWit; // 0(순수 지적 위트) - 100(순수 따뜻한 유머)
  final int selfVsObservational; // 0(순수 관찰형) - 100(순수 자기참조형)
  final int subtleVsExpressive; // 0(미묘한 유머) - 100(표현적/과장된 유머)

  HumorMatrix({
    this.warmthVsWit = 50,
    this.selfVsObservational = 50,
    this.subtleVsExpressive = 50,
  });

  factory HumorMatrix.empty() => HumorMatrix();

  Map<String, dynamic> toMap() => {
    'warmthVsWit': warmthVsWit,
    'selfVsObservational': selfVsObservational,
    'subtleVsExpressive': subtleVsExpressive,
  };

  factory HumorMatrix.fromMap(Map<String, dynamic> map) {
    return HumorMatrix(
      warmthVsWit: map['warmthVsWit'] as int? ?? 50,
      selfVsObservational: map['selfVsObservational'] as int? ?? 50,
      subtleVsExpressive: map['subtleVsExpressive'] as int? ?? 50,
    );
  }
}
