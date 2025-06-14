import 'dart:math';

/// 3가지 핵심 특성(온기, 능력, 외내향성)을 기반으로 127개 성격 변수를 자동 연동하는 서비스
class PersonalityVariablesService {
  static final Random _random = Random();

  /// 3가지 핵심 특성을 기반으로 127개 성격 변수 생성
  static Map<String, double> generatePersonalityVariables({
    required double warmth, // 0-10
    required double competence, // 0-10
    required double introversion, // 0-10 (높을수록 내향적)
  }) {
    // 0-10을 0-100으로 변환
    final warmthScore = warmth * 10;
    final competenceScore = competence * 10;
    final extraversionScore = (10 - introversion) * 10; // 내향성을 외향성으로 변환

    final variables = <String, double>{};

    // 1. 기본 온기-능력 차원 (20개 지표)
    _generateWarmthVariables(variables, warmthScore);
    _generateCompetenceVariables(variables, competenceScore);

    // 2. 빅5 성격 특성 확장 (30개 지표)
    _generateExtraversionVariables(variables, extraversionScore);
    _generateAgreeablenessVariables(variables, warmthScore, competenceScore);
    _generateConscientiousnessVariables(variables, competenceScore);
    _generateNeuroticismVariables(variables, warmthScore, extraversionScore);
    _generateOpennessVariables(variables, competenceScore, extraversionScore);

    // 3. 매력적 결함 차원 (25개 지표)
    _generateAttractiveFlawsVariables(
      variables,
      warmthScore,
      competenceScore,
      extraversionScore,
    );
    _generateContradictionVariables(
      variables,
      warmthScore,
      competenceScore,
      extraversionScore,
    );

    // 4. 소통 스타일 차원 (20개 지표)
    _generateCommunicationStyleVariables(
      variables,
      warmthScore,
      extraversionScore,
    );
    _generateHumorStyleVariables(
      variables,
      warmthScore,
      competenceScore,
      extraversionScore,
    );

    // 5. 관계 형성 차원 (20개 지표)
    _generateAttachmentStyleVariables(
      variables,
      warmthScore,
      extraversionScore,
    );
    _generateRelationshipDevelopmentVariables(
      variables,
      warmthScore,
      competenceScore,
      extraversionScore,
    );

    // 6. 사물 특성 기반 감정 차원 (24개 지표)
    _generateObjectPurposeVariables(variables, competenceScore);
    _generateFormCharacteristicsVariables(
      variables,
      warmthScore,
      competenceScore,
    );
    _generateInteractionPatternVariables(
      variables,
      warmthScore,
      extraversionScore,
    );

    // 7. 독특한 개성 차원 (12개 지표)
    _generateCulturalIdentityVariables(
      variables,
      warmthScore,
      extraversionScore,
    );
    _generateUniquePersonalityVariables(
      variables,
      competenceScore,
      extraversionScore,
    );

    return variables;
  }

