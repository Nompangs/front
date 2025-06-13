import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';

class PersonalityService {
  const PersonalityService();

  // 127개 변수 목록을 서비스 내에서 직접 관리
  static List<String> getVariableKeys() {
    return [
      'W01_친절함', 'W02_친근함', 'W03_진실성', 'W04_신뢰성', 'W05_수용성', 'W06_공감능력', 'W07_포용력', 'W08_격려성향', 'W09_친밀감표현', 'W10_무조건적수용',
      'C01_효율성', 'C02_전문성', 'C03_창의성', 'C04_창의성_중복', 'C05_정확성', 'C06_분석력', 'C07_학습능력', 'C08_통찰력', 'C09_실행력', 'C10_적응력',
      'E01_사교성', 'E02_활동성', 'E03_자기주장', 'E04_긍정정서', 'E05_자극추구', 'E06_주도성',
      'H01_유머감각',
      'CS01_책임감', 'CS02_질서성',
      'N01_불안성', 'N02_감정변화',
      'O01_상상력', 'O02_호기심'
    ];
  }

  Future<PersonalityProfile> generateProfile(OnboardingState state) async {
    debugPrint("🚀 [PersonalityService] 페르소나 생성 프로세스 시작");

    // 1단계: 이미지 분석
    final photoAnalysisResult = await _analyzeImage(state.photoPath);
    debugPrint("✅ 1단계 이미지 분석 완료");

    // 2단계: AI 변수 생성
    Map<String, int> aiGeneratedVariables = await _generateAIBasedVariables(state, photoAnalysisResult);
    debugPrint("✅ 2단계 AI 변수 생성 완료: ${aiGeneratedVariables.length}개");

    // 3단계: 사용자 선호도 적용
    Map<String, int> userAdjustedVariables = _applyUserPreferences(aiGeneratedVariables, state);
    debugPrint("✅ 3단계 사용자 선호도 적용 완료");

    // 4단계: 자연어 프로필 생성
    final naturalLanguageProfile = await _generateNaturalLanguageProfile(userAdjustedVariables);
    debugPrint("✅ 4단계 자연어 프로필 생성 완료");

    // 5단계: 최종 프로필 조합
    final profileData = naturalLanguageProfile['aiPersonalityProfile'] as Map<String, dynamic>? ?? {};
    final finalProfile = PersonalityProfile(
      aiPersonalityProfile: AiPersonalityProfile.fromMap({
        ...profileData,
        'npsScores': userAdjustedVariables,
      }),
      photoAnalysis: PhotoAnalysis.fromMap(photoAnalysisResult),
      lifeStory: LifeStory.fromMap(naturalLanguageProfile['lifeStory'] as Map<String, dynamic>? ?? {}),
      humorMatrix: HumorMatrix.fromMap(naturalLanguageProfile['humorMatrix'] as Map<String, dynamic>? ?? {}),
      attractiveFlaws: List<String>.from(naturalLanguageProfile['attractiveFlaws'] as List<dynamic>? ?? []),
      contradictions: List<String>.from(naturalLanguageProfile['contradictions'] as List<dynamic>? ?? []),
      communicationStyle: CommunicationStyle.fromMap(naturalLanguageProfile['communicationStyle'] as Map<String, dynamic>? ?? {}),
      structuredPrompt: naturalLanguageProfile['structuredPrompt'] as String? ?? '',
    );
    debugPrint("✅ 5단계 최종 프로필 조합 완료. 요약: ${finalProfile.aiPersonalityProfile?.summary}");
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
당신은 사진 속 사물을 분석하여 성격과 물리적 특성을 추론하는 전문가입니다.
제공된 이미지를 분석하여 다음 항목들을 JSON 형식으로 응답해주세요.

- personality_hints: 성격 추론 힌트 (예: "따뜻한 색감으로 보아 온화한 성격일 수 있음")
- physical_traits: 물리적 특성 (예: "붉은색, 플라스틱 재질, 약간의 흠집 있음")
- object_type: 사물 종류 (예: "머그컵")
- estimated_age: 추정 사용 기간 (예: "3년 이상")
''';

      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': systemPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
              }
            ]
          }
        ],
        'max_tokens': 300,
        'response_format': {'type': 'json_object'},
      });

      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final contentString = jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'] as String;
        return jsonDecode(contentString);
      } else {
        throw Exception('이미지 분석 API 호출 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 1단계 이미지 분석 실패: $e');
      rethrow; // 오류를 그대로 상위로 다시 던짐
    }
  }

  Future<Map<String, int>> _generateAIBasedVariables(OnboardingState state, Map<String, dynamic> photoAnalysis) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) throw Exception('API 키가 없습니다.');

    final variableKeys = getVariableKeys().join(', ');

    final systemPrompt = '''
당신은 사물의 페르소나를 127개의 정수형 변수로 정의하는 전문가입니다.
사용자 정보를 바탕으로 사물의 고유한 성격을 분석하여, 다음 127개 변수 각각에 대해 1에서 100 사이의 값을 할당해주세요.
응답은 반드시 JSON 형식이어야 하며, 다른 설명은 포함하지 마세요.

JSON 형식:
{
  "variables": {
    "W01_친절함": [1-100 사이 값],
    "W02_친근함": [1-100 사이 값],
    // ... 총 127개 변수
  }
}

🎯 중요: 각 변수는 사물의 고유한 특성을 반영하여 독립적으로 생성해야 합니다. 서로 다른 변수가 비슷한 값을 가질 수 있지만, 모든 값이 동일해서는 안됩니다.
변수 목록: $variableKeys
''';

    final userPrompt = '''
이름:${state.userInput?.nickname}, 위치:${state.userInput?.location}, 기간:${state.userInput?.duration},
사물:${state.userInput?.objectType}, 주 사용 목적:${state.purpose}, 선호 유머 스타일:${state.humorStyle}.
---
이미지 분석 결과:
${jsonEncode(photoAnalysis)}
---
이 사물의 성격을 분석하여 127개 변수 값을 할당해줘.
''';

    debugPrint("✨ [PersonalityService] 2단계: 127개 변수 생성 시작...");
    debugPrint("   - 프롬프트 일부: ${userPrompt.substring(0, 100)}...");

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.8, // 다양성 확보를 위해 온도 살짝 높임
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final contentString = jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'] as String;
        final contentJson = jsonDecode(contentString);
        final variables = contentJson['variables'];
        if (variables is Map<String, dynamic>) {
          return variables.map((key, value) => MapEntry(key, (value as num).toInt()));
        } else {
          throw Exception('GPT 응답에서 "variables" 필드를 찾을 수 없거나 형식이 잘못되었습니다.');
        }
      } else {
        throw Exception('변수 생성 API 호출 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 2단계 AI 변수 생성 실패: $e');
      rethrow; // 오류를 그대로 상위로 다시 던짐
    }
  }

  Map<String, int> _applyUserPreferences(Map<String, int> aiVariables, OnboardingState state) {
    final adjustedVariables = Map<String, int>.from(aiVariables);
    final random = Random();

    // 슬라이더 값 (1~9)
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5; // 외향성은 내향성의 반대로 사용

    // nps_test 방식 적용
    // W (온기) 계열: warmth 슬라이더
    _adjustWithRandomVariation(adjustedVariables, 'W01_친절함', warmth, 10, random);
    _adjustWithRandomVariation(adjustedVariables, 'W02_친근함', warmth, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'W03_진실성', warmth, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'W04_신뢰성', warmth, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'W05_수용성', warmth, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'W06_공감능력', warmth, 10, random);
    _adjustWithRandomVariation(adjustedVariables, 'W07_포용력', warmth, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'W08_격려성향', warmth, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'W09_친밀감표현', warmth, 25, random);
    _adjustWithRandomVariation(adjustedVariables, 'W10_무조건적수용', warmth, 30, random);
    
    // C (능력) 계열: competence 슬라이더
    _adjustWithRandomVariation(adjustedVariables, 'C01_효율성', competence, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'C02_전문성', competence, 10, random);
    _adjustWithRandomVariation(adjustedVariables, 'C03_창의성', competence, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'C04_창의성_중복', competence, 25, random);
    _adjustWithRandomVariation(adjustedVariables, 'C05_정확성', competence, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'C06_분석력', competence, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'C07_학습능력', competence, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'C08_통찰력', competence, 25, random);
    _adjustWithRandomVariation(adjustedVariables, 'C09_실행력', competence, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'C10_적응력', competence, 15, random);
    
    // E (외향성) 계열: introversion 슬라이더 (반대로 적용)
    final extraversion = 10 - introversion; // 1(내향) -> 9(외향), 9(내향) -> 1(외향)
    _adjustWithRandomVariation(adjustedVariables, 'E01_사교성', extraversion, 15, random);
    _adjustWithRandomVariation(adjustedVariables, 'E02_활동성', extraversion, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'E03_자기주장', extraversion, 25, random);
    _adjustWithRandomVariation(adjustedVariables, 'E04_긍정정서', extraversion, 20, random);
    _adjustWithRandomVariation(adjustedVariables, 'E05_자극추구', extraversion, 30, random);
    _adjustWithRandomVariation(adjustedVariables, 'E06_주도성', extraversion, 20, random);

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
    Random random
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

  Future<Map<String, dynamic>> _generateNaturalLanguageProfile(Map<String, int> variables) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) throw Exception('API 키가 없습니다.');

    final systemPrompt = '''
    당신은 127개의 성격 변수(NPS)를 해석하여, 사물의 개성적인 페르소나를 구체적인 자연어로 설명하는 작가입니다.
    주어진 NPS 데이터를 바탕으로, 다음 항목들을 포함하는 풍부하고 일관된 성격 프로필을 JSON 형식으로 생성해주세요.
    
    {
      "aiPersonalityProfile": {
        "name": "사물의 독창적이고 개성 넘치는 이름",
        "objectType": "사물의 종류 (예: '낡은 가죽 일기장')",
        "personalityTraits": ["성격을 대표하는 핵심 형용사 3-5개"],
        "summary": "NPS 데이터를 종합하여 사물의 성격을 2-3문장으로 요약"
      },
      "lifeStory": {
        "background": "사물의 배경, 태생, 소유주와의 관계 등을 묘사하는 짧은 이야기",
        "secretWishes": ["사물이 마음속으로 바라는 소망 2-3가지"],
        "innerComplaints": ["사물이 남몰래 가진 불만 2-3가지"]
      },
      "humorMatrix": {
        "style": "유머 스타일 (예: '아이러니', '슬랩스틱', '말장난', '냉소적')",
        "frequency": "유머 구사 빈도 (예: '가끔', '자주', '거의 안함')"
      },
      "communicationStyle": {
        "tone": "평소 대화 톤 (예: '따뜻하고 다정한', '무뚝뚝하지만 진심어린', '장난기 많은')",
        "responseLength": "응답 길이 (예: '간결함', '상세함')"
      },
      "attractiveFlaws": ["'인간적인' 매력으로 느껴질 수 있는 결점 2-3가지"],
      "contradictions": ["성격에 나타나는 모순적인 측면 2-3가지"],
      "structuredPrompt": "이 모든 정보를 종합하여, 이 캐릭터로서 대화하기 위한 최종 시스템 프롬프트"
    }
    ''';

    final userPrompt = '''
    다음 NPS 데이터를 가진 사물의 페르소나를 생성해줘.
    NPS 데이터: ${jsonEncode(variables)}
    ''';

    debugPrint("✨ [PersonalityService] 4단계: 자연어 프로필 생성 시작...");
    
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};
    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt}
      ],
      'max_tokens': 1000,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final contentString = jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'] as String;
        return jsonDecode(contentString);
      } else {
        throw Exception('자연어 프로필 생성 API 호출 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('🚨 4단계 자연어 프로필 생성 실패: $e');
      rethrow; // 오류를 그대로 상위로 다시 던짐
    }
  }
}
