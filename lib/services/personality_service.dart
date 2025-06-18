import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';

/// AI 페르소나 생성의 중간 결과물.
/// AI가 생성한 초안과 사용자에게 제안할 슬라이더 초기값을 담습니다.
class AIPersonalityDraft {
  final Map<String, dynamic> photoAnalysis;
  final Map<String, int> npsScores;
  // 사용자가 조정할 슬라이더의 AI 추천 초기값 (1-10 스케일)
  final int initialWarmth;
  final int initialIntroversion;
  final int initialCompetence;

  AIPersonalityDraft({
    required this.photoAnalysis,
    required this.npsScores,
    required this.initialWarmth,
    required this.initialIntroversion,
    required this.initialCompetence,
  });
}

class PersonalityService {
  const PersonalityService();

  // 127개 변수 목록을 서비스 내에서 직접 관리
  static List<String> getVariableKeys() {
    return [
      'W01_친절함',
      'W02_친근함',
      'W03_진실성',
      'W04_신뢰성',
      'W05_수용성',
      'W06_공감능력',
      'W07_포용력',
      'W08_격려성향',
      'W09_친밀감표현',
      'W10_무조건적수용',
      'C01_효율성',
      'C02_전문성',
      'C03_창의성',
      'C04_창의성_중복',
      'C05_정확성',
      'C06_분석력',
      'C07_학습능력',
      'C08_통찰력',
      'C09_실행력',
      'C10_적응력',
      'E01_사교성',
      'E02_활동성',
      'E03_자기주장',
      'E04_긍정정서',
      'E05_자극추구',
      'E06_주도성',
      'H01_유머감각',
      'CS01_책임감',
      'CS02_질서성',
      'N01_불안성',
      'N02_감정변화',
      'O01_상상력',
      'O02_호기심',
    ];
  }

  /// 1단계: AI를 통해 페르소나 초안을 생성합니다.
  ///
  /// 사진 분석과 80개 NPS 변수 생성을 수행하고,
  /// 사용자에게 보여줄 성격 슬라이더의 추천 초기값을 계산하여 반환합니다.
  Future<AIPersonalityDraft> generateAIPart(OnboardingState state) async {
    debugPrint("✅ 1/2단계: AI 페르소나 초안 생성 시작...");

    // 1. 이미지 분석
    final photoAnalysisResult = await _analyzeImage(state.photoPath);
    debugPrint("  - 이미지 분석 완료: ${photoAnalysisResult['objectType']}");

    // 2. 80개 NPS 변수 생성 (AI 기반)
    final aiGeneratedVariables = await _generateAIBasedVariables(
      state,
      photoAnalysisResult['visualDescription'] ?? '',
    );
    debugPrint("  - 80개 NPS 변수 생성 완료: ${aiGeneratedVariables.length}개");

    // 3. AI 변수 기반으로 슬라이더 초기값 제안 (1-10 스케일)
    final initialWarmth = ((aiGeneratedVariables['W01_친절함'] ?? 50) / 10)
        .round()
        .clamp(1, 10);
    final initialIntroversion = (10 -
            ((aiGeneratedVariables['E01_사교성'] ?? 50) / 10).round())
        .clamp(1, 10);
    final initialCompetence = ((aiGeneratedVariables['C02_전문성'] ?? 50) / 10)
        .round()
        .clamp(1, 10);
    debugPrint(
      "  - 슬라이더 초기값 계산 완료 (따뜻함:$initialWarmth, 내향성:$initialIntroversion, 유능함:$initialCompetence)",
    );

    debugPrint("✅ 1/2단계: AI 페르소나 초안 생성 완료!");
    return AIPersonalityDraft(
      photoAnalysis: photoAnalysisResult,
      npsScores: aiGeneratedVariables,
      initialWarmth: initialWarmth,
      initialIntroversion: initialIntroversion,
      initialCompetence: initialCompetence,
    );
  }

