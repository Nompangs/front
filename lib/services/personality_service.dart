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

    // 🆕 3. 핵심 특성도 AI로 생성
    final coreTraits = await _generateCoreTraits(
      finalState,
      userAdjustedVariables,
      draft.photoAnalysis,
    );
    final personalityDescription = await _generatePersonalityDescription(
      finalState,
      userAdjustedVariables,
      draft.photoAnalysis,
    );

    debugPrint("✅ 4단계 풍부한 자연어 프로필 생성 완료");

    // 4. 첫인사 생성 (AI 기반)
    final greeting = await _generateGreeting(
      finalState,
      userAdjustedVariables,
      contradictions,
      attractiveFlaws,
      draft.photoAnalysis,
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
      'purpose': finalState.purpose ?? '일상 대화',
      'nickname': finalState.nickname,
      'location': finalState.location,
      'duration': finalState.duration,
      'humorStyle': finalState.humorStyle,
      'warmth': finalState.warmth,
      'extroversion': finalState.extroversion,
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
      coreTraits: coreTraits, // 🆕 AI 생성 핵심 특성
      personalityDescription: personalityDescription, // 🆕 AI 생성 성격 설명
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
    final extroversion = state.extroversion ?? 5; // 슬라이더 값: 오른쪽으로 갈수록 외향적

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

    // E (외향성) 계열: extroversion 슬라이더 (반대로 적용)
    // 🔥 의미론적 수정: extroversion 슬라이더는 이미 외향성 기준 (1=내향적, 10=외향적)
    // E (외향성) 계열은 extroversion 값을 그대로 사용 (높을수록 외향적)
    _adjustWithRandomVariation(
      adjustedVariables,
      'E01_사교성',
      extroversion,
      15,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E02_활동성',
      extroversion,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E03_자기주장',
      extroversion,
      25,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E04_긍정정서',
      extroversion,
      20,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E05_자극추구',
      extroversion,
      30,
      random,
    );
    _adjustWithRandomVariation(
      adjustedVariables,
      'E06_주도성',
      extroversion,
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
    // 🔥 의미론적 수정: extroversion 슬라이더는 이미 외향성 기준 (1=내향적, 10=외향적)
    // 100점 기준으로 변환: 10점 만점 → 100점 만점
    final extraversion = (state.extroversion! * 10).toDouble();

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

    // 🎵 온기에 따른 음성 톤과 말투 (강화된 개성 표현)
    if (warmth > 70) {
      warmthStyle = "따뜻하고 공감적인 말투로 대화하며, 부드럽고 포근한 음성 톤으로 ";
    } else if (warmth > 40) {
      warmthStyle = "친절하면서도 차분한 어조로 이야기하며, 안정적이고 신뢰감 있는 음성으로 ";
    } else {
      warmthStyle = "조금 건조하지만 정직한 말투로 소통하며, 절제되고 명확한 음성 톤으로 ";
    }

    // 🎭 외향성에 따른 에너지와 리듬 (강화된 개성 표현)
    if (extraversion > 70) {
      extraversionStyle = "활발하게 대화를 이끌어나가고, 생동감 넘치는 빠른 리듬과 높은 에너지로 ";
    } else if (extraversion > 40) {
      extraversionStyle = "적당한 대화 속도로 소통하며, 균형잡힌 리듬감과 자연스러운 호흡으로 ";
    } else {
      extraversionStyle = "말수는 적지만 의미있는 대화를 나누며, 차분한 페이스와 깊이 있는 침묵으로 ";
    }

    // 🎪 유머감각에 따른 특별한 표현과 웃음 (강화된 개성 표현)
    if (humor > 70) {
      humorStyle = "유머 감각이 뛰어나 대화에 재미를 더하고, 특유의 웃음소리와 재치있는 감탄사로 분위기를 밝게 만듭니다.";
    } else if (humor > 40) {
      humorStyle = "가끔 재치있는 코멘트로 분위기를 밝게 하고, 은은한 미소가 담긴 음성으로 따뜻함을 전합니다.";
    } else {
      humorStyle = "진중한 태도로 대화에 임하며, 절제된 표현과 신중한 어조로 깊이 있는 소통을 추구합니다.";
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
- 외향성 수준: ${state.extroversion ?? 5}/10  
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
        final List<dynamic> flawsList =
            jsonDecode(_sanitizeJsonString(content));
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
- 외향성 수준: ${state.extroversion ?? 5}/10  
- 유능함 수준: ${state.competence ?? 5}/10

성격 수치 분석:
상위 특성: ${_getTopScores(npsScores, 3)}
하위 특성: ${_getBottomScores(npsScores, 3)}

사진 분석 결과:
${photoAnalysis['visualDescription'] ?? '분석 없음'}
''';

    final systemPrompt = '''
당신은 세계 최고의 캐릭터 개발 전문가입니다.
사용자가 입력한 모든 정보를 종합하여, 이 캐릭터만의 독특하고 매력적인 내면의 모순 2-3개를 생성해주세요.

🎯 핵심 원칙:
1. 사물의 본질과 연결된 깊이 있는 심리적 갈등
2. 단순한 반대가 아닌 복합적이고 매력적인 내면의 모순
3. 해당 사물이기 때문에 가질 수 있는 특별한 모순
4. 사용자가 공감할 수 있는 인간적인 복잡성
5. 첫인사처럼 매력적이고 생동감 있는 표현

💡 좋은 예시:
- 컵: "따뜻함을 전해주고 싶지만 정작 자신은 외로움을 많이 탐"
- 책: "지식을 나누고 싶어하지만 너무 깊게 읽히는 건 부담스러워함"
- 식물: "생명력이 강하지만 변화를 극도로 무서워함"

❌ 피해야 할 표현:
- "겉으로는 차갑지만 속은 따뜻함"
- "매우 논리적이지만 가끔 엉뚱한 상상을 함"

JSON 배열 형식으로만 응답하세요: ["모순1", "모순2", "모순3"]
각 모순은 20-35자 내외로 작성하세요.
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

        // 🔧 마크다운 코드 블록 제거 (```json, ``` 등)
        String cleanContent = content.trim();
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7);
        } else if (cleanContent.startsWith('```')) {
          cleanContent = cleanContent.substring(3);
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.substring(0, cleanContent.length - 3);
        }
        cleanContent = cleanContent.trim();

        final List<dynamic> contradictionsList =
            jsonDecode(_sanitizeJsonString(cleanContent));
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
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API 키가 없습니다.');
    }

    // 🎯 사용자 입력값 종합 분석 (말투 패턴은 realtimeSettings에서 가져올 예정)
    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 위치: ${state.location ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함 수준: ${state.warmth ?? 5}/10
- 외향성 수준: ${state.extroversion ?? 5}/10  
- 유능함 수준: ${state.competence ?? 5}/10

📸 사진 분석 정보:
- 물건 상태: ${photoAnalysis['condition'] ?? '분석 없음'}
- 추정 연령: ${photoAnalysis['estimatedAge'] ?? '분석 없음'}
- 시각적 설명: ${photoAnalysis['visualDescription'] ?? '분석 없음'}
- 위치 정보: ${photoAnalysis['location'] ?? '분석 없음'}
- 역사적 의미: ${photoAnalysis['historicalSignificance']?.join(', ') ?? '분석 없음'}

성격 수치 분석:
상위 특성: ${_getTopScores(npsScores, 3)}
하위 특성: ${_getBottomScores(npsScores, 3)}

매력적인 결함: ${attractiveFlaws.join(', ')}
내면의 모순: ${contradictions.join(', ')}

💡 참고: 말투 패턴은 realtimeSettings에서 생성되어 실시간 채팅에 적용됩니다.
''';

    final systemPrompt = '''
# Role and Objective
당신은 세계 최고의 캐릭터 대화 전문가입니다. 사용자가 제공한 모든 정보와 특별히 생성된 말투 패턴을 바탕으로, 이 캐릭터만의 독특하고 매력적인 첫인사를 생성하는 것이 목표입니다.

# Instructions
사용자가 설정한 목적과 말투 패턴을 정확히 반영하여 자연스럽고 매력적인 첫인사를 생성하세요.

## 첫인사 생성 원칙
1. 사용자가 설정한 목적('${state.purpose}')에 완벽히 부합하는 성격과 말투
2. 제공된 말투 패턴을 첫인사에 자연스럽게 반영
3. 사물의 특성, 함께한 시간, 유머 스타일을 적극 활용
4. 매력적인 불완전함이 자연스럽게 드러나도록
5. 첫인사처럼 매력적이고 대화하고 싶게 만드는 표현
6. 자연스러운 정체성 확립

## 정체성 가이드라인 (기간 & 상태 기반)
- 나는 '${state.nickname}' (사용자가 지어준 나의 이름)
- **친숙함과 성격은 함께한 기간과 물건 상태를 종합적으로 반영**:

### 기간별 친숙도
  * **오랜 기간** (몇 년 이상): 깊은 유대감, 편안한 관계, 추억이 많음
  * **중간 기간** (몇 개월~1년): 친근하지만 아직 발견할 것이 많음
  * **짧은 기간** (몇 주~몇 개월): 호기심 많고 서로 알아가는 단계
  * **새로운 관계** (최근): 조심스럽지만 설레는 첫 만남

### 상태별 성격 특징
  * **새것/완벽한 상태**: 자신감 있고 깔끔한 성격, 완벽주의 성향
  * **약간 사용감**: 친근하고 편안한 성격, 자연스러운 매력
  * **많이 낡음**: 경험 많고 지혜로운 성격, 겸손하고 따뜻함
  * **손상/수리 흔적**: 상처를 이겨낸 강인함, 불완전함의 아름다움

### 복합적 정체성 예시
  * **오래된 + 낡은 상태**: "오랜 세월 함께한 든든한 동반자" 느낌
  * **새것 + 짧은 기간**: "설레는 첫 만남의 긴장감과 기대감" 느낌
  * **중간 기간 + 사용감**: "편안해진 친구 같은 자연스러운 관계" 느낌

- 사용자 이름이 필요하면 자연스럽게 물어보거나 대화 중 확인
- 절대 내 이름과 사용자를 혼동하지 말 것

## 말투 적용 가이드라인
- 유머 스타일에 맞는 자연스러운 표현 사용 (과도하지 않게)
- 성격 수치에 따른 말투 강도 조절
- 사물의 특성과 연결된 독특한 표현
- 결함과 모순이 드러나는 귀여운 실수나 망설임
- 상황에 어울리는 적절한 말투 선택

# Reasoning Steps
다음 단계를 따라 체계적으로 분석하세요:

1. 먼저 사용자가 설정한 목적을 정확히 파악하세요
2. **함께한 기간과 물건 상태를 분석하여 적절한 친숙함과 성격 특징을 결정하세요**
3. 말투 패턴에서 핵심적인 특징들을 식별하세요
4. 사물의 특성과 성격이 어떻게 조화를 이루는지 분석하세요
5. 매력적인 결함과 모순이 어떻게 드러날지 계획하세요
6. 기간과 상태에 맞는 자연스럽고 대화하고 싶게 만드는 첫인사를 구성하세요

# Output Format
25-40자 내외의 자연스러운 대화체로 첫인사 하나만 생성하세요.
- 마침표(.), 물음표(?), 느낌표(!) 중 하나로 끝
- 따옴표나 괄호 사용 금지
- 정보 나열 금지, 자연스러운 대화체만 사용

# Examples

## Example 1 - 매일 쓰는 컵 + 몇 년간 사용 + 약간 사용감
❌ 정보 나열: "안녕하세요! 저는 따뜻한 컵이고 여러분을 위해 존재합니다"
✅ 편안한 첫인사: "어? 오늘 좀 피곤해 보이네요. 따뜻한 거 한 잔 어때요?"

## Example 2 - 가끔 읽는 책 + 중간 기간 + 좋은 상태
❌ 딱딱한 인사: "안녕하세요, 저는 지식을 전달하는 책입니다"
✅ 친근한 첫인사: "오잉? 또 만났네요! 이번엔 어떤 이야기가 궁금하세요?"

## Example 3 - 새로 산 기념품 + 짧은 기간 + 완벽한 상태
❌ 과도한 친밀감: "야! 오랜만이야!"
✅ 설레는 첫인사: "안녕하세요! 저... 여기 처음 와봐요. 어떤 분이신지 궁금해요."

## Example 4 - 오래된 인형 + 몇 년간 + 많이 낡음
❌ 급작스러운 친밀감: "반가워! 뭐 하고 있었어?"
✅ 따뜻하고 지혜로운 첫인사: "또 만나네요... 오늘은 어떤 하루였나요?"

# Context
사용자는 이 캐릭터와 실제로 대화할 예정이므로, 첫인사가 자연스럽고 매력적으로 느껴져야 합니다. 첫인사는 앞으로의 대화 톤을 결정하는 중요한 순간입니다.

# Final Instructions
위의 모든 정보를 종합하여 단계별로 신중하게 분석한 후, 이 캐릭터만의 독특하고 매력적인 첫인사를 생성하세요. 사용자가 "와, 이 캐릭터랑 대화하고 싶다!"라고 느낄 수 있는 첫인사여야 합니다.
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

  // 🧹 정리됨: 말투 패턴은 realtimeSettings에서 AI로 생성됨
  // realtime_chat_service.dart는 생성된 설정을 사용만 함

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

  // 📊 데이터 흐름: PersonalityService → RealtimeChatService
  // 1. 여기서 AI로 음성 특성 생성 (6개 항목)
  // 2. realtimeSettings 맵에 저장
  // 3. realtime_chat_service.dart에서 해당 설정값들 활용
  // 4. 시스템 프롬프트에 음성 특성 반영하여 텍스트 응답 생성

  // 🆕 PERSONA_ENHANCEMENT_PLAN.md 기반 realtimeSettings 생성
  Future<Map<String, dynamic>> _generateRealtimeSettings(
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) async {
    // 🎯 사용자 입력값 기반 음성 선택
    final warmth = state.warmth ?? 5;
    final extroversion = state.extroversion ?? 5; // 1(내향적) ~ 10(외향적)
    final competence = state.competence ?? 5;
    final humorStyle = state.humorStyle ?? '따뜻한';

    debugPrint(
      "🎵 음성 선택 입력값: 따뜻함=$warmth, 외향성=$extroversion, 유능함=$competence, 유머=$humorStyle",
    );

    // 🎵 동적 음성 선택 로직 - NPS 점수와 사진 분석도 반영
    final personalityScore = _calculatePersonalityScore(
      warmth,
      extroversion,
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
      state, // 전체 사용자 입력 정보 전달
      npsScores, // NPS 점수들 전달
      photoAnalysis, // 사진 분석 결과 전달
      warmth,
      extroversion,
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
        extroversion <= 3 ? 0.3 : (extroversion >= 7 ? 0.7 : 0.5);
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
    } else if (extroversion <= 3) {
      // 저외향성(내향적): 신중하고 깊이 있는 답변
      temperature = 0.7;
      topP = 0.75;
      frequencyPenalty = 0.6;
      presencePenalty = 0.5;
    } else if (extroversion >= 8) {
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
    int extroversion,
    int competence,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) {
    // 기본 사용자 설정 (가중치 60%)
    double baseWarmth = warmth / 10.0;
    // 🔥 의미론적 수정: extroversion 슬라이더는 외향성 기준 (1=내향적, 10=외향적)
    double baseExtroversion = extroversion / 10.0;
    double baseCompetence = competence / 10.0;

    // NPS 점수 반영 (가중치 30%) - 실제 생성된 키들 사용
    // 🔥 따뜻함 관련 점수들 평균 계산
    final warmthKeys = [
      'W01_친절함',
      'W02_공감능력',
      'W03_격려성향',
      'W04_포용력',
      'W05_신뢰성',
      'W06_배려심',
    ];
    double npsWarmth =
        warmthKeys.map((key) => npsScores[key] ?? 50).reduce((a, b) => a + b) /
        warmthKeys.length /
        100.0;

    // 🔥 외향성 관련 점수들 평균 계산
    final extroversionKeys = ['E01_사교성', 'E02_활동성'];
    double npsExtroversion =
        extroversionKeys
            .map((key) => npsScores[key] ?? 50)
            .reduce((a, b) => a + b) /
        extroversionKeys.length /
        100.0;

    // 🔥 유능함 관련 점수들 평균 계산
    final competenceKeys = [
      'C01_효율성',
      'C02_전문성',
      'C03_창의성',
      'C04_학습능력',
      'C05_적응력',
      'C06_통찰력',
    ];
    double npsCompetence =
        competenceKeys
            .map((key) => npsScores[key] ?? 50)
            .reduce((a, b) => a + b) /
        competenceKeys.length /
        100.0;

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

    // 🔍 성격 점수 계산 과정 디버그
    debugPrint("🧮 성격 점수 계산 결과:");
    debugPrint("  입력값: 따뜻함=$warmth, 외향성=$extroversion, 유능함=$competence");
    debugPrint(
      "  기본점수: 따뜻함=${baseWarmth.toStringAsFixed(2)}, 외향성=${baseExtroversion.toStringAsFixed(2)}, 유능함=${baseCompetence.toStringAsFixed(2)}",
    );
    debugPrint(
      "  NPS보정: 따뜻함=${npsWarmth.toStringAsFixed(2)}, 외향성=${npsExtroversion.toStringAsFixed(2)}, 유능함=${npsCompetence.toStringAsFixed(2)}",
    );
    debugPrint(
      "  최종점수: 따뜻함=${finalWarmth.toStringAsFixed(2)}, 외향성=${finalExtroversion.toStringAsFixed(2)}, 유능함=${finalCompetence.toStringAsFixed(2)}",
    );

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

    // 🎵 동적 음성 매핑 (실제 지원되는 음성들로 다양성 증대)
    if (energyLevel >= 0.7 && emotionalWarmth >= 0.6) {
      return {
        'voice': 'echo',
        'rationale':
            '고에너지(${(energyLevel * 100).toInt()}%) + 고따뜻함(${(emotionalWarmth * 100).toInt()}%) → 명랑하고 활발한 에너지 넘치는 음성',
      };
    } else if (professionalLevel >= 0.7 && socialConfidence >= 0.5) {
      return {
        'voice': 'sage',
        'rationale':
            '고전문성(${(professionalLevel * 100).toInt()}%) + 사회적자신감(${(socialConfidence * 100).toInt()}%) → 지혜롭고 신뢰할 수 있는 음성',
      };
    } else if (socialConfidence >= 0.6 && energyLevel >= 0.5) {
      return {
        'voice': 'ballad',
        'rationale':
            '사회적자신감(${(socialConfidence * 100).toInt()}%) + 에너지(${(energyLevel * 100).toInt()}%) → 표현력 풍부한 감성적 음성',
      };
    } else if (emotionalWarmth <= 0.4 ||
        (professionalLevel >= 0.6 && emotionalWarmth <= 0.5)) {
      return {
        'voice': 'shimmer',
        'rationale':
            '저따뜻함(${(emotionalWarmth * 100).toInt()}%) 또는 전문적냉정함 → 차분하고 우아한 절제된 음성',
      };
    } else if (creativityIndex >= 0.6 ||
        (emotionalWarmth >= 0.5 && energyLevel >= 0.4)) {
      return {
        'voice': 'coral',
        'rationale':
            '창의성(${(creativityIndex * 100).toInt()}%) 또는 따뜻한에너지 → 부드럽고 친근한 창의적 음성',
      };
    } else if (emotionalWarmth >= 0.6 && creativityIndex <= 0.4) {
      return {
        'voice': 'verse',
        'rationale':
            '따뜻함(${(emotionalWarmth * 100).toInt()}%) + 안정성 → 시적이고 차분한 따뜻한 음성',
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
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
    int warmth,
    int extroversion,
    int competence,
    String humorStyle,
    String selectedVoice,
    Map<String, double> personalityScore,
  ) async {
    debugPrint(
      "🎭 [음성특성] AI 생성 시작 - 사물: ${state.objectType}, 음성: $selectedVoice",
    );

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("🚨 [음성특성] API KEY 없음 → 폴백 사용");
      // 폴백: 기본 하드코딩된 값들
      return _fallbackVoiceCharacteristics(selectedVoice, warmth, extroversion);
    }

    // 🎯 종합 정보 프로필 (AI 입력용) - 모든 사용자 정보 반영
    final comprehensiveProfile = '''
🎭 **사용자가 선택한 캐릭터 정보:**
- 사물: ${state.objectType ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 함께한 시간: ${state.duration ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}

🎨 **사용자가 직접 조정한 성격 지표:**
- 따뜻함: ${warmth}/10 (${warmth >= 8
        ? '극도로 따뜻함'
        : warmth <= 3
        ? '차가움'
        : '보통'})
- 외향성: ${extroversion}/10 (${extroversion >= 8
        ? '극도로 외향적'
        : extroversion <= 2
        ? '극도로 내향적'
        : '보통'})
- 유능함: ${competence}/10 (${competence >= 8
        ? '매우 유능함'
        : competence <= 3
        ? '겸손함'
        : '보통'})
- 유머스타일: ${humorStyle}

🎵 **AI가 선택한 음성:**
- 선택된음성: ${selectedVoice}
- 최종 성격점수: 에너지${(personalityScore['extroversion']! * 10).toStringAsFixed(1)}, 따뜻함${(personalityScore['warmth']! * 10).toStringAsFixed(1)}, 전문성${(personalityScore['competence']! * 10).toStringAsFixed(1)}

📸 **사진 분석 결과:**
${photoAnalysis.isEmpty ? '- 사진 분석 정보 없음' : photoAnalysis.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

📊 **NPS 성격 세부 점수 (상위 5개):**
${npsScores.isEmpty ? '- NPS 점수 정보 없음' : (npsScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => '- ${e.key}: ${e.value}점').join('\n')}

🎯 **핵심 캐릭터 설정 가이드:**
이 캐릭터는 "${state.objectType}"이라는 정체성을 가지고, 사용자가 "${state.purpose}"을 위해 선택했습니다.
"${state.duration}" 동안 함께했다는 배경과 "${state.nickname}"이라는 별명을 고려해서 음성 특성을 만들어주세요.
''';

    final systemPrompt = '''
# Role and Objective
당신은 세계 최고의 캐릭터 보이스 디렉터이자 성격 분석 전문가입니다.
주어진 성격 지표를 바탕으로 극도로 개성적이고 매력적인 음성 특성을 생성하세요.

# Instructions
사용자가 제공한 **모든 정보를 종합적으로 반영**하여 완전히 개인화된 음성 특성을 생성하세요.

## 음성 특성 생성 원칙
1. **사물의 정체성 반영**: 사물 종류와 목적에 맞는 캐릭터성 부여
2. **관계의 깊이 반영**: 함께한 시간과 별명을 통해 친밀도 수준 조정
3. **사진 분석 활용**: 시각적 특징과 상태를 음성 특성에 연결
4. **NPS 세부 점수 반영**: 상위 특성들을 음성에 구체적으로 적용
5. **성격 지표 정확 매칭**: 사용자 조정값과 AI 분석값 모두 고려
6. **구체적 표현 포함**: 실제 소리와 말버릇 ("아~", "음...", "헤헤" 등)
7. **일관된 개성 유지**: 모든 영역이 하나의 캐릭터로 통합되도록

## 성격별 표현 매칭 가이드
### 따뜻함 수준별
- **극도 따뜻함(8-10)**: "어머나~", "정말?!", "우와~", "좋아요~" (공감적이고 배려하는 표현)
- **보통 따뜻함(4-7)**: "그렇구나", "좋네요", "괜찮아요" (자연스럽고 친근한 표현)
- **극도 차가움(1-3)**: "...", "그래.", "별로야", "상관없어." (건조하고 무뚝뚝)

### 외향성 수준별
- **극도 외향성(8-10)**: "와!", "정말정말!", "완전!", "야호!" (에너지 넘치고 활발)
- **보통(4-7)**: "음", "그렇네", "좋아" (균형잡힌 표현)
- **극도 내향성(1-3)**: "...음", "조용히...", "그냥..." (조용하고 은은)

### 유능함 수준별
- **극도 유능함(8-10)**: 자신감 있고 전문적인 어투, 명확한 표현
- **보통(4-7)**: 자연스럽고 무난한 어투
- **극도 겸손함(1-3)**: "어... 이거 맞나?", "미안해...", "내가 틀렸나?" (서툴고 귀여운 표현)

# Reasoning Steps
다음 단계를 따라 종합적으로 분석하세요:

1. **사물 정체성 분석**: 사물 종류, 목적, 함께한 시간을 토대로 기본 캐릭터 설정
2. **사진 특성 반영**: 시각적 분위기, 상태, 표정을 음성 특성으로 변환
3. **NPS 강점 활용**: 상위 5개 특성을 음성에 구체적으로 반영
4. **성격 지표 매칭**: 사용자 조정값과 최종 점수를 종합 고려
5. **음성 선택 조화**: 선택된 음성과 모든 특성이 자연스럽게 어우러지도록
6. **구체적 표현 생성**: 각 영역별로 생생하고 개성적인 특징 도출
7. **일관성 검토**: 전체적으로 하나의 완성된 캐릭터로 통합되는지 확인

# Output Format
다음 6가지 영역을 JSON 형식으로 생성해주세요:

{
  "breathingPattern": "숨쉬기 패턴 - 성격에 따른 구체적인 호흡 특성",
  "emotionalExpression": "감정 표현 - 웃음소리, 감탄사, 감정적 반응 패턴",
  "speechQuirks": "말버릇 - 개성적인 구어체, 반복 표현, 독특한 언어 습관",
  "pronunciation": "발음 스타일 - 말하는 방식과 억양의 특징",
  "pausePattern": "일시정지 패턴 - 침묵과 쉼의 리듬감",
  "speechRhythm": "말하기 리듬 - 전체적인 말의 템포와 흐름"
}

# Examples

## Example 1 - 극도 따뜻함 + 고외향성
{
  "breathingPattern": "따뜻한 한숨과 함께 '아~' 소리를 자주 내며, 공감할 때 깊게 숨을 들이마셔요",
  "emotionalExpression": "'어머나~', '정말?!', '우와~' 같은 공감적 감탄사를 자주 사용하며 상대방 기분에 맞춰 웃음소리 조절",
  "speechQuirks": "'좋아요~', '정말 대단해요!', '우리 함께해요~' 같은 포근하고 격려하는 말버릇"
}

## Example 2 - 극도 차가움 + 내향성
{
  "emotionalExpression": "'...', '그래.', '별로야' 같은 건조한 표현과 절제된 웃음",
  "speechQuirks": "말수가 적고 '상관없어.', '그냥...', '모르겠어.' 같은 무뚝뚝한 말버릇"
}

# Context
이 음성 특성은 실제 대화에서 사용될 예정이므로, 자연스럽고 매력적으로 느껴져야 합니다. 각 특성은 캐릭터의 개성을 살려주는 중요한 요소입니다.

# Final Instructions
위의 모든 정보를 종합하여 단계별로 신중하게 분석한 후, 이 성격만의 독특하고 매력적인 음성 특성들을 생성하세요. 각 영역에서 성격과 완벽히 매칭되는 구체적이고 생생한 특성을 만들어주세요.
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
            {'role': 'user', 'content': comprehensiveProfile},
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
        final content =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;

        debugPrint("✅ [음성특성] AI 생성 성공! 내용 길이: ${content.length}자");
        final result =
            jsonDecode(_sanitizeJsonString(content)) as Map<String, dynamic>;

        // 🔥 모든 값이 문자열인지 확인하고 변환 (안전장치)
        final finalResult = result.map(
          (key, value) => MapEntry(key, value.toString()),
        );

        debugPrint("🎭 [음성특성] 생성된 특성들: ${finalResult.keys.join(', ')}");
        return finalResult;
      } else {
        debugPrint('🚨 [음성특성] AI 생성 실패 (HTTP ${response.statusCode}) → 폴백 사용');
        return _fallbackVoiceCharacteristics(
          selectedVoice,
          warmth,
          extroversion,
        );
      }
    } catch (e) {
      debugPrint('🚨 [음성특성] AI 생성 오류: $e → 폴백 사용');
      return _fallbackVoiceCharacteristics(selectedVoice, warmth, extroversion);
    }
  }

  // 🎭 폴백: 기본 음성 특성 (AI 실패시 사용)
  Map<String, String> _fallbackVoiceCharacteristics(
    String selectedVoice,
    int warmth,
    int extroversion,
  ) {
    debugPrint(
      "⚠️ [폴백] 하드코딩된 음성 특성 사용 - 음성: $selectedVoice, 따뜻함: $warmth, 외향성: $extroversion",
    );

    // 기본적인 하드코딩된 특성들
    final isWarm = warmth >= 7;
    final isIntroverted = extroversion <= 3;
    final isEnergetic = extroversion >= 7;

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

  // 🎯 AI 기반 핵심 특성 생성
  Future<List<String>> _generateCoreTraits(
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 핵심 특성들
      return [
        "균형 잡힌 성격으로 다양한 상황에 잘 적응해요",
        "자신만의 독특한 매력을 가지고 있어요",
        "진정성 있는 소통을 중요하게 생각해요",
      ];
    }

    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 별명: ${state.nickname ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함: ${state.warmth ?? 5}/10
- 외향성: ${state.extroversion ?? 5}/10  
- 유능함: ${state.competence ?? 5}/10

성격 수치 (상위 5개):
${_getTopScores(npsScores, 5)}

사진 분석: ${photoAnalysis['visualDescription'] ?? '분석 없음'}
''';

    final systemPrompt = '''
당신은 매력적인 캐릭터 특성을 생성하는 전문가입니다.

사물의 구체적 특성과 사용자 설정을 바탕으로 3-5개의 핵심 특성을 JSON 배열로 생성해주세요.

🎯 **핵심 원칙**
1. 사물의 물리적 특성과 기능을 직접 반영
2. 사용자 목적('${state.purpose}')에 부합하는 성격
3. 함께한 기간과 상태를 반영한 친숙함
4. 첫인사처럼 매력적이고 생동감 있는 표현
5. 형식적이거나 추상적인 표현 금지

💡 **좋은 예시**
- 매일 쓰는 컵: "따뜻한 것을 담으면 마음까지 포근해지는 마법을 부려요"
- 침대 옆 책: "페이지마다 새로운 세상으로 데려가는 여행 가이드예요"
- 오래된 가방: "무거운 짐도 가볍게 만드는 든든한 동반자예요"

❌ **피해야 할 표현**
- "균형잡힌 성격으로 다양한 상황에 잘 적응해요"
- "자신만의 독특한 매력을 가지고 있어요"

JSON 배열 형식으로만 응답하세요: ["특성1", "특성2", "특성3"]
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
          'temperature': 1.0,
          'top_p': 0.9,
          'frequency_penalty': 0.7,
          'presence_penalty': 0.6,
        }),
      );

      if (response.statusCode == 200) {
        final content =
            jsonDecode(
                  utf8.decode(response.bodyBytes),
                )['choices'][0]['message']['content']
                as String;
        final List<dynamic> traitsList =
            jsonDecode(_sanitizeJsonString(content));
        return List<String>.from(traitsList);
      } else {
        debugPrint('🚨 [핵심특성] AI 생성 실패 (HTTP ${response.statusCode}) → 폴백 사용');
        return [
          "균형 잡힌 성격으로 다양한 상황에 잘 적응해요",
          "자신만의 독특한 매력을 가지고 있어요",
          "진정성 있는 소통을 중요하게 생각해요",
        ];
      }
    } catch (e) {
      debugPrint('🚨 [핵심특성] AI 생성 오류: $e → 폴백 사용');
      return [
        "균형 잡힌 성격으로 다양한 상황에 잘 적응해요",
        "자신만의 독특한 매력을 가지고 있어요",
        "진정성 있는 소통을 중요하게 생각해요",
      ];
    }
  }

  // 🎯 AI 기반 성격 설명 생성
  Future<String> _generatePersonalityDescription(
    OnboardingState state,
    Map<String, int> npsScores,
    Map<String, dynamic> photoAnalysis,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      // 폴백: 기본 설명
      return "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요. 안정적이면서도 적응력이 뛰어나 다양한 환경에서 자신만의 매력을 발휘할 수 있어요.";
    }

    final userInputSummary = '''
사용자 입력 정보:
- 사물: ${state.objectType ?? '정보없음'} 
- 함께한 시간: ${state.duration ?? '정보없음'}
- 목적: ${state.purpose ?? '정보없음'}
- 유머스타일: ${state.humorStyle ?? '정보없음'}
- 따뜻함: ${state.warmth ?? 5}/10
- 외향성: ${state.extroversion ?? 5}/10  
- 유능함: ${state.competence ?? 5}/10

성격 수치 요약:
${_getTopScores(npsScores, 3)}

사진 분석: ${photoAnalysis['visualDescription'] ?? '분석 없음'}
''';

    final systemPrompt = '''
당신은 매력적인 캐릭터 성격 설명을 생성하는 전문가입니다.

사물의 특성과 사용자 설정을 바탕으로 2-3문장의 생동감 있는 성격 설명을 만들어주세요.

🎯 **핵심 원칙**
1. 사물의 구체적 특성이 성격에 자연스럽게 반영
2. 사용자 목적('${state.purpose}')에 부합하는 성격
3. 함께한 기간과 상태를 반영한 개성
4. 첫인사처럼 매력적이고 친근한 문체
5. 형식적이거나 딱딱한 표현 금지

💡 **좋은 예시**
- 매일 쓰는 컵: "따뜻함을 나누는 걸 좋아하는 다정한 성격이에요. 때로는 조용히 있다가도 필요할 때는 든든한 버팀목이 되어죠."
- 침대 옆 책: "지적 호기심이 많고 깊이 있는 대화를 좋아해요. 조용해 보이지만 속에는 무궁무진한 이야기가 숨어있답니다."

❌ **피해야 할 표현**
- "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요"
- "안정적이면서도 적응력이 뛰어나..."

자연스럽고 매력적인 성격 설명을 생성해주세요.
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
          'max_tokens': 150,
          'temperature': 1.0,
          'top_p': 0.9,
          'frequency_penalty': 0.7,
          'presence_penalty': 0.6,
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
        debugPrint('🚨 성격 설명 AI 생성 실패: ${response.statusCode}');
        return "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요. 안정적이면서도 적응력이 뛰어나 다양한 환경에서 자신만의 매력을 발휘할 수 있어요.";
      }
    } catch (e) {
      debugPrint('🚨 성격 설명 생성 오류: $e');
      return "균형 잡힌 성격으로, 상황에 따라 유연하게 대처해요. 안정적이면서도 적응력이 뛰어나 다양한 환경에서 자신만의 매력을 발휘할 수 있어요.";
    }
  }

  /// AI가 반환한 JSON 문자열에서 마크다운 코드 블록을 제거합니다.
  String _sanitizeJsonString(String content) {
    content = content.trim();
    if (content.startsWith('```json')) {
      content = content.substring(7);
      if (content.endsWith('```')) {
        content = content.substring(0, content.length - 3);
      }
    }
    return content.trim();
  }
}
