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
  final String? photoPath;
  final String? uuid;
  final Map<String, dynamic>? realtimeSettings;
  final Map<String, dynamic>? userInput;
  // 🆕 AI 생성 추가 필드들
  final List<String> coreTraits;
  final String personalityDescription;
  final String? imageUrl;
  final String? persona;
  final List<String>? coreValues;

  PersonalityProfile({
    this.aiPersonalityProfile,
    this.photoAnalysis,
    this.humorMatrix,
    this.attractiveFlaws = const [],
    required this.contradictions,
    this.greeting,
    this.initialUserMessage,
    this.communicationPrompt = '',
    this.photoPath,
    this.uuid,
    this.realtimeSettings,
    this.userInput,
    // 🆕 AI 생성 추가 필드들
    this.coreTraits = const [],
    this.personalityDescription = '',
    this.imageUrl,
    this.persona,
    this.coreValues,
  });

  PersonalityProfile copyWith({
    AiPersonalityProfile? aiPersonalityProfile,
    PhotoAnalysis? photoAnalysis,
    HumorMatrix? humorMatrix,
    List<String>? attractiveFlaws,
    List<String>? contradictions,
    String? greeting,
    String? initialUserMessage,
    String? communicationPrompt,
    String? photoPath,
    String? uuid,
    Map<String, dynamic>? realtimeSettings,
    Map<String, dynamic>? userInput,
    List<String>? coreTraits,
    String? personalityDescription,
    String? imageUrl,
    String? persona,
    List<String>? coreValues,
  }) {
    return PersonalityProfile(
      aiPersonalityProfile: aiPersonalityProfile ?? this.aiPersonalityProfile,
      photoAnalysis: photoAnalysis ?? this.photoAnalysis,
      humorMatrix: humorMatrix ?? this.humorMatrix,
      attractiveFlaws: attractiveFlaws ?? this.attractiveFlaws,
      contradictions: contradictions ?? this.contradictions,
      greeting: greeting ?? this.greeting,
      initialUserMessage: initialUserMessage ?? this.initialUserMessage,
      communicationPrompt: communicationPrompt ?? this.communicationPrompt,
      photoPath: photoPath ?? this.photoPath,
      uuid: uuid ?? this.uuid,
      realtimeSettings: realtimeSettings ?? this.realtimeSettings,
      userInput: userInput ?? this.userInput,
      coreTraits: coreTraits ?? this.coreTraits,
      personalityDescription:
          personalityDescription ?? this.personalityDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      persona: persona ?? this.persona,
      coreValues: coreValues ?? this.coreValues,
    );
  }

  factory PersonalityProfile.empty() => PersonalityProfile(
    aiPersonalityProfile: AiPersonalityProfile.empty(),
    photoAnalysis: PhotoAnalysis.empty(),
    humorMatrix: HumorMatrix.empty(),
    attractiveFlaws: [],
    contradictions: [],
    greeting: null,
    initialUserMessage: null,
    photoPath: null,
    uuid: null,
    realtimeSettings: null,
    userInput: null,
    coreTraits: [],
    personalityDescription: '',
    imageUrl: null,
    persona: null,
    coreValues: null,
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
      'uuid': uuid,
      'realtimeSettings': realtimeSettings,
      'userInput': userInput,
      'coreTraits': coreTraits,
      'personalityDescription': personalityDescription,
      'imageUrl': imageUrl,
      'persona': persona,
      'coreValues': coreValues,
    };
  }

  factory PersonalityProfile.fromMap(Map<String, dynamic> map) {
    final aiProfile = map['aiPersonalityProfile'] as Map<String, dynamic>?;
    final imageUrl =
        map['imageUrl'] as String? ?? aiProfile?['imageUrl'] as String?;

    return PersonalityProfile(
      aiPersonalityProfile:
          aiProfile != null ? AiPersonalityProfile.fromMap(aiProfile) : null,
      photoAnalysis:
          map['photoAnalysis'] != null
              ? PhotoAnalysis.fromMap(
                map['photoAnalysis'] as Map<String, dynamic>,
              )
              : null,
      humorMatrix:
          map['humorMatrix'] != null
              ? HumorMatrix.fromMap(map['humorMatrix'] as Map<String, dynamic>)
              : null,
      attractiveFlaws: List<String>.from(
        (map['attractiveFlaws'] as List<dynamic>? ?? []).map(
          (e) => e.toString(),
        ),
      ),
      contradictions: List<String>.from(
        (map['contradictions'] as List<dynamic>? ?? []).map(
          (e) => e.toString(),
        ),
      ),
      greeting: map['greeting'] as String?,
      initialUserMessage: map['initialUserMessage'] as String?,
      communicationPrompt: map['communicationPrompt'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      uuid: map['uuid'] as String?,
      realtimeSettings: map['realtimeSettings'] as Map<String, dynamic>?,
      userInput: map['userInput'] as Map<String, dynamic>?,
      coreTraits: List<String>.from(
        (map['coreTraits'] as List<dynamic>? ?? []).map((e) => e.toString()),
      ),
      personalityDescription: map['personalityDescription'] as String? ?? '',
      imageUrl: imageUrl,
      persona: map['persona'] as String?,
      coreValues:
          map['coreValues'] != null && map['coreValues'] is List
              ? List<String>.from(map['coreValues'])
              : null,
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
      coreValues: List<String>.from(
        (map['coreValues'] as List<dynamic>? ?? []).map((e) => e.toString()),
      ),
      relationshipStyle: map['relationshipStyle'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      npsScores: Map<String, int>.from(
        map['npsScores'] ?? {},
      ), // NpsScores 파싱 로직 대신 Map 파싱
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
      historicalSignificance: List<String>.from(
        (map['historicalSignificance'] as List<dynamic>? ?? []).map(
          (e) => e.toString(),
        ),
      ),
      culturalContext: List<String>.from(
        (map['culturalContext'] as List<dynamic>? ?? []).map(
          (e) => e.toString(),
        ),
      ),
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