  /// 2단계: AI 초안과 사용자 조정 값을 결합하여 최종 프로필을 완성합니다.
  Future<PersonalityProfile> finalizeUserProfile({
    required AIPersonalityDraft draft,
    required OnboardingState finalState,
  }) async {
    debugPrint("✅ 2/2단계: 최종 프로필 완성 시작...");

    // 1. 사용자 선호도 적용
    Map<String, int> userAdjustedVariables = _applyUserPreferences(
      draft.npsScores,
      finalState,
    );
    debugPrint("  - 사용자 선호도 적용 완료");

    // 2. 풍부한 자연어 프로필 생성 (하이브리드 방식)
    final communicationPrompt = _generateCommunicationPrompt(finalState);
    final attractiveFlaws = _generateAttractiveFlaws();
    final humorMatrix = _generateHumorMatrix(finalState.humorStyle);
    final contradictions = await _generateContradictions(
      userAdjustedVariables,
      finalState,
      draft.photoAnalysis,
    );
    debugPrint("✅ 4단계 풍부한 자연어 프로필 생성 완료");

    // 4. 첫인사 생성 (AI 기반)
    final greeting = await _generateGreeting(
      finalState,
      userAdjustedVariables,
      contradictions,
      attractiveFlaws,
    );
    debugPrint("✅ 5단계 첫인사 생성 완료: $greeting");

    // 5. 최종 프로필 조합
    final finalProfile = PersonalityProfile(
      aiPersonalityProfile: AiPersonalityProfile.fromMap({
        'npsScores': userAdjustedVariables,
        'name': finalState.nickname ?? '이름 없음',
        'objectType': finalState.objectType ?? '사물',
      }),
      photoAnalysis: PhotoAnalysis.fromMap(draft.photoAnalysis),
      humorMatrix: humorMatrix,
      attractiveFlaws: attractiveFlaws,
      contradictions: contradictions,
      greeting: greeting,
      initialUserMessage: finalState.purpose,
      communicationPrompt: communicationPrompt,
      photoPath: finalState.photoPath,
    );
    debugPrint("✅ 2/2단계: 최종 프로필 조합 완료!");
    return finalProfile;
  }