  /// 온기 관련 변수 생성 (W로 시작)
  static void _generateWarmthVariables(
    Map<String, double> variables,
    double warmth,
  ) {
    variables["W01_친절함"] = _clamp(warmth + _randomVariation(-10, 10));
    variables["W02_친근함"] = _clamp(warmth + _randomVariation(-15, 15));
    variables["W03_진실성"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["W04_신뢰성"] = _clamp(warmth + _randomVariation(-15, 15));
    variables["W05_수용성"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["W06_공감능력"] = _clamp(warmth + _randomVariation(-10, 10));
    variables["W07_포용력"] = _clamp(warmth + _randomVariation(-15, 15));
    variables["W08_격려성향"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["W09_친밀감표현"] = _clamp(warmth + _randomVariation(-25, 25));
    variables["W10_무조건적수용"] = _clamp(warmth + _randomVariation(-30, 30));
  }

  /// 능력 관련 변수 생성 (C로 시작)
  static void _generateCompetenceVariables(
    Map<String, double> variables,
    double competence,
  ) {
    variables["C01_효율성"] = _clamp(competence + _randomVariation(-15, 15));
    variables["C02_지능"] = _clamp(competence + _randomVariation(-10, 10));
    variables["C03_전문성"] = _clamp(competence + _randomVariation(-20, 20));
    variables["C04_창의성"] = _clamp(competence + _randomVariation(-25, 25));
    variables["C05_정확성"] = _clamp(competence + _randomVariation(-15, 15));
    variables["C06_분석력"] = _clamp(competence + _randomVariation(-20, 20));
    variables["C07_학습능력"] = _clamp(competence + _randomVariation(-15, 15));
    variables["C08_통찰력"] = _clamp(competence + _randomVariation(-25, 25));
    variables["C09_실행력"] = _clamp(competence + _randomVariation(-20, 20));
    variables["C10_적응력"] = _clamp(competence + _randomVariation(-15, 15));
  }

  /// 외향성 관련 변수 생성 (E로 시작)
  static void _generateExtraversionVariables(
    Map<String, double> variables,
    double extraversion,
  ) {
    variables["E01_사교성"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["E02_활동성"] = _clamp(extraversion + _randomVariation(-20, 20));
    variables["E03_자기주장"] = _clamp(extraversion + _randomVariation(-25, 25));
    variables["E04_긍정정서"] = _clamp(extraversion + _randomVariation(-20, 20));
    variables["E05_자극추구"] = _clamp(extraversion + _randomVariation(-30, 30));
    variables["E06_열정성"] = _clamp(extraversion + _randomVariation(-20, 20));
  }

  /// 친화성 관련 변수 생성 (A로 시작)
  static void _generateAgreeablenessVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
  ) {
    final agreeableness = (warmth * 0.7 + competence * 0.3);
    variables["A01_신뢰"] = _clamp(agreeableness + _randomVariation(-15, 15));
    variables["A02_솔직함"] = _clamp(agreeableness + _randomVariation(-20, 20));
    variables["A03_이타심"] = _clamp(warmth + _randomVariation(-15, 15));
    variables["A04_순응성"] = _clamp(agreeableness + _randomVariation(-25, 25));
    variables["A05_겸손함"] = _clamp(
      100 - competence * 0.5 + _randomVariation(-20, 20),
    );
    variables["A06_공감민감성"] = _clamp(warmth + _randomVariation(-10, 10));
  }

  /// 성실성 관련 변수 생성 (C11-C16)
  static void _generateConscientiousnessVariables(
    Map<String, double> variables,
    double competence,
  ) {
    variables["C11_유능감"] = _clamp(competence + _randomVariation(-10, 10));
    variables["C12_질서성"] = _clamp(competence + _randomVariation(-20, 20));
    variables["C13_충실함"] = _clamp(competence + _randomVariation(-15, 15));
    variables["C14_성취욕구"] = _clamp(competence + _randomVariation(-15, 15));
    variables["C15_자기규율"] = _clamp(competence + _randomVariation(-20, 20));
    variables["C16_신중함"] = _clamp(competence + _randomVariation(-25, 25));
  }

  /// 신경증 관련 변수 생성 (N로 시작)
  static void _generateNeuroticismVariables(
    Map<String, double> variables,
    double warmth,
    double extraversion,
  ) {
    final stability = (warmth + extraversion) / 2;
    final neuroticism = 100 - stability;
    variables["N01_불안성"] = _clamp(neuroticism + _randomVariation(-20, 20));
    variables["N02_분노성"] = _clamp(neuroticism + _randomVariation(-25, 25));
    variables["N03_우울성"] = _clamp(neuroticism + _randomVariation(-20, 20));
    variables["N04_자의식"] = _clamp(neuroticism + _randomVariation(-15, 15));
    variables["N05_충동성"] = _clamp(neuroticism + _randomVariation(-30, 30));
    variables["N06_스트레스취약성"] = _clamp(neuroticism + _randomVariation(-20, 20));
  }

  /// 개방성 관련 변수 생성 (O로 시작)
  static void _generateOpennessVariables(
    Map<String, double> variables,
    double competence,
    double extraversion,
  ) {
    final openness = (competence * 0.6 + extraversion * 0.4);
    variables["O01_상상력"] = _clamp(openness + _randomVariation(-25, 25));
    variables["O02_심미성"] = _clamp(openness + _randomVariation(-20, 20));
    variables["O03_감정개방성"] = _clamp(openness + _randomVariation(-20, 20));
    variables["O04_행동개방성"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["O05_사고개방성"] = _clamp(competence + _randomVariation(-15, 15));
    variables["O06_가치개방성"] = _clamp(openness + _randomVariation(-25, 25));
  }

  /// 매력적 결함 관련 변수 생성 (F로 시작)
  static void _generateAttractiveFlawsVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
    double extraversion,
  ) {
    // 높은 능력일수록 완벽주의 불안 증가
    variables["F01_완벽주의불안"] = _clamp(
      competence * 0.3 + _randomVariation(0, 20),
    );
    variables["F02_방향감각부족"] = _clamp(
      30 - competence * 0.2 + _randomVariation(0, 15),
    );
    variables["F03_기술치음"] = _clamp(
      40 - competence * 0.3 + _randomVariation(0, 20),
    );
    variables["F04_우유부단함"] = _clamp(
      50 - extraversion * 0.2 + _randomVariation(0, 20),
    );
    variables["F05_과도한걱정"] = _clamp(
      60 - warmth * 0.1 + _randomVariation(0, 25),
    );
    variables["F06_감정기복"] = _clamp(
      40 + (100 - extraversion) * 0.1 + _randomVariation(0, 15),
    );
    variables["F07_산만함"] = _clamp(
      30 + extraversion * 0.1 + _randomVariation(0, 15),
    );
    variables["F08_고집스러움"] = _clamp(competence * 0.2 + _randomVariation(0, 20));
    variables["F09_예민함"] = _clamp(warmth * 0.2 + _randomVariation(0, 20));
    variables["F10_느림"] = _clamp(
      40 - extraversion * 0.2 + _randomVariation(0, 15),
    );
    variables["F11_소심함"] = _clamp(
      60 - extraversion * 0.3 + _randomVariation(0, 20),
    );
    variables["F12_잘못된자신감"] = _clamp(
      extraversion * 0.15 + _randomVariation(0, 15),
    );
    variables["F13_과거집착"] = _clamp(
      50 - competence * 0.1 + _randomVariation(0, 20),
    );
    variables["F14_변화거부"] = _clamp(
      60 - extraversion * 0.2 + _randomVariation(0, 20),
    );
    variables["F15_표현서툼"] = _clamp(50 - warmth * 0.2 + _randomVariation(0, 15));
  }

  /// 모순적 특성 관련 변수 생성 (P로 시작)
  static void _generateContradictionVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
    double extraversion,
  ) {
    variables["P01_외면내면대비"] = _clamp(
      abs(extraversion - warmth) * 0.5 + _randomVariation(10, 30),
    );
    variables["P02_상황별변화"] = _clamp(30 + _randomVariation(0, 25));
    variables["P03_가치관충돌"] = _clamp(
      abs(warmth - competence) * 0.3 + _randomVariation(5, 20),
    );
    variables["P04_시간대별차이"] = _clamp(20 + _randomVariation(0, 20));
    variables["P05_논리감정대립"] = _clamp(
      abs(competence - warmth) * 0.4 + _randomVariation(10, 25),
    );
    variables["P06_독립의존모순"] = _clamp(
      abs(extraversion - 50) * 0.3 + _randomVariation(5, 20),
    );
    variables["P07_보수혁신양면"] = _clamp(
      abs(competence - extraversion) * 0.3 + _randomVariation(10, 25),
    );
    variables["P08_활동정적대비"] = _clamp(
      abs(extraversion - 50) * 0.4 + _randomVariation(10, 25),
    );
    variables["P09_사교내향혼재"] = _clamp(
      abs(extraversion - 50) * 0.5 + _randomVariation(15, 30),
    );
    variables["P10_자신감불안공존"] = _clamp(
      abs(competence - warmth) * 0.3 + _randomVariation(5, 20),
    );
  }

  /// 소통 스타일 관련 변수 생성 (S로 시작)
  static void _generateCommunicationStyleVariables(
    Map<String, double> variables,
    double warmth,
    double extraversion,
  ) {
    final communicationBase = (warmth + extraversion) / 2;
    variables["S01_격식성수준"] = _clamp(
      100 - communicationBase + _randomVariation(-20, 20),
    );
    variables["S02_직접성정도"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["S03_어휘복잡성"] = _clamp(
      communicationBase + _randomVariation(-20, 20),
    );
    variables["S04_문장길이선호"] = _clamp(
      communicationBase + _randomVariation(-25, 25),
    );
    variables["S05_은유사용빈도"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["S06_감탄사사용"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["S07_질문형태선호"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["S08_반복표현패턴"] = _clamp(50 + _randomVariation(-25, 25));
    variables["S09_방언사용정도"] = _clamp(
      extraversion * 0.7 + _randomVariation(-20, 20),
    );
    variables["S10_신조어수용성"] = _clamp(extraversion + _randomVariation(-20, 20));
  }

  /// 유머 스타일 관련 변수 생성 (H로 시작)
  static void _generateHumorStyleVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
    double extraversion,
  ) {
    final humorBase = (warmth + extraversion) / 2;
    variables["H01_언어유희빈도"] = _clamp(
      competence * 0.7 + extraversion * 0.3 + _randomVariation(-15, 15),
    );
    variables["H02_상황유머감각"] = _clamp(humorBase + _randomVariation(-20, 20));
    variables["H03_자기비하정도"] = _clamp(
      60 - competence * 0.3 + _randomVariation(-15, 15),
    );
    variables["H04_위트반응속도"] = _clamp(
      competence * 0.6 + extraversion * 0.4 + _randomVariation(-15, 15),
    );
    variables["H05_아이러니사용"] = _clamp(competence + _randomVariation(-20, 20));
    variables["H06_관찰유머능력"] = _clamp(
      competence * 0.5 + warmth * 0.5 + _randomVariation(-15, 15),
    );
    variables["H07_패러디창작성"] = _clamp(
      competence * 0.7 + extraversion * 0.3 + _randomVariation(-20, 20),
    );
    variables["H08_유머타이밍감"] = _clamp(humorBase + _randomVariation(-15, 15));
    variables["H09_블랙유머수준"] = _clamp(
      competence * 0.6 + (100 - warmth) * 0.4 + _randomVariation(-20, 20),
    );
    variables["H10_문화유머이해"] = _clamp(
      competence * 0.8 + extraversion * 0.2 + _randomVariation(-15, 15),
    );
  }

  /// 애착 스타일 관련 변수 생성 (R로 시작)
  static void _generateAttachmentStyleVariables(
    Map<String, double> variables,
    double warmth,
    double extraversion,
  ) {
    final securityBase = (warmth + extraversion) / 2;
    variables["R01_안정애착성향"] = _clamp(securityBase + _randomVariation(-15, 15));
    variables["R02_불안애착성향"] = _clamp(
      100 - securityBase + _randomVariation(-20, 20),
    );
    variables["R03_회피애착성향"] = _clamp(100 - warmth + _randomVariation(-15, 15));
    variables["R04_의존성수준"] = _clamp(
      100 - extraversion + _randomVariation(-20, 20),
    );
    variables["R05_독립성추구"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["R06_친밀감수용도"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["R07_경계설정능력"] = _clamp(
      extraversion * 0.7 + warmth * 0.3 + _randomVariation(-15, 15),
    );
    variables["R08_갈등해결방식"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["R09_신뢰구축속도"] = _clamp(
      warmth * 0.6 + extraversion * 0.4 + _randomVariation(-15, 15),
    );
    variables["R10_배신경험영향"] = _clamp(
      60 - warmth * 0.3 + _randomVariation(-20, 20),
    );
  }

  /// 관계 발전 관련 변수 생성 (D로 시작)
  static void _generateRelationshipDevelopmentVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
    double extraversion,
  ) {
    variables["D01_초기접근성"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["D02_자기개방속도"] = _clamp(
      warmth * 0.7 + extraversion * 0.3 + _randomVariation(-20, 20),
    );
    variables["D03_호기심표현도"] = _clamp(extraversion + _randomVariation(-15, 15));
    variables["D04_공감반응강도"] = _clamp(warmth + _randomVariation(-10, 10));
    variables["D05_기억보존능력"] = _clamp(competence + _randomVariation(-15, 15));
    variables["D06_예측가능성"] = _clamp(
      competence * 0.7 + warmth * 0.3 + _randomVariation(-20, 20),
    );
    variables["D07_놀라움제공능력"] = _clamp(
      extraversion * 0.6 + competence * 0.4 + _randomVariation(-20, 20),
    );
    variables["D08_취약성공유도"] = _clamp(warmth + _randomVariation(-25, 25));
    variables["D09_성장추진력"] = _clamp(
      competence * 0.8 + extraversion * 0.2 + _randomVariation(-15, 15),
    );
    variables["D10_이별수용능력"] = _clamp(
      competence * 0.6 + warmth * 0.4 + _randomVariation(-20, 20),
    );
  }

  /// 사물 목적 관련 변수 생성 (OBJ로 시작)
  static void _generateObjectPurposeVariables(
    Map<String, double> variables,
    double competence,
  ) {
    variables["OBJ01_존재목적만족도"] = _clamp(competence + _randomVariation(-15, 15));
    variables["OBJ02_사용자기여감"] = _clamp(competence + _randomVariation(-20, 20));
    variables["OBJ03_역할정체성자부심"] = _clamp(
      competence + _randomVariation(-15, 15),
    );
    variables["OBJ04_기능완성도추구"] = _clamp(competence + _randomVariation(-10, 10));
    variables["OBJ05_무용감극복의지"] = _clamp(competence + _randomVariation(-25, 25));
    variables["OBJ06_성능개선욕구"] = _clamp(competence + _randomVariation(-20, 20));
    variables["OBJ07_사용빈도만족도"] = _clamp(
      competence * 0.8 + _randomVariation(-20, 20),
    );
    variables["OBJ08_대체불안감"] = _clamp(
      70 - competence * 0.3 + _randomVariation(-15, 15),
    );
  }

  /// 형태 특성 관련 변수 생성 (FORM으로 시작)
  static void _generateFormCharacteristicsVariables(
    Map<String, double> variables,
    double warmth,
    double competence,
  ) {
    variables["FORM01_크기자각정도"] = _clamp(competence + _randomVariation(-20, 20));
    variables["FORM02_재질특성자부심"] = _clamp(
      competence + _randomVariation(-15, 15),
    );
    variables["FORM03_색상표현력"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["FORM04_디자인심미감"] = _clamp(
      (warmth + competence) / 2 + _randomVariation(-15, 15),
    );
    variables["FORM05_내구성자신감"] = _clamp(competence + _randomVariation(-15, 15));
    variables["FORM06_공간점유의식"] = _clamp(
      competence * 0.7 + _randomVariation(-20, 20),
    );
    variables["FORM07_이동성적응력"] = _clamp(competence + _randomVariation(-25, 25));
    variables["FORM08_마모흔적수용도"] = _clamp(warmth + _randomVariation(-20, 20));
  }

  /// 상호작용 패턴 관련 변수 생성 (INT로 시작)
  static void _generateInteractionPatternVariables(
    Map<String, double> variables,
    double warmth,
    double extraversion,
  ) {
    variables["INT01_터치반응민감도"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["INT02_사용압력인내력"] = _clamp(
      warmth * 0.6 + extraversion * 0.4 + _randomVariation(-15, 15),
    );
    variables["INT03_방치시간적응력"] = _clamp(
      70 - extraversion * 0.3 + _randomVariation(-20, 20),
    );
    variables["INT04_청소반응태도"] = _clamp(warmth + _randomVariation(-15, 15));
    variables["INT05_다른사물과협력성"] = _clamp(
      warmth * 0.7 + extraversion * 0.3 + _randomVariation(-15, 15),
    );
    variables["INT06_환경변화적응성"] = _clamp(
      extraversion + _randomVariation(-20, 20),
    );
    variables["INT07_고장시대처능력"] = _clamp(
      warmth * 0.6 + extraversion * 0.4 + _randomVariation(-20, 20),
    );
    variables["INT08_업그레이드수용성"] = _clamp(
      extraversion + _randomVariation(-15, 15),
    );
  }

  /// 문화적 정체성 관련 변수 생성 (U로 시작)
  static void _generateCulturalIdentityVariables(
    Map<String, double> variables,
    double warmth,
    double extraversion,
  ) {
    variables["U01_한국적정서"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["U02_세대특성반영"] = _clamp(extraversion + _randomVariation(-20, 20));
    variables["U03_지역성표현"] = _clamp(warmth * 0.7 + _randomVariation(-25, 25));
    variables["U04_전통가치계승"] = _clamp(
      60 - extraversion * 0.2 + _randomVariation(-20, 20),
    );
    variables["U05_계절감수성"] = _clamp(warmth + _randomVariation(-20, 20));
    variables["U06_음식문화이해"] = _clamp(
      warmth * 0.8 + extraversion * 0.2 + _randomVariation(-15, 15),
    );
  }

  /// 개인 고유성 관련 변수 생성 (P11-P16)
  static void _generateUniquePersonalityVariables(
    Map<String, double> variables,
    double competence,
    double extraversion,
  ) {
    variables["P11_특이한관심사"] = _clamp(
      competence * 0.6 + extraversion * 0.4 + _randomVariation(-20, 20),
    );
    variables["P12_언어버릇"] = _clamp(extraversion + _randomVariation(-25, 25));
    variables["P13_사고패턴독특성"] = _clamp(competence + _randomVariation(-20, 20));
    variables["P14_감정표현방식"] = _clamp(extraversion + _randomVariation(-20, 20));
    variables["P15_가치관고유성"] = _clamp(
      competence * 0.7 + extraversion * 0.3 + _randomVariation(-15, 15),
    );
    variables["P16_행동패턴특이성"] = _clamp(extraversion + _randomVariation(-25, 25));
  }

  /// 값을 0-100 범위로 제한
  static double _clamp(double value) {
    return value.clamp(0.0, 100.0);
  }

  /// 랜덤 변동값 생성
  static double _randomVariation(int min, int max) {
    return min + _random.nextDouble() * (max - min);
  }

  /// 절댓값 계산
  static double abs(double value) {
    return value < 0 ? -value : value;
  }

  /// 성격 변수를 카테고리별로 분류
  static Map<String, Map<String, double>> categorizeVariables(
    Map<String, double> personalityVariables,
  ) {
    final categories = <String, Map<String, double>>{
      '온기차원': {},
      '능력차원': {},
      '외향성차원': {},
      '친화성차원': {},
      '성실성차원': {},
      '신경증차원': {},
      '개방성차원': {},
      '매력적결함': {},
      '모순적특성': {},
      '소통스타일': {},
      '유머스타일': {},
      '애착스타일': {},
      '관계발전': {},
      '사물목적': {},
      '형태특성': {},
      '상호작용': {},
      '문화정체성': {},
      '개인고유성': {},
    };

    personalityVariables.forEach((key, value) {
      if (key.startsWith('W')) {
        categories['온기차원']![key] = value;
      } else if (key.startsWith('C') && !key.startsWith('C1')) {
        categories['능력차원']![key] = value;
      } else if (key.startsWith('E')) {
        categories['외향성차원']![key] = value;
      } else if (key.startsWith('A')) {
        categories['친화성차원']![key] = value;
      } else if (key.startsWith('C1')) {
        categories['성실성차원']![key] = value;
      } else if (key.startsWith('N')) {
        categories['신경증차원']![key] = value;
      } else if (key.startsWith('O')) {
        categories['개방성차원']![key] = value;
      } else if (key.startsWith('F')) {
        categories['매력적결함']![key] = value;
      } else if (key.startsWith('P') && key.length <= 3) {
        categories['모순적특성']![key] = value;
      } else if (key.startsWith('S')) {
        categories['소통스타일']![key] = value;
      } else if (key.startsWith('H')) {
        categories['유머스타일']![key] = value;
      } else if (key.startsWith('R')) {
        categories['애착스타일']![key] = value;
      } else if (key.startsWith('D')) {
        categories['관계발전']![key] = value;
      } else if (key.startsWith('OBJ')) {
        categories['사물목적']![key] = value;
      } else if (key.startsWith('FORM')) {
        categories['형태특성']![key] = value;
      } else if (key.startsWith('INT')) {
        categories['상호작용']![key] = value;
      } else if (key.startsWith('U')) {
        categories['문화정체성']![key] = value;
      } else if (key.startsWith('P1')) {
        categories['개인고유성']![key] = value;
      }
    });

    return categories;
  }

  /// 카테고리별 평균 점수 계산
  static Map<String, double> calculateCategoryAverages(
    Map<String, double> personalityVariables,
  ) {
    final categories = categorizeVariables(personalityVariables);
    final averages = <String, double>{};

    categories.forEach((categoryName, categoryVariables) {
      if (categoryVariables.isNotEmpty) {
        final sum = categoryVariables.values.reduce((a, b) => a + b);
        averages[categoryName] = sum / categoryVariables.length;
      }
    });

    return averages;
  }
}
