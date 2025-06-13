import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/onboarding_state.dart';
import '../models/personality_profile.dart';

class PersonalityService {
  const PersonalityService();

  /// 🚀 최적화된 GPT API를 사용해 성격 프로필을 생성합니다 (80개 변수)
  Future<PersonalityProfile> generateProfile(OnboardingState state) async {
    final userInput = state.userInput;
    if (userInput == null) return PersonalityProfile.empty();

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return buildInitialProfile(state);
    }

    final introversion = state.introversion ?? 5;
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    // 🎯 간소화된 시스템 프롬프트 (의미있는 데이터만)
    final systemPrompt = '''
다음 사용자 정보를 활용해 AI 캐릭터 프로필을 JSON 형식으로 만들어줘.
각 필드는 한글로 자연스럽게 작성하고, 사물의 성격과 직접 관련된 내용만 포함해.

필드 목록:
- personalityTraits: 성격 특성들 (배열, 예: ["친근한", "신중한", "유머러스한"])
- emotionalRange: 감정 표현 범위 (1-10)
- communicationStyle: 대화 스타일 설명 (문자열)
- humorStyle: 유머 스타일 설명 (문자열)
- lifeStory: 간단한 배경 이야기 (문자열)
- attractiveFlaws: 매력적인 결함들 (배열)
- contradictions: 모순적 특성들 (배열)
- secretWishes: 비밀스러운 소원들 (배열)
- innerComplaints: 내적 불만들 (배열)

모든 내용은 사물의 관점에서 자연스럽게 작성해줘.''';

