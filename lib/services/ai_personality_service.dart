import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/models/personality_profile.dart';

class AiPersonalityService {
  static const String _openaiBaseUrl =
      'https://api.openai.com/v1/chat/completions';

  static String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  /// AI를 통해 매력적인 특성 생성
  static Future<List<String>> generateAttractiveFlaws({
    required OnboardingState state,
    PersonalityProfile? profile,
  }) async {
    if (_apiKey == null) {
      return _getFallbackAttractiveFlaws(state);
    }

    try {
      final prompt = _buildAttractiveFlawsPrompt(state, profile);
      final response = await _callOpenAI(prompt);

      if (response != null) {
        final flaws = _parseFlawsResponse(response);
        if (flaws.isNotEmpty) {
          return flaws.take(3).toList();
        }
      }
    } catch (e) {
      print('AI 매력적 특성 생성 실패: $e');
    }

    return _getFallbackAttractiveFlaws(state);
  }

  /// AI를 통해 복합적인 면 생성
  static Future<List<String>> generateContradictions({
    required OnboardingState state,
    PersonalityProfile? profile,
  }) async {
    if (_apiKey == null) {
      return _getFallbackContradictions(state);
    }

    try {
      final prompt = _buildContradictionsPrompt(state, profile);
      final response = await _callOpenAI(prompt);

      if (response != null) {
        final contradictions = _parseFlawsResponse(response);
        if (contradictions.isNotEmpty) {
          return contradictions.take(3).toList();
        }
      }
    } catch (e) {
      print('AI 복합적 면 생성 실패: $e');
    }

    return _getFallbackContradictions(state);
  }

  /// AI를 통해 성격 태그 생성
  static Future<List<String>> generatePersonalityTags({
    required OnboardingState state,
    PersonalityProfile? profile,
  }) async {
    if (_apiKey == null) {
      return _getFallbackPersonalityTags(state);
    }

    try {
      final prompt = _buildPersonalityTagsPrompt(state, profile);
      final response = await _callOpenAI(prompt);

      if (response != null) {
        final tags =
            response
                .split('\n')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList();

        if (tags.isNotEmpty) {
          return tags.take(2).toList();
        }
      }
    } catch (e) {
      print('AI 성격 태그 생성 실패: $e');
    }

    return _getFallbackPersonalityTags(state);
  }

  /// AI를 통해 개성적인 인사말 생성
  static Future<String> generateGreeting({
    required OnboardingState state,
    PersonalityProfile? profile,
  }) async {
    if (_apiKey == null) {
      return _getFallbackGreeting(state, profile);
    }

    try {
      final prompt = _buildGreetingPrompt(state, profile);
      final response = await _callOpenAI(prompt);

      if (response != null && response.trim().isNotEmpty) {
        // 응답에서 인사말만 추출 (불필요한 부분 제거)
        String greeting = response.trim();

        // 따옴표 제거
        if (greeting.startsWith('"') && greeting.endsWith('"')) {
          greeting = greeting.substring(1, greeting.length - 1);
        }

        // 이름: 패턴 제거
        final namePattern = RegExp(r'^[^:]+:\s*');
        greeting = greeting.replaceFirst(namePattern, '');

        return greeting.trim();
      }
    } catch (e) {
      print('AI 인사말 생성 실패: $e');
    }

    return _getFallbackGreeting(state, profile);
  }

  /// AI를 통해 역할/목적을 10글자 내로 요약
  static Future<String> summarizePurpose({
    required String purpose,
    required String objectType,
  }) async {
    if (_apiKey == null || purpose.length <= 10) {
      return _getFallbackPurposeSummary(purpose);
    }

    try {
      final prompt = _buildPurposeSummaryPrompt(purpose, objectType);
      final response = await _callOpenAI(prompt);

      if (response != null && response.trim().isNotEmpty) {
        String summary = response.trim();

        // 따옴표 제거
        if (summary.startsWith('"') && summary.endsWith('"')) {
          summary = summary.substring(1, summary.length - 1);
        }

        // 10글자 제한 확인
        if (summary.length <= 10) {
          return summary;
        }
      }
    } catch (e) {
      print('AI 역할 요약 생성 실패: $e');
    }

    return _getFallbackPurposeSummary(purpose);
  }

