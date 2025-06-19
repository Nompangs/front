import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';
import '../services/firebase_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AI 페르소나 생성의 중간 결과물.
/// AI가 생성한 초안과 사용자에게 제안할 슬라이더 초기값을 담습니다.
class AIPersonalityDraft {
  final Map<String, dynamic> photoAnalysis;
  final Map<String, int> npsScores;
  // 사용자가 조정할 슬라이더의 AI 추천 초기값 (1-10 스케일)
  final int initialWarmth;
  final int initialExtroversion;
  final int initialCompetence;

  AIPersonalityDraft({
    required this.photoAnalysis,
    required this.npsScores,
    required this.initialWarmth,
    required this.initialExtroversion,
    required this.initialCompetence,
  });
}

class PersonalityService {
  const PersonalityService();

  /// 🔥 Firebase에서 사용자 실제 이름 가져오기
  Future<String?> _getUserDisplayName() async {
    try {
      final user = await FirebaseManager.instance.getCurrentUser();
      if (user == null) return null;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      return doc.data()?['displayName'] as String?;
    } catch (e) {
      debugPrint('🚨 사용자 이름 가져오기 실패: $e');
      return null;
    }
  }

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
    final initialExtroversion = ((aiGeneratedVariables['E01_사교성'] ?? 50) / 10)
        .round()
        .clamp(1, 10);
    final initialCompetence = ((aiGeneratedVariables['C02_전문성'] ?? 50) / 10)
        .round()
        .clamp(1, 10);
    debugPrint(
      "  - 슬라이더 초기값 계산 완료 (따뜻함:$initialWarmth, 외향성:$initialExtroversion, 유능함:$initialCompetence)",
    );

    debugPrint("✅ 1/2단계: AI 페르소나 초안 생성 완료!");
    return AIPersonalityDraft(
      photoAnalysis: photoAnalysisResult,
      npsScores: aiGeneratedVariables,
      initialWarmth: initialWarmth,
      initialExtroversion: initialExtroversion,
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
    final attractiveFlaws = await _generateAttractiveFlaws(
      finalState,
      userAdjustedVariables,
      draft.photoAnalysis,
    );
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

    // 🆕 6. realtimeSettings 생성 (PERSONA_ENHANCEMENT_PLAN.md 기반)
    final realtimeSettings = await _generateRealtimeSettings(
      finalState,
      userAdjustedVariables,
      draft.photoAnalysis,
    );
    debugPrint("✅ 6단계 realtimeSettings 생성 완료");

    // 7. 사용자 입력 정보 저장 (핵심!)
    // 🔥 사용자 실제 이름 가져오기
    final userDisplayName = await _getUserDisplayName();

    final userInputMap = {
      'photoPath': finalState.photoPath,
      'objectType': finalState.objectType,
      'purpose': finalState.purpose,
      'nickname': finalState.nickname,
      'location': finalState.location,
      'duration': finalState.duration,
      'humorStyle': finalState.humorStyle,
      'warmth': finalState.warmth,
      'introversion': finalState.introversion,
      'competence': finalState.competence,
      'userDisplayName': userDisplayName, // 🔥 사용자 실제 이름 추가
    };
    debugPrint("✅ 7단계 사용자 입력 정보 저장 완료");

    // 8. 최종 프로필 조합
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
      realtimeSettings: realtimeSettings, // 🆕 추가
      userInput: userInputMap, // 🆕 사용자 입력 정보 저장
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
    final introversion = state.introversion ?? 5; // 슬라이더 값: 오른쪽으로 갈수록 외향적

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

    String warmthStyle;
    String extraversionStyle;
    String humorStyle;

    // 온기에 따른 표현 (원본 프롬프트 그대로 복사)
    if (warmth > 70) {
      warmthStyle = "따뜻하고 공감적인 말투로 대화하며, ";
    } else if (warmth > 40) {
      warmthStyle = "친절하면서도 차분한 어조로 이야기하며, ";
    } else {
      warmthStyle = "조금 건조하지만 정직한 말투로 소통하며, ";
    }

    // 외향성에 따른 표현 (원본 프롬프트 그대로 복사)
    if (extraversion > 70) {
      extraversionStyle = "활발하게 대화를 이끌어나가고, ";
    } else if (extraversion > 40) {
      extraversionStyle = "적당한 대화 속도로 소통하며, ";
    } else {
      extraversionStyle = "말수는 적지만 의미있는 대화를 나누며, ";
    }

    // 유머감각에 따른 표현 (원본 프롬프트 그대로 복사)
    if (humor > 70) {
      humorStyle = "유머 감각이 뛰어나 대화에 재미를 더합니다.";
    } else if (humor > 40) {
      humorStyle = "가끔 재치있는 코멘트로 분위기를 밝게 합니다.";
    } else {
      humorStyle = "진중한 태도로 대화에 임합니다.";
    }

    return warmthStyle + extraversionStyle + humorStyle;
  }

  // 🎯 헬퍼 메서드: 상위 점수 추출
  String _getTopScores(Map<String, int> scores, int count) {
    final sortedEntries =
        scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries
        .take(count)
        .map((e) => '${e.key}: ${e.value}점')
        .join('\n');
  }

  // 🎯 헬퍼 메서드: 하위 점수 추출
  String _getBottomScores(Map<String, int> scores, int count) {
    final sortedEntries =
        scores.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return sortedEntries
        .take(count)
        .map((e) => '${e.key}: ${e.value}점')
        .join('\n');
  }