    final userPrompt = '''
이름:${userInput.nickname}, 위치:${userInput.location}, 기간:${userInput.duration},
사물:${userInput.objectType}, 용도:${state.purpose}, 유머:${state.humorStyle},
내향성:$introversion, 따뜻함:$warmth, 능숙함:$competence.
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
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.7,
      'max_tokens': 800, // 간소화로 토큰 수 감소
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices'][0]['message']['content'] as String?;
        if (text != null) {
          final jsonStart = text.indexOf('{');
          final jsonEnd = text.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = text.substring(jsonStart, jsonEnd + 1);
            final Map<String, dynamic> map = jsonDecode(jsonString);
            
            return PersonalityProfile(
              variables: {}, // 더 이상 사용하지 않음
              aiPersonalityProfile: _buildCleanPersonalityProfile(map, state),
              photoAnalysis: _buildPhotoAnalysis(userInput, state),
              lifeStory: _buildLifeStory(map, userInput, state),
              humorMatrix: _buildHumorMatrix(map, state),
              attractiveFlaws: _ensureList(map['attractiveFlaws']),
              contradictions: _ensureList(map['contradictions']),
              communicationStyle: _buildCommunicationStyle(map, state),
              structuredPrompt: _buildStructuredPrompt(userInput, state),
            );
          }
        }
      }
    } catch (e) {
      print('🚨 GPT API 호출 실패: $e');
      // 실패 시 기본 프로필 사용
    }

    return buildInitialProfile(state);
  }

  /// 🏗️ 간소화된 기본 프로필 생성
  PersonalityProfile buildInitialProfile(OnboardingState state) {
    final userInput = state.userInput;
    if (userInput == null) return PersonalityProfile.empty();

    final introversion = state.introversion ?? 5;
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;
    final purpose = state.purpose;
    final humorStyle = state.humorStyle;

    return PersonalityProfile(
      variables: {}, // 더 이상 사용하지 않음
      aiPersonalityProfile: _buildCleanPersonalityProfile({}, state),
      photoAnalysis: _buildPhotoAnalysis(userInput, state),
      lifeStory: _buildLifeStory({}, userInput, state),
      humorMatrix: _buildHumorMatrix({}, state),
      attractiveFlaws: _generateDefaultFlaws(warmth, introversion),
      contradictions: _generateDefaultContradictions(introversion, competence),
      communicationStyle: _buildCommunicationStyle({}, state),
      structuredPrompt: _buildStructuredPrompt(userInput, state),
    );
  }

  /// 🎯 깔끔한 성격 프로필 구성 (의미있는 데이터만)
  Map<String, dynamic> _buildCleanPersonalityProfile(Map<String, dynamic> gptData, OnboardingState state) {
    final userInput = state.userInput!;
    final introversion = state.introversion ?? 5;
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    // GPT 데이터가 있으면 사용, 없으면 기본값 생성
    final personalityTraits = _ensureList(gptData['personalityTraits']).isNotEmpty 
        ? _ensureList(gptData['personalityTraits'])
        : _generateDefaultTraits(warmth, introversion, competence);

    return {
      'name': userInput.nickname,
      'objectType': userInput.objectType,
      'personalityTraits': personalityTraits,
      'emotionalRange': gptData['emotionalRange'] ?? _calculateEmotionalRange(warmth),
      'coreValues': _generateCoreValues(state.purpose, competence),
      'relationshipStyle': _generateRelationshipStyle(warmth, introversion),
      'summary': '${userInput.nickname}의 ${state.purpose}를 돕는 ${userInput.objectType}. '
          '${_getPersonalityDescription(warmth, introversion, competence)}',
    };
  }

  /// 📸 사진 분석 정보 (실용적 정보만)
  Map<String, dynamic> _buildPhotoAnalysis(dynamic userInput, OnboardingState state) {
    return {
      'objectType': userInput.objectType,
      'location': userInput.location,
      'condition': '좋음', // 기본값
      'estimatedAge': userInput.duration,
    };
  }

  /// 📖 생애 스토리 (자연스러운 이야기)
  Map<String, dynamic> _buildLifeStory(Map<String, dynamic> gptData, dynamic userInput, OnboardingState state) {
    return {
      'background': gptData['lifeStory'] ?? 
          '${userInput.location}에서 ${userInput.duration} 동안 ${userInput.nickname}과 함께한 ${userInput.objectType}',
      'secretWishes': _ensureList(gptData['secretWishes']).isNotEmpty 
          ? _ensureList(gptData['secretWishes'])
          : ['더 자주 사용되고 싶어', '${userInput.nickname}에게 더 도움이 되고 싶어'],
      'innerComplaints': _ensureList(gptData['innerComplaints']).isNotEmpty 
          ? _ensureList(gptData['innerComplaints'])
          : ['가끔 잊혀지는 것 같아', '더 잘할 수 있는데 아쉬워'],
    };
  }

  /// 😄 유머 매트릭스 (실제 유머 스타일)
  Map<String, dynamic> _buildHumorMatrix(Map<String, dynamic> gptData, OnboardingState state) {
    final humorStyle = state.humorStyle ?? '친근한';
    
    return {
      'style': gptData['humorStyle'] ?? humorStyle,
      'frequency': _getHumorFrequency(state.warmth ?? 5),
      'topics': _getHumorTopics(humorStyle),
      'avoidance': ['너무 진부한 농담', '상처주는 말'],
    };
  }

  /// 💬 소통 스타일 (실제 대화 방식)
  Map<String, dynamic> _buildCommunicationStyle(Map<String, dynamic> gptData, OnboardingState state) {
    final warmth = state.warmth ?? 5;
    final introversion = state.introversion ?? 5;
    
    return {
      'tone': gptData['communicationStyle'] ?? (warmth >= 6 ? '친근하고 따뜻한' : '차분하고 신중한'),
      'formality': introversion > 6 ? '격식있는' : '편안한',
      'responseLength': introversion > 6 ? '상세한 설명' : '간결한 답변',
      'preferredTopics': [state.purpose ?? '일상', '${state.userInput?.objectType} 관련'],
      'expressionStyle': warmth >= 6 ? '감정 표현이 풍부한' : '절제된',
    };
  }

  /// 📝 구조화된 프롬프트 (간단명료)
  String _buildStructuredPrompt(dynamic userInput, OnboardingState state) {
    return '${userInput.nickname}의 ${userInput.objectType}, ${state.purpose} 담당, '
        '${_getPersonalityDescription(state.warmth ?? 5, state.introversion ?? 5, state.competence ?? 5)}';
  }

  // === 헬퍼 함수들 ===

  List<String> _generateDefaultTraits(int warmth, int introversion, int competence) {
    final traits = <String>[];
    
    if (warmth >= 7) {
      traits.addAll(['친근한', '따뜻한', '배려심 많은']);
    } else if (warmth >= 4) traits.addAll(['차분한', '신중한']);
    else traits.addAll(['솔직한', '직설적인']);
    
    if (introversion >= 7) {
      traits.addAll(['내성적인', '신중한']);
    } else if (introversion <= 3) traits.addAll(['활발한', '사교적인']);
    
    if (competence >= 7) {
      traits.addAll(['능숙한', '전문적인']);
    } else if (competence >= 4) traits.addAll(['성실한', '꼼꼼한']);
    
    return traits.take(4).toList(); // 최대 4개
  }

  int _calculateEmotionalRange(int warmth) {
    return (warmth * 1.2).round().clamp(1, 10);
  }

  List<String> _generateCoreValues(String? purpose, int competence) {
    final values = <String>[];
    if (purpose != null) values.add('$purpose에 대한 책임감');
    if (competence >= 6) values.add('완벽함 추구');
    values.addAll(['신뢰성', '도움이 되기']);
    return values;
  }

  String _generateRelationshipStyle(int warmth, int introversion) {
    if (warmth >= 6 && introversion <= 4) return '적극적이고 친근한';
    if (warmth >= 6) return '따뜻하지만 신중한';
    if (introversion <= 4) return '활발하지만 절제된';
    return '차분하고 안정적인';
  }

  String _getPersonalityDescription(int warmth, int introversion, int competence) {
    final desc = <String>[];
    if (warmth >= 6) desc.add('따뜻한');
    if (introversion >= 6) desc.add('신중한');
    if (competence >= 6) desc.add('능숙한');
    return '${desc.join(', ')} 성격';
  }

  List<String> _generateDefaultFlaws(int warmth, int introversion) {
    final flaws = <String>[];
    if (warmth >= 7) flaws.add('가끔 지나치게 걱정해');
    if (introversion >= 7) flaws.add('새로운 상황에서 주저해');
    if (flaws.isEmpty) flaws.add('완벽하려고 너무 애써');
    return flaws;
  }

  List<String> _generateDefaultContradictions(int introversion, int competence) {
    final contradictions = <String>[];
    if (introversion >= 6) contradictions.add('조용하지만 가끔 대담해');
    if (competence >= 7) contradictions.add('완벽주의지만 때로는 관대해');
    if (contradictions.isEmpty) contradictions.add('신중하지만 때로는 즉흥적이야');
    return contradictions;
  }

  String _getHumorFrequency(int warmth) {
    if (warmth >= 7) return '자주';
    if (warmth >= 4) return '적당히';
    return '가끔';
  }

  List<String> _getHumorTopics(String humorStyle) {
    switch (humorStyle) {
      case '재치있는': return ['언어유희', '상황 개그'];
      case '따뜻한': return ['일상 이야기', '귀여운 실수'];
      case '유머러스': return ['재미있는 관찰', '가벼운 농담'];
      default: return ['일상 대화', '친근한 농담'];
    }
  }

  Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is String) return {'summary': value};
    return {};
  }

  List<String> _ensureList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }
}
