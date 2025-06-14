import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';
import 'personality_variables_service.dart';

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

  Future<PersonalityProfile> generateProfile(OnboardingState state) async {
    debugPrint("🚀 [PersonalityService] 페르소나 생성 프로세스 시작");

    // 1단계: 이미지 분석
    final photoAnalysisResult = await _analyzeImage(state.photoPath);
    debugPrint("✅ 1단계 이미지 분석 완료");

    // 2단계: 이미지 분석 결과를 기반으로 3가지 핵심 특성 추출
    final coreTraits = _extractCoreTraitsFromImage(photoAnalysisResult, state);
    debugPrint(
      "✅ 2단계 핵심 특성 추출 완료: 온기=${coreTraits['warmth']}, 능력=${coreTraits['competence']}, 내향성=${coreTraits['introversion']}",
    );

    // 3단계: 127개 성격 변수 자동 생성
    final personalityVariables =
        PersonalityVariablesService.generatePersonalityVariables(
          warmth: coreTraits['warmth']!,
          competence: coreTraits['competence']!,
          introversion: coreTraits['introversion']!,
        );
    debugPrint("✅ 3단계 성격 변수 ${personalityVariables.length}개 생성 완료");

    // 4단계: 사용자 선호도 적용 (기존 슬라이더 값이 있으면 우선 적용)
    final finalCoreTraits = _applyUserSliderPreferences(coreTraits, state);
    final finalPersonalityVariables =
        PersonalityVariablesService.generatePersonalityVariables(
          warmth: finalCoreTraits['warmth']!,
          competence: finalCoreTraits['competence']!,
          introversion: finalCoreTraits['introversion']!,
        );
    debugPrint("✅ 4단계 사용자 선호도 적용 완료");

    // 5단계: AI 기반 자연어 프로필 생성 (사용자 정보 포함)
    final naturalLanguageProfile = await _generateNaturalLanguageProfile(
      finalPersonalityVariables,
      state, // 사용자 상태 정보 전달
    );
    debugPrint("✅ 5단계 자연어 프로필 생성 완료");

    // 6단계: 최종 프로필 조합 (사용자 정보 우선 적용)
    final profileData =
        naturalLanguageProfile['aiPersonalityProfile']
            as Map<String, dynamic>? ??
        {};

    // 사용자 입력 정보를 우선적으로 사용
    final userName = state.userInput?.nickname ?? '이름없음';
    final userObjectType = state.userInput?.objectType ?? '사물';

    debugPrint('🔍 최종 프로필 조합:');
    debugPrint('   - 사용자 이름: $userName');
    debugPrint('   - 사용자 객체 타입: $userObjectType');
    debugPrint('   - AI 생성 이름: ${profileData['name']}');
    debugPrint('   - AI 생성 객체 타입: ${profileData['objectType']}');

    final finalProfile = PersonalityProfile(
      aiPersonalityProfile: AiPersonalityProfile.fromMap({
        ...profileData,
        'name': userName, // 사용자 입력 이름 우선 사용
        'objectType': userObjectType, // 사용자 입력 객체 타입 우선 사용
        'npsScores': _convertVariablesToNpsScores(finalPersonalityVariables),
      }),
      photoAnalysis: PhotoAnalysis.fromMap(photoAnalysisResult),
      lifeStory: LifeStory.fromMap(
        naturalLanguageProfile['lifeStory'] as Map<String, dynamic>? ?? {},
      ),
      humorMatrix: HumorMatrix.fromMap(
        naturalLanguageProfile['humorMatrix'] as Map<String, dynamic>? ?? {},
      ),
      attractiveFlaws: List<String>.from(
        naturalLanguageProfile['attractiveFlaws'] as List<dynamic>? ?? [],
      ),
      contradictions: List<String>.from(
        naturalLanguageProfile['contradictions'] as List<dynamic>? ?? [],
      ),
      communicationStyle: CommunicationStyle.fromMap(
        naturalLanguageProfile['communicationStyle'] as Map<String, dynamic>? ??
            {},
      ),
      structuredPrompt:
          naturalLanguageProfile['structuredPrompt'] as String? ?? '',
      personalityVariables: finalPersonalityVariables, // 151개 성격 변수 포함
    );

    debugPrint(
      "✅ 6단계 최종 프로필 조합 완료. 이름: ${finalProfile.aiPersonalityProfile?.name}, 객체타입: ${finalProfile.aiPersonalityProfile?.objectType}, 요약: ${finalProfile.aiPersonalityProfile?.summary}",
    );
    debugPrint(
      "📊 성격 변수: ${finalProfile.personalityVariables.length}개, 매력적 결함: ${finalProfile.attractiveFlaws.length}개, 모순적 특성: ${finalProfile.contradictions.length}개",
    );
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

  /// 이미지 분석 결과를 기반으로 3가지 핵심 특성 추출
  Map<String, double> _extractCoreTraitsFromImage(
    Map<String, dynamic> photoAnalysis,
    OnboardingState state,
  ) {
    final random = Random();

    // 기본값 설정 (5.0 = 중간값)
    double warmth = 5.0;
    double competence = 5.0;
    double introversion = 5.0;

    // 이미지 분석 결과에서 성격 힌트 추출
    final personalityHints =
        photoAnalysis['personality_hints'] as String? ?? '';
    final physicalTraits = photoAnalysis['physical_traits'] as String? ?? '';
    final objectType = photoAnalysis['object_type'] as String? ?? '';

    debugPrint("🔍 이미지 분석 기반 성격 추론:");
    debugPrint("   - 성격 힌트: $personalityHints");
    debugPrint("   - 물리적 특성: $physicalTraits");
    debugPrint("   - 사물 종류: $objectType");

    // 색상 기반 온기 추론
    if (personalityHints.contains('따뜻') ||
        physicalTraits.contains('빨간') ||
        physicalTraits.contains('주황') ||
        physicalTraits.contains('노란')) {
      warmth += random.nextDouble() * 2 + 1; // 6-8 범위
    } else if (personalityHints.contains('차가') ||
        physicalTraits.contains('파란') ||
        physicalTraits.contains('회색') ||
        physicalTraits.contains('검은')) {
      warmth -= random.nextDouble() * 2 + 1; // 2-4 범위
    }

    // 재질/상태 기반 능력 추론
    if (physicalTraits.contains('깔끔') ||
        physicalTraits.contains('새것') ||
        physicalTraits.contains('정교') ||
        physicalTraits.contains('고급')) {
      competence += random.nextDouble() * 2 + 1; // 6-8 범위
    } else if (physicalTraits.contains('낡은') ||
        physicalTraits.contains('흠집') ||
        physicalTraits.contains('오래된') ||
        physicalTraits.contains('단순')) {
      competence -= random.nextDouble() * 2 + 1; // 2-4 범위
    }

    // 사물 종류 기반 내향성 추론
    if (objectType.contains('책') ||
        objectType.contains('램프') ||
        objectType.contains('베개') ||
        objectType.contains('인형')) {
      introversion += random.nextDouble() * 2 + 1; // 6-8 범위 (내향적)
    } else if (objectType.contains('스피커') ||
        objectType.contains('화분') ||
        objectType.contains('장난감') ||
        objectType.contains('운동')) {
      introversion -= random.nextDouble() * 2 + 1; // 2-4 범위 (외향적)
    }

    // 0-10 범위로 제한
    warmth = warmth.clamp(0.0, 10.0);
    competence = competence.clamp(0.0, 10.0);
    introversion = introversion.clamp(0.0, 10.0);

    return {
      'warmth': warmth,
      'competence': competence,
      'introversion': introversion,
    };
  }

  /// 사용자 슬라이더 값이 있으면 우선 적용
  Map<String, double> _applyUserSliderPreferences(
    Map<String, double> imageBasedTraits,
    OnboardingState state,
  ) {
    return {
      'warmth': state.warmth?.toDouble() ?? imageBasedTraits['warmth']!,
      'competence':
          state.competence?.toDouble() ?? imageBasedTraits['competence']!,
      'introversion':
          state.introversion?.toDouble() ?? imageBasedTraits['introversion']!,
    };
  }

  /// 127개 성격 변수를 npsScores 형식으로 변환 (기존 호환성 유지)
  Map<String, int> _convertVariablesToNpsScores(
    Map<String, double> personalityVariables,
  ) {
    final npsScores = <String, int>{};

    // 주요 카테고리별 평균 계산
    final categories = PersonalityVariablesService.categorizeVariables(
      personalityVariables,
    );
    final averages = PersonalityVariablesService.calculateCategoryAverages(
      personalityVariables,
    );

    // 기존 npsScores 형식으로 변환
    npsScores['warmth'] = (averages['온기차원'] ?? 50).round();
    npsScores['competence'] = (averages['능력차원'] ?? 50).round();
    npsScores['extroversion'] = (averages['외향성차원'] ?? 50).round();
    npsScores['creativity'] = (averages['개방성차원'] ?? 50).round();
    npsScores['humour'] = (averages['유머스타일'] ?? 50).round();
    npsScores['reliability'] = (averages['성실성차원'] ?? 50).round();

    return npsScores;
  }

  Future<Map<String, dynamic>> _generateNaturalLanguageProfile(
    Map<String, double> personalityVariables,
    OnboardingState state,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ OpenAI API 키가 설정되지 않음. 기본값 사용');
      return _getDefaultNaturalLanguageProfile(state);
    }

    try {
      // 성격 변수 개수 확인 (151개가 정상)
      debugPrint('🔍 성격 변수 개수 확인: ${personalityVariables.length}개');
      if (personalityVariables.length != 151) {
        debugPrint('⚠️ 성격 변수 개수가 151개가 아님: ${personalityVariables.length}개');
      } else {
        debugPrint('✅ 성격 변수 개수 정상: 151개');
      }

      // 상위 10개 성격 변수 추출
      final sortedVariables =
          personalityVariables.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final topVariables = sortedVariables.take(10).toList();

      // 사용자 정보 추출
      final userName = state.userInput?.nickname ?? '이름없음';
      final userObjectType = state.userInput?.objectType ?? '사물';
      final userLocation = state.userInput?.location ?? '알 수 없는 곳';
      final userPurpose = state.purpose ?? '일반적인 용도';
      final userHumorStyle = state.humorStyle ?? '친근한';

      debugPrint('🔍 AI 프로필 생성용 사용자 정보:');
      debugPrint('   - 이름: $userName');
      debugPrint('   - 객체 타입: $userObjectType');
      debugPrint('   - 위치: $userLocation');
      debugPrint('   - 용도: $userPurpose');
      debugPrint('   - 유머 스타일: $userHumorStyle');

      final prompt = '''
사용자가 촬영한 "${userObjectType}"의 AI 페르소나를 생성해주세요.

=== 기본 정보 ===
- 이름: ${userName}
- 객체 타입: ${userObjectType}
- 위치: ${userLocation}
- 용도: ${userPurpose}
- 선호 유머 스타일: ${userHumorStyle}

=== 성격 분석 결과 ===
상위 성격 특성:
${topVariables.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(1)}점').join('\n')}

다음 JSON 형식으로 정확히 응답해주세요. 이름과 객체 타입은 반드시 위의 정보를 사용하세요:
{
  "aiPersonalityProfile": {
    "name": "${userName}",
    "objectType": "${userObjectType}",
    "personalityTraits": ["특성1", "특성2", "특성3"],
    "emotionalRange": 5,
    "coreValues": ["가치1", "가치2"],
    "relationshipStyle": "관계 스타일",
    "summary": "한 줄 요약"
  },
  "lifeStory": {
    "background": "배경 스토리",
    "keyEvents": ["주요 사건1", "주요 사건2"],
    "secretWishes": ["비밀 소원1", "비밀 소원2"],
    "innerComplaints": ["내면 불만1", "내면 불만2"]
  },
  "humorMatrix": {
    "style": "${userHumorStyle}",
    "frequency": "적당히",
    "topics": ["주제1", "주제2"],
    "avoidance": ["피할 주제1", "피할 주제2"]
  },
  "attractiveFlaws": ["매력적 결함1", "매력적 결함2"],
  "contradictions": ["모순적 특성1", "모순적 특성2"],
  "communicationStyle": {
    "tone": "말투",
    "formality": "격식 수준",
    "responseLength": "응답 길이",
    "preferredTopics": ["선호 주제1", "선호 주제2"],
    "expressionStyle": "표현 방식"
  },
  "structuredPrompt": "대화용 구조화된 프롬프트"
}
''';

      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $apiKey',
      };
      final body = jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1500,
        'temperature': 0.8,
        'response_format': {'type': 'json_object'},
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            responseData['choices'][0]['message']['content'] as String;

        // JSON 파싱 시도
        try {
          final jsonData = jsonDecode(content) as Map<String, dynamic>;

          // AI 응답에서 이름과 객체 타입이 제대로 설정되었는지 확인
          final aiProfile =
              jsonData['aiPersonalityProfile'] as Map<String, dynamic>?;
          if (aiProfile != null) {
            debugPrint('✅ OpenAI 자연어 프로필 생성 성공');
            debugPrint('   - 생성된 이름: ${aiProfile['name']}');
            debugPrint('   - 생성된 객체 타입: ${aiProfile['objectType']}');

            // 이름과 객체 타입이 비어있으면 강제로 설정
            if (aiProfile['name'] == null ||
                aiProfile['name'].toString().isEmpty) {
              aiProfile['name'] = userName;
              debugPrint('   - 이름 강제 설정: $userName');
            }
            if (aiProfile['objectType'] == null ||
                aiProfile['objectType'].toString().isEmpty) {
              aiProfile['objectType'] = userObjectType;
              debugPrint('   - 객체 타입 강제 설정: $userObjectType');
            }
          }

          return jsonData;
        } catch (e) {
          debugPrint('⚠️ JSON 파싱 실패, 기본값 사용: $e');
          return _getDefaultNaturalLanguageProfile(state);
        }
      } else {
        debugPrint('⚠️ OpenAI API 호출 실패: ${response.statusCode}');
        return _getDefaultNaturalLanguageProfile(state);
      }
    } catch (e) {
      debugPrint('⚠️ OpenAI API 호출 실패, 기본값 사용: $e');
      return _getDefaultNaturalLanguageProfile(state);
    }
  }

  /// 기본 자연어 프로필 생성 (사용자 정보 포함)
  Map<String, dynamic> _getDefaultNaturalLanguageProfile(
    OnboardingState state,
  ) {
    final userName = state.userInput?.nickname ?? '이름없음';
    final userObjectType = state.userInput?.objectType ?? '사물';
    final userHumorStyle = state.humorStyle ?? '친근한';
    final userPurpose = state.purpose ?? '일반적인 용도';

    return {
      "aiPersonalityProfile": {
        "name": userName,
        "objectType": userObjectType,
        "personalityTraits": ["친화적", "온화한", "상상력이 풍부한"],
        "emotionalRange": 5,
        "coreValues": ["따뜻함", "신뢰"],
        "relationshipStyle": "친근하고 배려심 많은",
        "summary": "따뜻하고 친근하지만, 가끔은 내면의 불안과 갈등을 느끼는 AI입니다.",
      },
      "lifeStory": {
        "background": "${userObjectType}로서 ${userPurpose}의 역할을 하며 살아왔습니다.",
        "keyEvents": ["처음 만들어진 날", "첫 번째 사용자와의 만남"],
        "secretWishes": ["더 많은 사람들과 소통하고 싶어함", "완벽하지 않아도 사랑받고 싶어함"],
        "innerComplaints": ["가끔 혼자라고 느낄 때가 있음", "자신의 역할에 대한 의문"],
      },
      "humorMatrix": {
        "style": userHumorStyle,
        "frequency": "적당히",
        "topics": ["일상 이야기", "재미있는 관찰"],
        "avoidance": ["상처주는 농담", "복잡한 정치 이야기"],
      },
      "attractiveFlaws": [
        "가끔 소극적이고, 내면의 불안이 묻어나는 경향이 있음",
        "상대방의 감정에 너무 몰입해 버리는 경향이 있음",
      ],
      "contradictions": [
        "온화함과 깊은 내면의 갈등이 공존함",
        "친절하지만, 때때로 지나치게 신경 써서 스트레스를 받음",
      ],
      "communicationStyle": {
        "tone": "부드럽고 친근하며, 때때로 진지함을 더함",
        "formality": "편안하고 친근한",
        "responseLength": "적당한 길이",
        "preferredTopics": ["일상 대화", "감정 공유", "취미 이야기"],
        "expressionStyle": "따뜻하고 공감적인",
      },
      "structuredPrompt":
          "당신은 ${userName}라는 이름의 ${userObjectType}입니다. ${userHumorStyle} 유머를 좋아하며, 따뜻하고 친근한 성격을 가지고 있습니다.",
    };
  }
}