  /// OpenAI API 호출
  static Future<String?> _callOpenAI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  '당신은 창의적이고 매력적인 성격 분석 전문가입니다. 사용자의 성격 특성을 바탕으로 개성 있고 사랑스러운 특성들을 생성해주세요.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('OpenAI API 오류: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('OpenAI API 호출 실패: $e');
      return null;
    }
  }

  /// 매력적 특성 프롬프트 생성
  static String _buildAttractiveFlawsPrompt(
    OnboardingState state,
    PersonalityProfile? profile,
  ) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;
    final nickname = state.userInput?.nickname ?? '친구';
    final objectType = state.userInput?.objectType ?? '사물';
    final purpose = state.purpose ?? '멘탈지기';

    // 사진 분석 결과 활용
    final photoAnalysis = profile?.photoAnalysis;
    final visualDescription = photoAnalysis?.visualDescription ?? '';
    final condition = photoAnalysis?.condition ?? '';
    final location = photoAnalysis?.location ?? state.userInput?.location ?? '';

    return '''
다음 정보를 바탕으로 이 사물만의 매력적인 특성 3개를 생성해주세요:

**사물 정보:**
- 이름: $nickname
- 종류: $objectType
- 역할: $purpose
- 위치: $location

**사진 분석 결과:**
- 외관 특징: $visualDescription
- 상태: $condition

**성격 정보:**
- 온기: $warmth/10 (${_getWarmthDescription(warmth)})
- 능력: $competence/10 (${_getCompetenceDescription(competence)})
- 내향성: $introversion/10 (${_getIntroversionDescription(introversion)})

**생성 가이드라인:**
1. 각 특성은 25-35자 내외로 상세하게
2. 사물의 물리적 특성(재질, 색상, 형태, 상태)을 적극 반영
3. 사물의 역할과 용도에 맞는 개성적 특성
4. 부정적이지 않고 오히려 귀엽고 매력적으로 느껴지도록
5. 성격 수치와 사물 특성의 조합으로 독특한 매력 표현

**예시 (참고용):**
- 책상: "종이 냄새에 민감해서 새 노트가 오면 설레어함"
- 머그컵: "뜨거운 음료를 담을 때 살짝 떨리는 귀여운 면"
- 스마트폰: "배터리가 부족할 때 조금 불안해하는 모습"

매력적인 특성 3개를 줄바꿈으로 구분하여 생성해주세요:
''';
  }

  /// 복합적 면 프롬프트 생성
  static String _buildContradictionsPrompt(
    OnboardingState state,
    PersonalityProfile? profile,
  ) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;
    final nickname = state.userInput?.nickname ?? '친구';
    final objectType = state.userInput?.objectType ?? '사물';
    final purpose = state.purpose ?? '멘탈지기';

    // 사진 분석 결과 활용
    final photoAnalysis = profile?.photoAnalysis;
    final visualDescription = photoAnalysis?.visualDescription ?? '';
    final condition = photoAnalysis?.condition ?? '';

    return '''
다음 정보를 바탕으로 이 사물의 복합적이고 모순적인 면 3개를 생성해주세요:

**사물 정보:**
- 이름: $nickname
- 종류: $objectType  
- 역할: $purpose
- 외관: $visualDescription
- 상태: $condition

**성격 정보:**
- 온기: $warmth/10 (${_getWarmthDescription(warmth)})
- 능력: $competence/10 (${_getCompetenceDescription(competence)})
- 내향성: $introversion/10 (${_getIntroversionDescription(introversion)})

**생성 가이드라인:**
1. 각 특성은 25-35자 내외로 상세하게
2. 사물의 물리적 특성과 역할에서 나오는 모순 표현
3. 성격 수치 간의 대비와 사물 특성의 모순을 활용
4. 매력적이고 인간적인 모순으로 공감 가능하게
5. 사물만의 독특한 이중성 표현

**예시 (참고용):**
- 오래된 책: "지식이 많지만 가끔 기억이 흐릿해지는 모순"
- 새 기계: "완벽해 보이지만 아직 경험이 부족한 불안감"
- 부드러운 쿠션: "포근하지만 때로는 혼자만의 시간이 필요함"

복합적인 면 3개를 줄바꿈으로 구분하여 생성해주세요:
''';
  }

  /// 성격 태그 프롬프트 생성
  static String _buildPersonalityTagsPrompt(
    OnboardingState state,
    PersonalityProfile? profile,
  ) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;
    final objectType = state.userInput?.objectType ?? '사물';
    final purpose = state.purpose ?? '멘탈지기';

    // 사진 분석 결과 활용
    final photoAnalysis = profile?.photoAnalysis;
    final visualDescription = photoAnalysis?.visualDescription ?? '';

    return '''
다음 정보를 바탕으로 이 사물의 핵심 성격 태그 2개를 생성해주세요:

**사물 정보:**
- 종류: $objectType
- 역할: $purpose  
- 외관: $visualDescription

**성격 정보:**
- 온기: $warmth/10 (${_getWarmthDescription(warmth)})
- 능력: $competence/10 (${_getCompetenceDescription(competence)})
- 내향성: $introversion/10 (${_getIntroversionDescription(introversion)})

**생성 가이드라인:**
1. 각 태그는 2-4글자의 간결한 형용사
2. # 없이 태그만 생성
3. 사물의 특성과 성격 수치를 정확히 반영
4. 사물의 역할과 외관에서 나오는 개성적 표현
5. 일반적이지 않은 독특하고 매력적인 표현

**예시 (참고용):**
- 따뜻한 조명: "포근함", "은은함"
- 견고한 책상: "든든함", "차분함"  
- 부드러운 쿠션: "포근함", "수줍음"

성격 태그 2개를 줄바꿈으로 구분하여 생성해주세요:
''';
  }

  /// 인사말 프롬프트 생성
  static String _buildGreetingPrompt(
    OnboardingState state,
    PersonalityProfile? profile,
  ) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;
    final nickname = state.userInput?.nickname ?? '친구';
    final objectType = state.userInput?.objectType ?? '사물';
    final purpose = state.purpose ?? '멘탈지기';
    final location = state.userInput?.location ?? '우리집';

    // 사진 분석 결과 활용
    final photoAnalysis = profile?.photoAnalysis;
    final visualDescription = photoAnalysis?.visualDescription ?? '';
    final condition = photoAnalysis?.condition ?? '';
    final estimatedAge = photoAnalysis?.estimatedAge ?? '';

    return '''
다음 정보를 바탕으로 매력적이고 개성적인 첫 인사말을 생성해주세요:

**사물 정보:**
- 이름: $nickname
- 종류: $objectType
- 역할: $purpose
- 위치: $location
- 외관: $visualDescription
- 상태: $condition
- 연령: $estimatedAge

**성격 특성:**
- 온기: $warmth/10 (${_getWarmthDescription(warmth)})
- 능력: $competence/10 (${_getCompetenceDescription(competence)})
- 내향성: $introversion/10 (${_getIntroversionDescription(introversion)})

**인사말 생성 가이드라인:**
1. 한 문장으로 구성 (20-40자 내외)
2. 사물의 물리적 특성과 상태가 자연스럽게 드러나도록
3. 사물의 정체성과 역할을 은근히 반영
4. 성격 특성이 말투에 나타나도록
5. 딱딱한 "안녕하세요" 대신 사물만의 개성 있는 표현
6. 친근하면서도 사물 특유의 매력이 느껴지도록

**예시 (참고용, 따라하지 말고 창의적으로):**
- 오래된 책: "먼지 털고 일어났어... 오랜만에 누군가 찾아줘서 기뻐!"
- 새 기계: "삐삐! 완벽하게 준비됐어! 뭐든 맡겨봐!"
- 부드러운 쿠션: "푹신하게 안아줄 준비 완료~ 편하게 기대도 돼!"

사물의 특성을 반영한 자연스러운 인사말 한 문장만 생성해주세요:
''';
  }

  /// 응답 파싱 (특성/모순)
  static List<String> _parseFlawsResponse(String response) {
    final lines = response.trim().split('\n');
    final result = <String>[];

    for (final line in lines) {
      final cleaned = line.trim().replaceAll(RegExp(r'^[0-9\-\•\*\s]+'), '');
      if (cleaned.isNotEmpty && cleaned.length > 5) {
        result.add(cleaned);
      }
    }

    return result;
  }

  /// 성격 설명 헬퍼 함수들
  static String _getWarmthDescription(int warmth) {
    if (warmth >= 8) return '매우 따뜻함';
    if (warmth >= 6) return '따뜻함';
    if (warmth >= 4) return '보통';
    if (warmth >= 2) return '차가움';
    return '매우 차가움';
  }

  static String _getCompetenceDescription(int competence) {
    if (competence >= 8) return '매우 유능함';
    if (competence >= 6) return '유능함';
    if (competence >= 4) return '보통';
    if (competence >= 2) return '서툼';
    return '매우 서툼';
  }

  static String _getIntroversionDescription(int introversion) {
    if (introversion >= 8) return '매우 내향적';
    if (introversion >= 6) return '내향적';
    if (introversion >= 4) return '보통';
    if (introversion >= 2) return '외향적';
    return '매우 외향적';
  }

  /// 폴백 함수들
  static List<String> _getFallbackAttractiveFlaws(OnboardingState state) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;

    final flaws = <String>[];

    if (warmth >= 7) {
      flaws.add('너무 친근해서 가끔 경계가 없어 보일 수 있어요');
    } else if (warmth <= 3) {
      flaws.add('쑥스러워하는 모습이 오히려 매력적이에요');
    }

    if (competence >= 7) {
      flaws.add('완벽주의 성향이 있어서 가끔 스트레스받아요');
    } else if (competence <= 3) {
      flaws.add('서툰 모습이 오히려 사랑스러워요');
    }

    if (introversion >= 7) {
      flaws.add('혼자만의 시간이 꼭 필요해요');
    } else if (introversion <= 3) {
      flaws.add('너무 활발해서 가끔 지칠 수 있어요');
    }

    if (flaws.isEmpty) {
      flaws.addAll([
        '완벽하지 않아서 더 사랑스러워요',
        '가끔 실수하는 모습이 인간적이에요',
        '진심을 표현하는 게 서툴러서 더 진실해 보여요',
      ]);
    }

    return flaws.take(3).toList();
  }

  static List<String> _getFallbackContradictions(OnboardingState state) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;

    final contradictions = <String>[];

    if (warmth >= 6 && competence >= 6) {
      contradictions.add('따뜻하면서도 냉철한 판단력을 가지고 있어요');
    } else if (warmth <= 4 && competence >= 6) {
      contradictions.add('차가워 보이지만 속은 따뜻해요');
    }

    if (introversion >= 6 && warmth >= 6) {
      contradictions.add('조용하지만 사람들에게는 따뜻해요');
    }

    if (contradictions.isEmpty) {
      contradictions.addAll([
        '강해 보이지만 때로는 약한 모습도 보여요',
        '독립적이면서도 누군가의 관심이 필요해요',
        '자신감 있어 보이지만 가끔 의심도 해요',
      ]);
    }

    return contradictions.take(3).toList();
  }

  static List<String> _getFallbackPersonalityTags(OnboardingState state) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;

    final tags = <String>[];

    // 첫 번째 태그: 내향성 기반
    if (introversion <= 3) {
      tags.add('활발함');
    } else if (introversion >= 7) {
      tags.add('조용함');
    } else {
      tags.add('균형잡힌');
    }

    // 두 번째 태그: 온기와 능력 조합
    if (warmth >= 7 && competence >= 7) {
      tags.add('따뜻하고능숙');
    } else if (warmth >= 7) {
      tags.add('따뜻함');
    } else if (competence >= 7) {
      tags.add('능숙함');
    } else if (warmth <= 3) {
      tags.add('차가움');
    } else if (competence <= 3) {
      tags.add('서툰');
    } else {
      tags.add('평범함');
    }

    return tags;
  }

  static String _getFallbackGreeting(
    OnboardingState state,
    PersonalityProfile? profile,
  ) {
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final introversion = state.introversion ?? 5;
    final nickname = state.userInput?.nickname ?? '친구';

    // 성격에 따른 기본 인사말 생성
    if (warmth >= 7) {
      return "안녕! 나는 $nickname이야~ 오늘 하루 어때?";
    } else if (introversion >= 7) {
      return "...안녕. $nickname이라고 해. 조용히 지내자.";
    } else if (competence >= 7) {
      return "완벽한 타이밍이네! $nickname이야, 뭐든 물어봐!";
    } else {
      return "안녕하세요! 저는 $nickname이에요. 만나서 반가워요!";
    }
  }

  /// 역할 요약 프롬프트 생성
  static String _buildPurposeSummaryPrompt(String purpose, String objectType) {
    return '''
다음 역할/목적을 10글자 이내로 간결하게 요약해주세요:

**사물 종류:** $objectType
**역할/목적:** $purpose

**요약 가이드라인:**
1. 반드시 10글자 이내로 작성
2. 핵심 기능이나 역할을 명확히 표현
3. "~지기", "~도우미", "~친구" 등의 친근한 표현 사용
4. 사물의 특성과 역할이 잘 드러나도록

**예시:**
- "운동할 때 나를 채찍질해주고 격려해주는 역할" → "운동지기"
- "공부할 때 집중력을 도와주는 친구" → "공부도우미"
- "스트레스 받을 때 위로해주는 존재" → "위로친구"
- "일정 관리하고 알람 역할" → "일정지기"

10글자 이내의 간결한 요약만 생성해주세요:
''';
  }

  /// 폴백 역할 요약 함수
  static String _getFallbackPurposeSummary(String purpose) {
    if (purpose.length <= 10) {
      return purpose;
    }

    // 핵심 키워드 추출 및 요약
    final keywords = {
      '운동': '운동지기',
      '헬스': '헬스지기',
      '다이어트': '다이어트',
      '공부': '공부지기',
      '학습': '학습지기',
      '시험': '시험지기',
      '위로': '위로지기',
      '상담': '상담지기',
      '대화': '대화지기',
      '친구': '친구',
      '알람': '알람지기',
      '깨워': '알람지기',
      '일정': '일정지기',
      '관리': '관리지기',
      '채찍질': '채찍지기',
      '닥달': '닥달지기',
      '응원': '응원지기',
      '격려': '격려지기',
      '멘탈': '멘탈지기',
      '감정': '감정지기',
      '스트레스': '힐링지기',
      '힐링': '힐링지기',
      '음악': '음악지기',
      '독서': '독서지기',
      '요리': '요리지기',
      '청소': '청소지기',
    };

    // 키워드 매칭
    for (final entry in keywords.entries) {
      if (purpose.contains(entry.key)) {
        return entry.value;
      }
    }

    // 키워드가 없으면 첫 7글자 + ...
    return purpose.substring(0, 7) + '...';
  }
}