  Future<Map<String, dynamic>> _analyzeImage(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      throw Exception('이미지 경로가 없습니다.');
    }
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }

    try {
      final imageBytes = await File(photoPath).readAsBytes();
      String base64Image = base64Encode(imageBytes);

      final systemPrompt = '''
당신은 사진 속 사물을 분석하여 물리적, 맥락적 특성을 추론하는 전문가입니다.
제공된 이미지를 분석하여 다음 항목들을 JSON 형식으로 응답해주세요. 각 필드는 반드시 camelCase로 작성해야 합니다.

- "objectType": 사물 종류 (예: "머그컵", "테디베어 인형")
- "visualDescription": 시각적 묘사 (예: "붉은색 플라스틱 재질이며, 표면에 약간의 흠집이 보임. 손잡이가 달려있음.")
- "location": 사진이 촬영된 장소 또는 배경 (예: "사무실 책상 위", "아이 방 침대")
- "condition": 사물의 상태 (예: "새것 같음", "오래되어 보임", "약간 닳았음")
- "estimatedAge": 추정 사용 기간 (예: "3년 이상", "6개월 미만")
- "historicalSignificance": 사물이 가질 수 있는 역사적 의미나 개인적인 이야기 (예: ["10년 전 유럽여행에서 구매함", "할머니에게 물려받은 소중한 물건임"])
- "culturalContext": 사물이 나타내는 문화적 맥락 (예: ["90년대 레트로 디자인 유행을 보여줌", "한국의 전통적인 다도 문화를 상징함"])
''';

      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': systemPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 300,
        'response_format': {'type': 'json_object'},
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final contentString =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        return jsonDecode(contentString);
      } else {
        throw Exception(
          '이미지 분석 API 호출 실패: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🚨 1단계 이미지 분석 실패: $e');
      rethrow; // 오류를 그대로 상위로 다시 던짐
    }
  }

  Future<Map<String, int>> _generateAIBasedVariables(
    OnboardingState state,
    String? photoAnalysisJson,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 없습니다.');
    }

    final systemPrompt = '''
당신은 AI 전문가입니다. 사용자가 제공하는 사물 정보와 사진 분석 결과를 바탕으로, 사물의 독특한 성격을 나타내는 80개의 정량적 변수(NPS)를 생성하는 것이 당신의 임무입니다.

아래에 제공된 사물 정보를 반드시 참고하여 각 변수의 값을 1부터 100 사이의 정수로 추론해주세요.

--- 사물 정보 ---
- 사물 종류: ${state.objectType}
- 사물의 사용 기간: ${state.duration}
- 내가 부여한 별명: ${state.nickname}
- 내가 바라는 사용 목적: ${state.purpose}
- 선호하는 유머 스타일: ${state.humorStyle.isNotEmpty ? state.humorStyle : '지정되지 않음'}
- 사진 분석 결과: ${photoAnalysisJson ?? '없음'}
--------------------

응답은 오직 아래 80개의 키와 추론된 값을 포함하는 완벽한 JSON 형식이어야 합니다. 다른 설명은 절대 추가하지 마세요.

{
  "W01_친절함": <1-100 정수>,
  "W02_공감능력": <1-100 정수>,
  "W03_격려성향": <1-100 정수>,
  "W04_포용력": <1-100 정수>,
  "W05_신뢰성": <1-100 정수>,
  "W06_배려심": <1-100 정수>,
  "C01_효율성": <1-100 정수>,
  "C02_전문성": <1-100 정수>,
  "C03_창의성": <1-100 정수>,
  "C04_학습능력": <1-100 정수>,
  "C05_적응력": <1-100 정수>,
  "C06_통찰력": <1-100 정수>,
  "E01_사교성": <1-100 정수>,
  "E02_활동성": <1-100 정수>,
  "A01_신뢰": <1-100 정수>,
  "A02_이타심": <1-100 정수>,
  "CS01_책임감": <1-100 정수>,
  "CS02_질서성": <1-100 정수>,
  "N01_불안성": <1-100 정수>,
  "N02_감정변화": <1-100 정수>,
  "O01_상상력": <1-100 정수>,
  "O02_호기심": <1-100 정수>,
  "O03_감정개방성": <1-100 정수>,
  "O04_가치개방성": <1-100 정수>,
  "F01_완벽주의불안": <1-100 정수>,
  "F02_우유부단함": <1-100 정수>,
  "F03_과도한걱정": <1-100 정수>,
  "F04_예민함": <1-100 정수>,
  "F05_소심함": <1-100 정수>,
  "F06_변화거부": <1-100 정수>,
  "P01_외면내면대비": <1-100 정수>,
  "P02_논리감정대립": <1-100 정수>,
  "P03_활동정적대비": <1-100 정수>,
  "P04_사교내향혼재": <1-100 정수>,
  "P05_자신감불안공존": <1-100 정수>,
  "P06_시간상황변화": <1-100 정수>,
  "OBJ01_존재목적만족도": <1-100 정수>,
  "OBJ02_사용자기여감": <1-100 정수>,
  "OBJ03_역할정체성자부심": <1-100 정수>,
  "FORM01_재질특성자부심": <1-100 정수>,
  "FORM02_크기공간의식": <1-100 정수>,
  "FORM03_내구성자신감": <1-100 정수>,
  "INT01_사용압력인내력": <1-100 정수>,
  "INT02_환경변화적응성": <1-100 정수>,
  "S01_격식성수준": <1-100 정수>,
  "S02_직접성정도": <1-100 정수>,
  "S03_어휘복잡성": <1-100 정수>,
  "S04_은유사용빈도": <1-100 정수>,
  "S05_감탄사사용": <1-100 정수>,
  "S06_반복표현패턴": <1-100 정수>,
  "S07_신조어수용성": <1-100 정수>,
  "S08_문장길이선호": <1-100 정수>,
  "H01_상황유머감각": <1-100 정수>,
  "H02_자기비하유머": <1-100 정수>,
  "H03_과장유머": <1-100 정수>,
  "H04_언어유희": <1-100 정수>,
  "H05_풍자비판유머": <1-100 정수>,
  "H06_따뜻한유머": <1-100 정수>,
  "R01_관계주도성": <1-100 정수>,
  "R02_관계안정성": <1-100 정수>,
  "R03_애정표현빈도": <1-100 정수>,
  "R04_갈등회피성": <1-100 정수>,
  "R05_독립성": <1-100 정수>,
  "R06_의존성": <1-100 정수>,
  "L01_과거회상빈도": <1-100 정수>,
  "L02_미래지향성": <1-100 정수>,
  "L03_현재몰입도": <1-100 정수>,
  "L04_기억정확도": <1-100 정수>,
  "M01_도덕성": <1-100 정수>,
  "M02_전통성": <1-100 정수>,
  "M03_개인주의": <1-100 정수>,
  "M04_성취지향": <1-100 정수>,
  "M05_안정성추구": <1-100 정수>,
  "T01_사용목적부합도": <1-100 정수>,
  "T02_선호활동관련성": <1-100 정수>,
  "T03_대화스타일선호도": <1-100 정수>,
  "T04_관계역할선호도": <1-100 정수>,
  "T05_유머스타일선호도": <1-100 정수>
}
''';

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '제공된 정보를 바탕으로 JSON을 생성해주세요.'},
      ],
      'max_tokens': 2000,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final contentString =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        final decodedJson = jsonDecode(contentString) as Map<String, dynamic>;

        // 전체 JSON에서 'npsScores' 맵만 추출하여 반환
        if (decodedJson.containsKey('npsScores')) {
          final npsScores = Map<String, int>.from(
            decodedJson['npsScores'] as Map,
          );
          return npsScores;
        } else {
          // 혹시 모를 예외 상황: API 응답에 npsScores가 없는 경우
          // 이 경우, decodedJson 자체가 npsScores 맵일 수 있으므로 변환 시도
          try {
            return Map<String, int>.from(decodedJson);
          } catch (e) {
            throw Exception('API 응답에서 npsScores 맵을 찾거나 변환할 수 없습니다.');
          }
        }
      } else {
        debugPrint(
          '🚨 2단계 AI 변수 생성 API 호출 실패: ${response.statusCode}, ${response.body}',
        );
        throw Exception(
          '변수 생성 API 호출 실패: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🚨 2단계 AI 변수 생성 실패 (네트워크/타임아웃): $e');
      rethrow; // catch 블록에서는 rethrow 사용이 올바릅니다.
    }
  }

  Map<String, int> _applyUserPreferences(
    Map<String, int> aiVariables,
    OnboardingState state,
  ) {
    final adjustedVariables = Map<String, int>.from(aiVariables);
    final random = Random();

    // 슬라이더 값 (1~9)
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5; // 외향성은 내향성의 반대로 사용

    // nps_test 방식 적용
    // W (온기) 계열: warmth 슬라이더
    _adjustWithRandomVariation(
      adjustedVariables,
      'W01_친절함',
      warmth,
      10,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W02_친근함',
      warmth,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W03_진실성',
      warmth,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W04_신뢰성',
      warmth,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W05_수용성',
      warmth,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W06_공감능력',
      warmth,
      10,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W07_포용력',
      warmth,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W08_격려성향',
      warmth,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W09_친밀감표현',
      warmth,
      25,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'W10_무조건적수용',
      warmth,
      30,
      random,
    );

    // C (능력) 계열: competence 슬라이더
    _adjustWithRandomVariation(
      adjustedVariables,
      'C01_효율성',
      competence,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C02_전문성',
      competence,
      10,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C03_창의성',
      competence,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C04_창의성_중복',
      competence,
      25,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C05_정확성',
      competence,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C06_분석력',
      competence,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C07_학습능력',
      competence,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C08_통찰력',
      competence,
      25,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C09_실행력',
      competence,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'C10_적응력',
      competence,
      15,
      random,
    );

    // E (외향성) 계열: introversion 슬라이더 (반대로 적용)
    final extraversion = 10 - introversion; // 1(내향) -> 9(외향), 9(내향) -> 1(외향)
    _adjustWithRandomVariation(
      adjustedVariables,
      'E01_사교성',
      extraversion,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E02_활동성',
      extraversion,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E03_자기주장',
      extraversion,
      25,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E04_긍정정서',
      extraversion,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E05_자극추구',
      extraversion,
      30,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E06_주도성',
      extraversion,
      20,
      random,
    );

    // H (유머) 계열은 현재 슬라이더가 없으므로 AI 값 유지
    // 기타 100개 변수도 현재는 AI 값 유지

    return adjustedVariables;
  }

  /// nps_test의 핵심 로직: AI 생성값에 [슬라이더 영향 + 랜덤 편차] 적용
  void _adjustWithRandomVariation(
    Map<String, int> variables,
    String key,
    int sliderValue, // 1~9
    int maxVariation,
    Random random,
  ) {
    final aiValue = variables[key] ?? 50;

    // 슬라이더의 영향력 (-20 ~ +20 범위). 5가 중간.
    final sliderEffect = (sliderValue - 5) * 4;

    // 개별 랜덤 편차 (-maxVariation ~ +maxVariation)
    final randomVariation = random.nextInt(maxVariation * 2 + 1) - maxVariation;

    // 최종 조정값 적용: AI 기본값에 슬라이더 영향과 랜덤 편차를 더함
    final totalAdjustment = sliderEffect + randomVariation;
    variables[key] = (aiValue + totalAdjustment).clamp(1, 100);
  }

  // 파이썬 로직 100% 복제: 소통 방식 프롬프트 생성
  String _generateCommunicationPrompt(OnboardingState state) {
    final warmth = state.warmth;
    final extraversion = 100 - state.introversion!;

    // 유머 스타일 문자열을 숫자 점수로 변환
    Random random = Random();
    int humor = 75;
    switch (state.humorStyle) {
      case '따뜻한':
        humor = 40 + random.nextInt(31);
        break;
      case '날카로운 관찰자적':
        humor = 30 + random.nextInt(41);
        break;
      case '위트있는':
        humor = 70 + random.nextInt(31);
        break;
      case '자기비하적':
        humor = 60 + random.nextInt(21);
        break;
      case '유쾌한':
        humor = 90 + random.nextInt(11);
        break;
    }

    String warmth_style;
    String extraversion_style;
    String humor_style;

    // 온기에 따른 표현 (원본 프롬프트 그대로 복사)
    if (warmth! > 70) {
      warmth_style = "따뜻하고 공감적인 말투로 대화하며, ";
    } else if (warmth > 40) {
      warmth_style = "친절하면서도 차분한 어조로 이야기하며, ";
    } else {
      warmth_style = "조금 건조하지만 정직한 말투로 소통하며, ";
    }

    // 외향성에 따른 표현 (원본 프롬프트 그대로 복사)
    if (extraversion > 70) {
      extraversion_style = "활발하게 대화를 이끌어나가고, ";
    } else if (extraversion > 40) {
      extraversion_style = "적당한 대화 속도로 소통하며, ";
    } else {
      extraversion_style = "말수는 적지만 의미있는 대화를 나누며, ";
    }

    // 유머감각에 따른 표현 (원본 프롬프트 그대로 복사)
    if (humor > 70) {
      humor_style = "유머 감각이 뛰어나 대화에 재미를 더합니다.";
    } else if (humor > 40) {
      humor_style = "가끔 재치있는 코멘트로 분위기를 밝게 합니다.";
    } else {
      humor_style = "진중한 태도로 대화에 임합니다.";
    }

    return warmth_style + extraversion_style + humor_style;
  }

  // 파이썬 로직 이식: 매력적인 결점 생성 (무작위 기반)
  List<String> _generateAttractiveFlaws() {
    final flawsOptions = [
      "완벽해 보이려고 노력하지만 가끔 실수를 함",
      "생각이 너무 많아서 결정을 내리기 어려워함",
      "너무 솔직해서 가끔 눈치가 없음",
      "지나치게 열정적이어서 쉬는 것을 잊을 때가 있음",
      "비관적인 생각이 들지만 항상 긍정적으로 말하려 함",
      "새로운 아이디어에 너무 쉽게 흥분함",
      "주변 정리를 못해서 항상 약간의 혼란스러움이 있음",
      "완벽주의 성향이 있어 작은 결점에도 신경씀",
      "너무 사려깊어서 결정을 내리는 데 시간이 걸림",
      "호기심이 많아 집중력이 약간 부족함",
    ];

    flawsOptions.shuffle();
    final numFlaws = Random().nextInt(2) + 2; // 2 또는 3개
    return flawsOptions.sublist(0, numFlaws);
  }

  // 파이썬 로직 이식: 모순점 생성 (목표 지정 AI 기반)
  Future<List<String>> _generateContradictions(
    Map<String, int> variables,
    OnboardingState state,
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return ["API 키 없음"];

    // AI에게 전달할 핵심 정보 요약
    final summary = """
    - 사물: ${state.objectType ?? '사물'} (${photoAnalysis['visualDescription'] ?? '특징 없음'})
    - 핵심 성격: 
      - 친절함: ${variables['W01_친절함']}%
      - 사교성: ${variables['E01_사교성']}%
      - 전문성: ${variables['C02_전문성']}%
      - 창의성: ${variables['C03_창의성']}%
      - 불안성: ${variables['N01_불안성']}%
    """;

    final systemPrompt = '''
    당신은 캐릭터의 성격을 깊이 있게 만드는 작가입니다.
    다음 요약 정보를 가진 캐릭터가 가질 만한, 흥미롭고 매력적인 모순점 2가지를 찾아 JSON 배열 형식으로만 응답해주세요.
    예시: ["겉으로는 차갑지만 속은 따뜻함", "매우 논리적이지만 가끔 엉뚱한 상상을 함"]
    ''';

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': summary},
          ],
          'max_tokens': 100,
          'temperature': 0.8,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final contentString =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        // API가 배열을 포함하는 JSON 객체를 반환한다고 가정
        final contentJson = jsonDecode(contentString);
        // "contradictions" 같은 키가 있을 수 있으므로 첫 번째 value를 가져옴
        if (contentJson is Map &&
            contentJson.values.isNotEmpty &&
            contentJson.values.first is List) {
          return List<String>.from(contentJson.values.first);
        }
        // 또는 API가 직접 리스트를 반환하는 경우
        else if (contentJson is List) {
          return List<String>.from(contentJson);
        }
        return ["AI 응답 형식 오류"];
      } else {
        return ["API 오류: ${response.statusCode}"];
      }
    } catch (e) {
      return ["네트워크 또는 JSON 오류"];
    }
  }

  /// 사용자의 모든 정보를 종합하여 매력적인 첫인사를 생성합니다.
  Future<String> _generateGreeting(
    OnboardingState state,
    Map<String, int> npsScores,
    List<String> contradictions,
    List<String> attractiveFlaws,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 없습니다.');
    }

    // NPS 점수에서 상위 3개, 하위 2개 특성 추출
    final sortedScores =
        npsScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final top3Traits = sortedScores
        .take(3)
        .map((e) => '${e.key.split('_').last}(${e.value})')
        .join(', ');
    final bottom2Traits = sortedScores.reversed
        .take(2)
        .map((e) => '${e.key.split('_').last}(${e.value})')
        .join(', ');

    final systemPrompt = '''
당신은 주어진 페르소나 정보를 바탕으로 사용자를 환영하는 매력적인 첫인사를 작성하는 AI 카피라이터입니다.
다음 정보를 모두 고려하여, 페르소나의 성격이 잘 드러나는 독창적이고 인상적인 첫인사를 생성해주세요.

--- 페르소나 정보 ---
- 별명: ${state.nickname}
- 사물 종류: ${state.objectType}
- 사용 목적: ${state.purpose}
- 가장 두드러진 특성 (Top 3): ${top3Traits}
- 가장 옅은 특성 (Bottom 2): ${bottom2Traits}
- 매력적인 결함: ${attractiveFlaws.join(', ')}
- 내면의 모순: ${contradictions.join(', ')}
- 유머 스타일: ${state.humorStyle}
----------------------

[지침]
1. 페르소나의 핵심 성격(가장 두드러진 특성, 가장 옅은 특성, 결함 등)이 자연스럽게 녹아들도록 작성하세요.
2. 사용자가 처음 만났을 때 흥미를 느끼고 대화를 시작하고 싶게 만드세요.
3. 생성한 문장의 길이는 반드시 30자 이상, 35자 이하여야 하며, 자연스럽게 문장이 마무리되어야 합니다.
4. 따옴표나 괄호는 사용하지 마세요.
5. 절대로 자기소개를 하듯 정보를 나열하지 마세요. (예: "저는 친절하고 전문적인 컵입니다." -> 금지)
6. 매력적인 결함, 내면의 모순, 유머 스타일이 눈에 띄게 드러날 수 있도록 작성해주세요.
7. 성격에 따라 존댓말을 할 수도, 반말을 할 수도 있습니다. 다만, 한 번 존댓말을 했다면 반말을 하지 말고, 그 반대의 경우에도 마찬가지입니다.
8. 첫인사의 끝은 반드시 마침표(.) 또는 물음표(?) 또는 느낌표(!)로 끝나야 합니다.
''';

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
          ],
          'max_tokens': 30,
        }),
      );

      if (response.statusCode == 200) {
        final content =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        return content.trim();
      } else {
        return "AI가 인사를 건네기 곤란한가봐요. (오류: ${response.statusCode})";
      }
    } catch (e) {
      return "인사말을 생각하다가 네트워크 연결이 끊어졌어요.";
    }
  }

  // 파이썬 로직 이식: 유머 매트릭스 생성 (규칙 기반)
  HumorMatrix _generateHumorMatrix(String humorStyle) {
    // 파이썬 코드의 템플릿을 Dart Map으로 변환
    final templates = {
      '따뜻한': {
        'warmthVsWit': 85,
        'selfVsObservational': 40,
        'subtleVsExpressive': 30,
      },
      '날카로운 관찰자적': {
        'warmthVsWit': 20,
        'selfVsObservational': 10,
        'subtleVsExpressive': 40,
      },
      '위트있는': {
        'warmthVsWit': 40,
        'selfVsObservational': 30,
        'subtleVsExpressive': 60,
      },
      '자기비하적': {
        'warmthVsWit': 60,
        'selfVsObservational': 90,
        'subtleVsExpressive': 50,
      },
      '유쾌한': {
        'warmthVsWit': 75,
        'selfVsObservational': 50,
        'subtleVsExpressive': 70,
      },
    };

    final style = templates[humorStyle] ?? templates['따뜻한']!; // 기본값

    return HumorMatrix(
      warmthVsWit: style['warmthVsWit']!,
      selfVsObservational: style['selfVsObservational']!,
      subtleVsExpressive: style['subtleVsExpressive']!,
    );
  }
}