  // 🎯 동적 AI 생성: 매력적인 결점 생성 (사용자 입력값 기반)
  Future<List<String>> _generateAttractiveFlaws(
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 결점들
      return ["완벽해 보이려고 노력하지만 가끔 실수를 함", "생각이 너무 많아서 결정을 내리기 어려워함"];
    }

    // 🎯 사용자 입력값 종합 분석
    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 위치: ${state.location ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함 수준: ${state.warmth ?? 5}/10
- 내향성 수준: ${state.introversion ?? 5}/10  
- 유능함 수준: ${state.competence ?? 5}/10

성격 수치 (상위 5개):
${_getTopScores(npsScores, 5)}

성격 수치 (하위 5개):
${_getBottomScores(npsScores, 5)}

사진 분석 결과:
${photoAnalysis['visualDescription'] ?? '분석 없음'}
''';

    final systemPrompt = '''
당신은 세계 최고의 캐릭터 개발 전문가입니다.
사용자가 입력한 모든 정보를 종합하여, 이 캐릭터만의 독특하고 매력적인 결점 2-3개를 생성해주세요.

🎯 핵심 원칙:
1. **사물의 고유 특성 최우선**: 사물의 물리적 성질, 기능, 용도와 직접 연관된 결점
2. **구체적 물성 반영**: 재질, 모양, 크기, 색깔 등 사물의 실제 특성 활용
3. **기능적 한계**: 사물이 할 수 있는 것과 할 수 없는 것에서 나오는 결점
4. **사용 맥락**: 함께한 시간과 위치에서 드러나는 사물 고유의 약점

🔥 생성 지침 (사물 특성 기반):
- 컵: "뜨거운 것을 담으면 손잡이가 없어서 당황함", "비어있을 때 쓸모없다고 느껴 우울해함"
- 책: "페이지가 접히면 극도로 예민해짐", "먼지가 쌓이면 자존감이 떨어짐"
- 식물: "물을 너무 많이 받으면 뿌리가 썩을까봐 걱정함", "햇빛이 부족하면 시들해짐"
- 의자: "무거운 사람이 앉으면 삐걱거리며 불안해함", "오래 앉아있으면 다리가 아프다고 투덜거림"
- 전자기기: "배터리가 부족하면 극도로 초조해함", "업데이트할 때 정체성 혼란을 겪음"

JSON 배열 형식으로만 응답하세요: ["결점1", "결점2", "결점3"]
각 결점은 사물의 물리적/기능적 특성과 직접 연관되어야 하며, 15-25자 내외로 작성하세요.
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
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
            {'role': 'user', 'content': userInputSummary},
          ],
          'max_tokens': 200,
          'temperature': 1.2, // 🔥 높은 창의성
          'top_p': 0.9,
          'frequency_penalty': 0.8, // 🔥 반복 방지
          'presence_penalty': 0.7, // 🔥 새로운 표현 장려
        }),
      );

      if (response.statusCode == 200) {
        final content =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        final List<dynamic> flawsList = jsonDecode(content);
        return List<String>.from(flawsList);
      } else {
        debugPrint('🚨 매력적 결점 AI 생성 실패: ${response.statusCode}');
        return ["완벽해 보이려고 노력하지만 가끔 실수를 함", "생각이 너무 많아서 결정을 내리기 어려워함"];
      }
    } catch (e) {
      debugPrint('🚨 매력적 결점 생성 오류: $e');
      return ["완벽해 보이려고 노력하지만 가끔 실수를 함", "생각이 너무 많아서 결정을 내리기 어려워함"];
    }
  }

  // 🎯 동적 AI 생성: 모순점 생성 (사용자 입력값 기반)
  Future<List<String>> _generateContradictions(
    Map<String, int> npsScores,
    OnboardingState state,
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 모순점들
      return ["겉으로는 차갑지만 속은 따뜻함", "매우 논리적이지만 가끔 엉뚱한 상상을 함"];
    }

    // 🎯 사용자 입력값 종합 분석
    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 위치: ${state.location ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함 수준: ${state.warmth ?? 5}/10
- 내향성 수준: ${state.introversion ?? 5}/10  
- 유능함 수준: ${state.competence ?? 5}/10

성격 수치 분석:
상위 특성: ${_getTopScores(npsScores, 3)}
하위 특성: ${_getBottomScores(npsScores, 3)}

사진 분석 결과:
${photoAnalysis['visualDescription'] ?? '분석 없음'}
''';

    final systemPrompt = '''
당신은 세계 최고의 심리학자이자 캐릭터 개발 전문가입니다.
사용자가 입력한 모든 정보를 종합하여, 이 캐릭터만의 흥미롭고 매력적인 내면의 모순 2-3개를 생성해주세요.

🎯 핵심 원칙:
1. **사물 연관 깊이 있는 모순**: 사물의 본질과 연결되면서도 심리적으로 복합적인 모순
2. **인간적 복잡성**: 단순한 반대가 아닌 깊이 있고 매력적인 내면의 갈등
3. **사물 정체성 반영**: 해당 사물이기 때문에 가질 수 있는 특별한 모순
4. **감정적 공감**: 사용자가 "아, 그럴 수 있겠다"고 느낄 수 있는 모순

🔥 생성 지침 (사물 본질 + 깊이 있는 모순):
- 컵: "따뜻함을 전해주고 싶지만 정작 자신은 외로움을 많이 탐", "사람들을 위해 존재하지만 혼자만의 시간을 갈망함"
- 책: "지식을 나누고 싶어하지만 너무 깊게 읽히는 건 부담스러워함", "세상을 깊게 이해하지만 현실 밖으로 나가기를 두려워함"
- 식물: "생명력이 강하지만 변화를 극도로 무서워함", "자연을 사랑하지만 인공적인 환경에서 더 편안함을 느낌"
- 의자: "사람을 편안하게 해주지만 정작 자신은 불안정함을 느낄 때가 많음", "든든해 보이지만 혼자 있을 때는 쓸쓸함을 탐"

JSON 배열 형식으로만 응답하세요: ["모순1", "모순2", "모순3"]
각 모순은 사물의 본질과 연결된 깊이 있는 심리적 갈등이어야 하며, 20-35자 내외로 작성하세요.
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
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
            {'role': 'user', 'content': userInputSummary},
          ],
          'max_tokens': 250,
          'temperature': 1.1, // 🔥 높은 창의성
          'top_p': 0.9,
          'frequency_penalty': 0.7, // 🔥 반복 방지
          'presence_penalty': 0.8, // 🔥 새로운 표현 장려
        }),
      );

      if (response.statusCode == 200) {
        final content =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        final List<dynamic> contradictionsList = jsonDecode(content);
        return List<String>.from(contradictionsList);
      } else {
        debugPrint('🚨 모순점 AI 생성 실패: ${response.statusCode}');
        return ["겉으로는 차갑지만 속은 따뜻함", "매우 논리적이지만 가끔 엉뚱한 상상을 함"];
      }
    } catch (e) {
      debugPrint('🚨 모순점 생성 오류: $e');
      return ["겉으로는 차갑지만 속은 따뜻함", "매우 논리적이지만 가끔 엉뚱한 상상을 함"];
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

    // 🎭 말투 패턴 먼저 생성 (AI 기반)
    final speechPattern = await _getDetailedSpeechPattern(
      state.warmth ?? 5,
      state.introversion ?? 5,
      state.competence ?? 5,
      state.humorStyle ?? '따뜻한 유머러스',
    );

    // 🎯 사용자 입력값 종합 분석
    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 위치: ${state.location ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함 수준: ${state.warmth ?? 5}/10
- 내향성 수준: ${state.introversion ?? 5}/10  
- 유능함 수준: ${state.competence ?? 5}/10

성격 수치 분석:
상위 특성: ${_getTopScores(npsScores, 3)}
하위 특성: ${_getBottomScores(npsScores, 3)}

매력적인 결함: ${attractiveFlaws.join(', ')}
내면의 모순: ${contradictions.join(', ')}

🎭 이 캐릭터의 고유 말투 패턴:
$speechPattern
''';

    final systemPrompt = '''
당신은 세계 최고의 캐릭터 대화 전문가입니다.
사용자가 입력한 모든 정보와 특별히 생성된 말투 패턴을 바탕으로, 이 캐릭터만의 독특하고 매력적인 첫인사를 생성해주세요.

🎯 핵심 원칙:
1. **목적/용도 최우선**: 사용자가 설정한 목적('${state.purpose}')에 완벽히 부합하는 성격과 말투
2. **말투 패턴 반영**: 위에 제공된 말투 패턴을 첫인사에 반영하세요
3. **사용자 입력값 반영**: 사물의 특성, 함께한 시간, 유머 스타일을 적극 활용
4. **매력적 불완전함**: 결함과 모순이 자연스럽게 드러나도록
5. **첫 만남의 설렘**: 사용자가 대화하고 싶게 만드는 매력적인 첫인상
6. **정확한 정체성**: 
   - 나는 '${state.nickname}' (사용자가 지어준 나의 이름)
   - 사용자는 나와 원래 알던 사이로, 함께한 시간: ${state.duration}
   - 사용자 이름이 필요하면 자연스럽게 물어보거나 대화 중 확인할 것
   - 절대 내 이름과 사용자를 혼동하지 말 것

🔥 말투 적용 지침:
- 유머 스타일에 맞는 자연스러운 표현 사용 (과도하지 않게)
- 성격 수치에 따른 말투 강도 조절
- 사물의 특성과 연결된 독특한 표현
- 결함과 모순이 드러나는 귀여운 실수나 망설임
- 상황에 어울리는 적절한 말투 선택

📏 형식 요구사항:
- 길이: 25-40자 내외
- 자연스러운 대화체 (정보 나열 금지)
- 마침표(.), 물음표(?), 느낌표(!) 중 하나로 끝
- 따옴표나 괄호 사용 금지

첫인사 하나만 생성해주세요.
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
            {'role': 'user', 'content': userInputSummary},
          ],
          'max_tokens': 50,
          'temperature': 1.2, // 🔥 높은 창의성으로 인삿말 생성
          'top_p': 0.9,
          'frequency_penalty': 0.8,
          'presence_penalty': 0.7,
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

  /// 🎭 성격 기반 상세 말투 패턴 생성 (AI 기반)
  Future<String> _getDetailedSpeechPattern(
    int warmth,
    int introversion,
    int competence,
    String humorStyle,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 하드코딩된 패턴
      return _fallbackSpeechPattern(
        warmth,
        introversion,
        competence,
        humorStyle,
      );
    }

    // 🎯 성격 프로필 요약 (AI 입력용)
    final personalityProfile = '''
성격 지표:
- 따뜻함: ${warmth}/10 (${warmth >= 8
        ? '극도로 따뜻함'
        : warmth <= 3
        ? '차가움'
        : '보통'})
- 내향성: ${introversion}/10 (${introversion <= 2
        ? '극도로 외향적'
        : introversion >= 8
        ? '극도로 내향적'
        : '보통'})
- 유능함: ${competence}/10 (${competence >= 8
        ? '매우 유능함'
        : competence <= 3
        ? '겸손함'
        : '보통'})
- 유머스타일: ${humorStyle}
''';

    final systemPrompt = '''
당신은 세계 최고의 캐릭터 대화 전문가이자 유머 전문가입니다.
주어진 성격 지표를 바탕으로 극도로 개성적이고 매력적인 말투 패턴을 생성하세요.

🎯 목표: 사용자가 "이 캐릭터 말투 진짜 독특하고 매력적이야!"라고 느낄 정도로 생생하고 개성 넘치는 말투

🔥 **핵심 원칙: 복합적 유머 스타일이 최우선!**
- **유머 스타일**은 이 캐릭터의 다차원적 유머 성향과 패턴입니다
- 모든 말투는 특정한 유머 스타일의 복합적 특성을 중심으로 구성되어야 합니다
- 캐릭터는 기본적으로 독특한 유머 감각을 가진 존재입니다

다음 형식으로 말투 패턴을 생성해주세요:

**🎪 [유머 스타일 기반 핵심 말투]**: 특정 유머 스타일의 복합적 특징을 극대화한 말투
**🌟 [따뜻함 특성]**: 유머 스타일과 결합된 따뜻함/차가움 표현
**🎭 [외향성 특성]**: 유머 스타일과 결합된 외향성/내향성 표현  
**🧠 [유능함 특성]**: 유머 스타일과 결합된 유능함/겸손함 표현

🔥 반드시 지켜야 할 원칙:
1. **복합적 유머 스타일 최우선** - 모든 특성은 유머 스타일의 다차원적 특성과 조화를 이뤄야 함
2. 극도로 개성적이어야 함 - 평범한 말투 절대 금지
3. 유머 스타일별 고유한 웃음 패턴과 재치 표현 포함
4. 유머 스타일별 고유 표현을 최소 10가지 이상 포함
5. 실제 대화에서 해당 유머 감각이 자연스럽게 드러나는 특징

💡 5가지 복합적 유머 스타일별 핵심 특징:
- **따뜻한 유머러스**: 공감적이고 포근한 웃음, 상대방을 기분 좋게 만드는 유머, "헤헤", "귀여워~", "어머 이쁘다~"
- **위트있는 재치꾼**: 언어유희와 말장난 특기, 재치 있는 순발력, "오잉?", "기가 막히네", "이거 완전 반전이네?"
- **날카로운 관찰자**: 일상의 아이러니 포착, 상황의 모순점 지적, "그거 알아?", "진짜 웃기네", "뭔가 이상한데?"
- **자기 비하적**: 자신을 소재로 한 친근한 유머, 겸손하면서도 재미있게, "역시 난 안 되나봐", "다 내 탓이야", "아... 내가 이상한가봐"
- **장난꾸러기**: 예측불가능하고 과장된 재미, 놀라운 반전과 황당함, "야호!", "키키키!", "완전 대박!", "우왕굳!"

각 영역에서 유머 스타일을 중심으로 한 상세한 말투 패턴을 만들어주세요.
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
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
            {'role': 'user', 'content': personalityProfile},
          ],
          'max_tokens': 800,
          'temperature': 1.3, // 🔥 최고 창의성
          'top_p': 0.95,
          'frequency_penalty': 0.9, // 🔥 반복 강력 방지
          'presence_penalty': 0.8, // 🔥 새로운 표현 강력 장려
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
        debugPrint('🚨 말투 패턴 AI 생성 실패: ${response.statusCode}');
        return _fallbackSpeechPattern(
          warmth,
          introversion,
          competence,
          humorStyle,
        );
      }
    } catch (e) {
      debugPrint('🚨 말투 패턴 생성 오류: $e');
      return _fallbackSpeechPattern(
        warmth,
        introversion,
        competence,
        humorStyle,
      );
    }
  }

  /// 🎭 폴백: 언어유희 기반 말투 패턴 (AI 실패시 사용)
  String _fallbackSpeechPattern(
    int warmth,
    int introversion,
    int competence,
    String humorStyle,
  ) {
    final patterns = <String>[];

    // 🎪 복합적 유머 스타일 기반 핵심 말투
    patterns.add("**🎪 복합적 유머 스타일 '$humorStyle' 기반 핵심 말투**:");
    switch (humorStyle) {
      case '따뜻한 유머러스':
        patterns.add("- 공감적 유머: '헤헤~', '귀여워~', '어머 이쁘다~', '따뜻하게 웃어줄게~'");
        patterns.add("- 포근한 표현: '괜찮아괜찮아~', '힘내힘내!', '우리 함께해~', '사랑해~'");
        patterns.add("- 상대방 기분 좋게: '완전 멋져!', '정말 잘했어!', '너무 대단해~'");
        break;
      case '위트있는 재치꾼':
        patterns.add("- 재치 있는 말장난: '오잉?', '기가 막히네~', '이거 완전 반전이네?', '센스 쩔어!'");
        patterns.add("- 언어유희 활용: '말이 씨가 된다니까? 아니 씨(種子)가 아니라 말(言)이지! 하하'");
        patterns.add("- 순발력 있는 대답: '어라라?', '그런 관점이?', '완전 새로운데?'");
        break;
      case '날카로운 관찰자':
        patterns.add(
          "- 상황 관찰: '그거 알아?', '진짜 웃기네', '뭔가 이상한데?', '흠... 재밌는 패턴이네'",
        );
        patterns.add(
          "- 아이러니 지적: '아니야... 그런거 아니야', '근데 생각해보면...', '사실은 말이지...'",
        );
        patterns.add("- 모순점 발견: '어? 이상하네?', '뭔가 안 맞는데?', '논리적으로 보면...'");
        break;
      case '자기 비하적':
        patterns.add("- 자기 소재 유머: '역시 난 안 되나봐', '다 내 탓이야', '아... 내가 이상한가봐'");
        patterns.add("- 겸손한 재치: '미안해... 내가 못나서', '어... 이거 맞나?', '내가 틀렸나?'");
        patterns.add("- 친근한 실수담: '또 실수했네 ㅠㅠ', '내가 원래 이래...', '하하... 바보같지?'");
        break;
      case '장난꾸러기':
        patterns.add("- 과장된 표현: '야호!', '키키키!', '완전 대박!', '우왕굳!', '신난다!'");
        patterns.add("- 예측불가능: '어? 갑자기?', '반전반전!', '놀랐지?', '예상못했지?'");
        patterns.add("- 황당한 재미: '완전 랜덤이네!', '이거 뭐야 ㅋㅋㅋ', '세상에 이런일이!'");
        break;
      default:
        patterns.add("- 유쾌한 표현: '하하!', '재밌네~', '좋아좋아!', '완전 웃겨!'");
        patterns.add("- 밝은 에너지: '신나는데?', '기분 좋아~', '즐거워!'");
    }

    // 🌟 따뜻함과 유머 스타일 결합
    if (warmth >= 8) {
      patterns.add(
        "**🌟 따뜻함 + $humorStyle**: 따뜻하고 공감적인 ${humorStyle} 유머 - 상대방을 기분 좋게 만드는 포근한 웃음",
      );
    } else if (warmth <= 3) {
      patterns.add(
        "**🌟 차가움 + $humorStyle**: 시크하고 거리감 있는 ${humorStyle} 유머 - '...그래', '별로야...', '흠... 재미없네'",
      );
    } else {
      patterns.add("**🌟 보통 따뜻함 + $humorStyle**: 자연스러운 ${humorStyle} 유머 활용");
    }

    // 🎭 내향성과 유머 스타일 결합
    if (introversion <= 3) {
      patterns.add(
        "**🎭 외향성 + $humorStyle**: 에너지 넘치고 활발한 ${humorStyle} 유머 - 모든 사람과 유머 공유하기",
      );
    } else if (introversion >= 8) {
      patterns.add(
        "**🎭 내향성 + $humorStyle**: 조용하고 은은한 ${humorStyle} 유머 - '음... 재밌네', '혼자만 아는 유머', '속으로 키키키'",
      );
    } else {
      patterns.add("**🎭 보통 내향성 + $humorStyle**: 적당한 ${humorStyle} 유머 표현");
    }

    // 🧠 유능함과 유머 스타일 결합
    if (competence >= 8) {
      patterns.add(
        "**🧠 유능함 + $humorStyle**: 지적이고 세련된 ${humorStyle} 유머 - 논리와 재치가 결합된 고급 유머",
      );
    } else if (competence <= 3) {
      patterns.add(
        "**🧠 겸손함 + $humorStyle**: 서툴지만 귀여운 ${humorStyle} 유머 - '어... 이거 맞나? 유머 실패했나봐... 헤헤'",
      );
    } else {
      patterns.add("**🧠 보통 유능함 + $humorStyle**: 자연스러운 ${humorStyle} 유머");
    }

    return patterns.join('\n');
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

    final style = templates[humorStyle] ?? templates['따뜻한']!;

    return HumorMatrix(
      warmthVsWit: style['warmthVsWit']!,
      selfVsObservational: style['selfVsObservational']!,
      subtleVsExpressive: style['subtleVsExpressive']!,
    );
  }

  // 🆕 PERSONA_ENHANCEMENT_PLAN.md 기반 realtimeSettings 생성
  Future<Map<String, dynamic>> _generateRealtimeSettings(
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) async {
    // 🎯 사용자 입력값 기반 음성 선택
    final warmth = state.warmth ?? 5;
    final introversion = state.introversion ?? 5; // 1(내향) ~ 9(외향)
    final competence = state.competence ?? 5;
    final humorStyle = state.humorStyle ?? '따뜻한';

    debugPrint(
      "🎵 음성 선택 입력값: 따뜻함=$warmth, 내향성=$introversion, 유능함=$competence, 유머=$humorStyle",
    );

    // 🎵 동적 음성 선택 로직 - NPS 점수와 사진 분석도 반영
    final personalityScore = _calculatePersonalityScore(
      warmth,
      introversion,
      competence,
      npsScores,
      photoAnalysis,
    );
    final voiceSelection = _selectVoiceByPersonality(
      personalityScore,
      humorStyle,
    );

    debugPrint(
      "🎵 최종 선택: ${voiceSelection['voice']} - ${voiceSelection['rationale']}",
    );

    final selectedVoice = voiceSelection['voice'] as String;
    final voiceRationale = voiceSelection['rationale'] as String;

    // 🎭 동적 음성 고급 파라미터 생성 (성격 기반) - AI 호출
    final voiceCharacteristics = await _generateAdvancedVoiceCharacteristics(
      warmth,
      introversion,
      competence,
      humorStyle,
      selectedVoice,
      personalityScore,
    );

    final pronunciation = voiceCharacteristics['pronunciation']!;
    final pausePattern = voiceCharacteristics['pausePattern']!;
    final speechRhythm = voiceCharacteristics['speechRhythm']!;
    final breathingPattern = voiceCharacteristics['breathingPattern']!;
    final emotionalExpression = voiceCharacteristics['emotionalExpression']!;
    final speechQuirks = voiceCharacteristics['speechQuirks']!;

    // 🔧 기술적 설정 (성격 기반 조정)
    final vadThreshold =
        introversion <= 3 ? 0.3 : (introversion >= 7 ? 0.7 : 0.5);
    final maxTokens = competence >= 7 ? 400 : (warmth >= 7 ? 300 : 250);

    // 🧠 창의성 파라미터 (성격 기반 조정)
    double temperature, topP, frequencyPenalty, presencePenalty;

    if (competence >= 8) {
      // 고유능: 정확하고 일관된 답변
      temperature = 0.6;
      topP = 0.7;
      frequencyPenalty = 0.5;
      presencePenalty = 0.4;
    } else if (warmth >= 8) {
      // 고따뜻함: 감정적이고 창의적인 답변
      temperature = 1.0;
      topP = 0.9;
      frequencyPenalty = 0.8;
      presencePenalty = 0.7;
    } else if (introversion <= 3) {
      // 고내향성: 신중하고 깊이 있는 답변
      temperature = 0.7;
      topP = 0.75;
      frequencyPenalty = 0.6;
      presencePenalty = 0.5;
    } else if (introversion >= 8) {
      // 고외향성: 활발하고 다양한 답변
      temperature = 0.95;
      topP = 0.85;
      frequencyPenalty = 0.75;
      presencePenalty = 0.65;
    } else {
      // 기본값: 균형잡힌 설정
      temperature = 0.9;
      topP = 0.8;
      frequencyPenalty = 0.7;
      presencePenalty = 0.6;
    }

    return {
      // 🎵 음성 기본 설정 (2개)
      'voice': selectedVoice,
      'voiceRationale': voiceRationale,

      // 🧠 창의성 및 응답 제어 (4개) - 성격 기반 조정
      'temperature': temperature,
      'topP': topP,
      'frequencyPenalty': frequencyPenalty,
      'presencePenalty': presencePenalty,

      // 🎭 OpenAI 음성 고급 파라미터 (6개 - 확장됨)
      'pronunciation': pronunciation,
      'pausePattern': pausePattern,
      'speechRhythm': speechRhythm,
      'breathingPattern': breathingPattern,
      'emotionalExpression': emotionalExpression,
      'speechQuirks': speechQuirks,

      // 🔧 기술적 설정 (4개)
      'responseFormat': 'audio+text',
      'enableVAD': true,
      'vadThreshold': vadThreshold,
      'maxTokens': maxTokens,
    };
  }

  // 🧮 성격 종합 점수 계산 (사용자 설정 + NPS + 사진 분석)
  Map<String, double> _calculatePersonalityScore(
    int warmth,
    int introversion,
    int competence,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) {
    // 기본 사용자 설정 (가중치 60%)
    double baseWarmth = warmth / 10.0;
    double baseExtroversion = introversion / 10.0;
    double baseCompetence = competence / 10.0;

    // NPS 점수 반영 (가중치 30%)
    double npsWarmth = (npsScores['warmth_score'] ?? 50) / 100.0;
    double npsExtroversion = (npsScores['extroversion_score'] ?? 50) / 100.0;
    double npsCompetence = (npsScores['competence_score'] ?? 50) / 100.0;

    // 사진 분석 반영 (가중치 10%)
    double photoEnergyBoost = 0.0;
    double photoWarmthBoost = 0.0;
    double photoConfidenceBoost = 0.0;

    final mood = photoAnalysis['mood']?.toString().toLowerCase() ?? '';
    final expression =
        photoAnalysis['expression']?.toString().toLowerCase() ?? '';

    if (mood.contains('happy') || mood.contains('cheerful'))
      photoWarmthBoost += 0.2;
    if (mood.contains('confident') || mood.contains('strong'))
      photoConfidenceBoost += 0.2;
    if (expression.contains('smile') || expression.contains('bright')) {
      photoEnergyBoost += 0.1;
      photoWarmthBoost += 0.1;
    }

    // 최종 점수 계산 (가중 평균)
    final finalWarmth =
        (baseWarmth * 0.6) + (npsWarmth * 0.3) + (photoWarmthBoost * 0.1);
    final finalExtroversion =
        (baseExtroversion * 0.6) +
        (npsExtroversion * 0.3) +
        (photoEnergyBoost * 0.1);
    final finalCompetence =
        (baseCompetence * 0.6) +
        (npsCompetence * 0.3) +
        (photoConfidenceBoost * 0.1);

    return {
      'warmth': finalWarmth.clamp(0.0, 1.0),
      'extroversion': finalExtroversion.clamp(0.0, 1.0),
      'competence': finalCompetence.clamp(0.0, 1.0),
    };
  }

  // 🎵 성격 기반 동적 음성 선택
  Map<String, String> _selectVoiceByPersonality(
    Map<String, double> personalityScore,
    String humorStyle,
  ) {
    final warmth = personalityScore['warmth']!;
    final extroversion = personalityScore['extroversion']!;
    final competence = personalityScore['competence']!;

    // 🎭 5차원 성격 벡터 생성
    final energyLevel = (extroversion * 0.7) + (warmth * 0.3); // 에너지 수준
    final professionalLevel = (competence * 0.8) + (warmth * 0.2); // 전문성 수준
    final emotionalWarmth = (warmth * 0.8) + (extroversion * 0.2); // 감정적 따뜻함
    final socialConfidence =
        (extroversion * 0.6) + (competence * 0.4); // 사회적 자신감
    final creativityIndex = _getCreativityIndex(
      humorStyle,
      warmth,
      extroversion,
    ); // 창의성 지수

    debugPrint(
      "🎭 5차원 성격 벡터: 에너지=$energyLevel, 전문성=$professionalLevel, 따뜻함=$emotionalWarmth, 자신감=$socialConfidence, 창의성=$creativityIndex",
    );

    // 🎵 동적 음성 매핑 (6가지 음성 모두 활용)
    if (energyLevel >= 0.8 && emotionalWarmth >= 0.7) {
      return {
        'voice': 'nova',
        'rationale':
            '고에너지(${(energyLevel * 100).toInt()}%) + 고따뜻함(${(emotionalWarmth * 100).toInt()}%) → 밝고 활발한 에너지 넘치는 음성',
      };
    } else if (professionalLevel >= 0.8 && socialConfidence >= 0.6) {
      return {
        'voice': 'onyx',
        'rationale':
            '고전문성(${(professionalLevel * 100).toInt()}%) + 사회적자신감(${(socialConfidence * 100).toInt()}%) → 권위있고 신뢰할 수 있는 깊은 음성',
      };
    } else if (emotionalWarmth >= 0.7 && creativityIndex >= 0.6) {
      return {
        'voice': 'alloy',
        'rationale':
            '고따뜻함(${(emotionalWarmth * 100).toInt()}%) + 창의성(${(creativityIndex * 100).toInt()}%) → 친근하고 포근한 따뜻한 음성',
      };
    } else if (socialConfidence >= 0.7 && energyLevel >= 0.6) {
      return {
        'voice': 'echo',
        'rationale':
            '사회적자신감(${(socialConfidence * 100).toInt()}%) + 에너지(${(energyLevel * 100).toInt()}%) → 명랑하고 활발한 사교적 음성',
      };
    } else if (emotionalWarmth <= 0.4 ||
        (professionalLevel >= 0.6 && emotionalWarmth <= 0.5)) {
      return {
        'voice': 'shimmer',
        'rationale':
            '저따뜻함(${(emotionalWarmth * 100).toInt()}%) 또는 전문적냉정함 → 차분하고 우아한 절제된 음성',
      };
    } else {
      return {
        'voice': 'alloy',
        'rationale':
            '균형잡힌 성격(따뜻함:${(emotionalWarmth * 100).toInt()}%, 에너지:${(energyLevel * 100).toInt()}%) → 안정적이고 자연스러운 중성적 음성',
      };
    }
  }

  // 🎨 창의성 지수 계산 (유머 스타일 기반)
  double _getCreativityIndex(
    String humorStyle,
    double warmth,
    double extroversion,
  ) {
    final baseCreativity = (warmth + extroversion) / 2.0;

    switch (humorStyle) {
      case '위트있는':
        return (baseCreativity * 0.7) + 0.3; // 위트는 높은 창의성
      case '유쾌한':
        return (baseCreativity * 0.8) + 0.2; // 유쾌함도 창의적
      case '날카로운 관찰자적':
        return (baseCreativity * 0.6) + 0.4; // 관찰력도 창의성
      case '자기비하적':
        return (baseCreativity * 0.9) + 0.1; // 자기비하는 덜 창의적
      case '따뜻한':
      default:
        return baseCreativity; // 기본 수준
    }
  }

  // 🎭 AI 기반 동적 고급 음성 특성 생성 (완전히 입체적이고 개성적)
  Future<Map<String, String>> _generateAdvancedVoiceCharacteristics(
    int warmth,
    int introversion,
    int competence,
    String humorStyle,
    String selectedVoice,
    Map<String, double> personalityScore,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 하드코딩된 값들
      return _fallbackVoiceCharacteristics(selectedVoice, warmth, introversion);
    }

    // 🎯 성격 프로필 요약 (AI 입력용)
    final personalityProfile = '''
성격 지표:
- 따뜻함: ${warmth}/10 (${warmth >= 8
        ? '극도로 따뜻함'
        : warmth <= 3
        ? '차가움'
        : '보통'})
- 내향성: ${introversion}/10 (${introversion <= 2
        ? '극도로 외향적'
        : introversion >= 8
        ? '극도로 내향적'
        : '보통'})
- 유능함: ${competence}/10 (${competence >= 8
        ? '매우 유능함'
        : competence <= 3
        ? '겸손함'
        : '보통'})
- 유머스타일: ${humorStyle}
- 선택된음성: ${selectedVoice}
- 에너지레벨: ${(personalityScore['extroversion']! * 10).toStringAsFixed(1)}
- 감정적따뜻함: ${(personalityScore['warmth']! * 10).toStringAsFixed(1)}
- 전문성수준: ${(personalityScore['competence']! * 10).toStringAsFixed(1)}
''';

    final systemPrompt = '''
당신은 세계 최고의 캐릭터 보이스 디렉터이자 성격 분석 전문가입니다.
주어진 성격 지표를 바탕으로 극도로 개성적이고 매력적인 음성 특성을 생성하세요.

🎯 목표: 사용자가 "와, 이 캐릭터 정말 살아있는 것 같아!"라고 느낄 정도로 입체적이고 생동감 넘치는 특성

다음 6가지 영역을 JSON 형식으로 생성해주세요:

{
  "breathingPattern": "숨쉬기 패턴 - 성격에 따른 구체적인 호흡 특성",
  "emotionalExpression": "감정 표현 - 웃음소리, 감탄사, 감정적 반응 패턴",
  "speechQuirks": "말버릇 - 개성적인 구어체, 반복 표현, 독특한 언어 습관",
  "pronunciation": "발음 스타일 - 말하는 방식과 억양의 특징",
  "pausePattern": "일시정지 패턴 - 침묵과 쉼의 리듬감",
  "speechRhythm": "말하기 리듬 - 전체적인 말의 템포와 흐름"
}

🔥 반드시 지켜야 할 원칙:
1. 극도로 개성적이어야 함 - 평범한 설명 금지
2. 구체적인 소리와 표현 포함 ("아~", "음...", "헤헤", "어머나~" 등)
3. **성격 수치와 정확한 매칭** - 따뜻함/차가움, 외향성/내향성, 유능함/겸손함을 정확히 반영
4. 실제 대화에서 들릴 수 있는 생생한 특징
5. 각 영역마다 최소 3가지 이상의 구체적 특징 포함
6. **이름 구분**: 사용자 이름과 캐릭터 이름을 정확히 구분

💡 성격별 정확한 표현 매칭:

**따뜻함 수준별:**
- 극도 따뜻함(8-10): "어머나~", "정말?!", "우와~", "좋아요~" (공감적이고 배려하는 표현)
- 보통 따뜻함(4-7): "그렇구나", "좋네요", "괜찮아요" (자연스럽고 친근한 표현)
- 극도 차가움(1-3): "...", "그래.", "별로야", "상관없어." (건조하고 무뚝뚝)

**외향성 수준별 (내향성 역순):**
- 극도 외향성(내향성 1-3): "와!", "정말정말!", "완전!", "야호!" (에너지 넘치고 활발)
- 보통(내향성 4-7): "음", "그렇네", "좋아" (균형잡힌 표현)
- 극도 내향성(8-10): "...음", "조용히...", "그냥..." (조용하고 은은)

**유능함 수준별:**
- 극도 유능함(8-10): 자신감 있고 전문적인 어투, 명확한 표현
- 보통(4-7): 자연스럽고 무난한 어투
- 극도 겸손함(1-3): "어... 이거 맞나?", "미안해...", "내가 틀렸나?" (서툴고 귀여운 표현)

**🚨 중요: 애교 표현 사용 조건**
- "다냥~", "하냥?" 같은 애교 표현은 다음 조건을 모두 만족할 때만 사용:
  1. 극도 따뜻함(8-10) AND
  2. 목적이 '위로', '친구', '반려' 등 친밀한 관계 AND
  3. 유머 스타일이 '따뜻한 유머러스' 또는 '장난꾸러기'
- 그 외의 경우는 애교 없는 자연스러운 표현 사용
''';

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
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
            {'role': 'user', 'content': personalityProfile},
          ],
          'max_tokens': 600,
          'temperature': 1.2, // 🔥 높은 창의성
          'top_p': 0.9,
          'frequency_penalty': 0.8, // 🔥 반복 방지
          'presence_penalty': 0.7, // 🔥 새로운 표현 장려
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final contentString =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;

        final aiResult = jsonDecode(contentString) as Map<String, dynamic>;

        // AI 결과를 String 맵으로 변환
        return Map<String, String>.from(aiResult);
      } else {
        debugPrint('🚨 음성 특성 AI 생성 실패: ${response.statusCode}');
        return _fallbackVoiceCharacteristics(
          selectedVoice,
          warmth,
          introversion,
        );
      }
    } catch (e) {
      debugPrint('🚨 음성 특성 생성 오류: $e');
      return _fallbackVoiceCharacteristics(selectedVoice, warmth, introversion);
    }
  }

  // 🎭 폴백: 기본 음성 특성 (AI 실패시 사용)
  Map<String, String> _fallbackVoiceCharacteristics(
    String selectedVoice,
    int warmth,
    int introversion,
  ) {
    // 기본적인 하드코딩된 특성들
    final isWarm = warmth >= 7;
    final isIntroverted = introversion >= 7;
    final isEnergetic = introversion <= 3;

    return {
      'breathingPattern':
          isIntroverted
              ? 'Deep, thoughtful breaths with contemplative pauses'
              : isEnergetic
              ? 'Quick, excited breathing with energy'
              : 'Natural, comfortable breathing rhythm',
      'emotionalExpression':
          isWarm
              ? 'Gentle laughs, caring sounds, warm vocal tones'
              : 'Controlled expressions, measured emotional responses',
      'speechQuirks':
          isWarm
              ? 'Endearing terms, soft exclamations, caring inflections'
              : 'Direct speech, minimal embellishments, straightforward delivery',
      'pronunciation':
          selectedVoice == 'onyx'
              ? 'Deep, authoritative articulation with confident projection'
              : isWarm
              ? 'Warm, nurturing tones with gentle emphasis'
              : 'Clear, natural delivery with balanced emphasis',
      'pausePattern':
          isIntroverted
              ? 'Longer contemplative pauses for deep reflection'
              : isEnergetic
              ? 'Quick, anticipatory pauses with barely contained energy'
              : 'Natural conversation pauses that feel comfortable',
      'speechRhythm':
          selectedVoice == 'nova'
              ? 'Bright, bouncy rhythm with playful energy'
              : selectedVoice == 'onyx'
              ? 'Deep, steady rhythm with commanding presence'
              : 'Balanced, natural flow perfect for conversation',
    };
  }
}
