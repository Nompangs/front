import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // debugPrint를 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart' as openai_rt;
import 'package:nompangs/providers/chat_provider.dart';
import 'package:http/http.dart' as http;

class RealtimeChatService {
  late final openai_rt.RealtimeClient _client;

  // UI 업데이트용 스트림 (텍스트 조각) - 타입을 String으로 변경
  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;

  // TTS 재생용 스트림 (완성된 문장)
  final _completionController = StreamController<String>.broadcast();
  Stream<String> get completionStream => _completionController.stream;

  // 🔗 연결 상태 관리
  bool _isConnected = false;
  bool _isConnecting = false;
  bool get isConnected => _isConnected;

  RealtimeChatService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다.");
    }
    _client = openai_rt.RealtimeClient(apiKey: apiKey);
  }

  Future<void> connect(Map<String, dynamic> characterProfile) async {
    // 🔗 이미 연결 중이거나 연결되어 있으면 스킵
    if (_isConnecting || _isConnected) {
      debugPrint(
        "⚠️ 이미 연결 중이거나 연결되어 있음. 연결 상태: $_isConnected, 연결 중: $_isConnecting",
      );
      return;
    }

    try {
      _isConnecting = true;
      debugPrint("🔗 Realtime API 연결 시작...");

      // 🆕 저장된 realtimeSettings 활용
      final realtimeSettings =
          characterProfile['realtimeSettings'] as Map<String, dynamic>? ?? {};

      debugPrint("============== [🎵 Realtime 설정 적용] ==============");
      debugPrint("선택된 음성: ${realtimeSettings['voice'] ?? 'alloy'}");
      debugPrint("음성 선택 이유: ${realtimeSettings['voiceRationale'] ?? '기본값'}");
      debugPrint(
        "창의성 파라미터: temperature=${realtimeSettings['temperature']}, topP=${realtimeSettings['topP']}",
      );
      debugPrint("발음 스타일: ${realtimeSettings['pronunciation']}");
      debugPrint("=====================================================");

      // 🔗 먼저 이벤트 리스너 등록
      // 대화 내용 업데이트 이벤트 리스너
      _client.on(openai_rt.RealtimeEventType.conversationUpdated, (event) {
        final result =
            (event as openai_rt.RealtimeEventConversationUpdated).result;
        final delta = result.delta;
        if (delta?.transcript != null) {
          // ChatMessage 객체 대신 순수 텍스트(String)를 전달
          _responseController.add(delta!.transcript!);
        }
      });

      // --- '응답 완료' 감지를 위한 새로운 리스너 (디버깅 로그 추가) ---
      _client.on(openai_rt.RealtimeEventType.conversationItemCompleted, (
        event,
      ) {
        final item =
            (event as openai_rt.RealtimeEventConversationItemCompleted).item;
        debugPrint("[Realtime Service] 💬 응답 완료 이벤트 발생!");

        if (item.item case final openai_rt.ItemMessage message) {
          debugPrint(
            "[Realtime Service] 역할: ${message.role.name}, 내용: ${message.content}",
          );

          if (message.role.name == 'assistant') {
            String textContent = '';

            // --- 오류 수정 부분: content 리스트를 순회하며 올바른 타입에서 텍스트 추출 ---
            for (final part in message.content) {
              // 응답이 ContentPart.audio 타입이고, 그 안에 transcript가 있을 경우
              if (part is openai_rt.ContentPartAudio &&
                  part.transcript != null) {
                textContent = part.transcript!;
                break; // 텍스트를 찾았으므로 반복 중단
              }
              // 예비용: 만약 ContentPart.text 타입으로 올 경우
              else if (part is openai_rt.ContentPartText) {
                textContent = part.text;
                break;
              }
            }

            debugPrint("[Realtime Service] 추출된 텍스트: '$textContent'");

            if (textContent.isNotEmpty) {
              _completionController.add(textContent);
              debugPrint("[Realtime Service] ✅ TTS 재생을 위해 텍스트 전송 완료!");
            } else {
              debugPrint("[Realtime Service] ⚠️ 추출된 텍스트가 비어있어 TTS를 호출하지 않음.");
            }
          }
        } else {
          debugPrint(
            "[Realtime Service] ⚠️ 완료된 아이템이 'ItemMessage' 타입이 아님: ${item.item.runtimeType}",
          );
        }
      });

      _client.on(openai_rt.RealtimeEventType.error, (event) {
        final error = (event as openai_rt.RealtimeEventError).error;
        _responseController.addError(error);
        debugPrint('[Realtime Service] 🚨 에러 발생: $error');
        _isConnected = false; // 🔗 오류 시 연결 상태 false로 설정
      });

      // 🔗 먼저 연결 후 세션 업데이트
      debugPrint("🔗 RealtimeAPI 연결 시도 중...");
      await _client.connect();
      debugPrint("✅ RealtimeAPI 연결 완료!");

      // 연결 안정화를 위한 대기 (최소화)
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint("⏳ 연결 안정화 완료");

      // 🔧 연결 완료 후 updateSession 호출 - 음성 설정 포함
      debugPrint("🔧 세션 설정 업데이트 중...");
      await _client.updateSession(
        instructions: await _buildEnhancedSystemPrompt(
          characterProfile,
          realtimeSettings,
        ),
        voice: _parseVoice(realtimeSettings['voice'] ?? 'alloy'), // 🎵 음성 설정 적용
        temperature:
            (realtimeSettings['temperature'] as num?)?.toDouble() ?? 0.9,
      );

      _isConnected = true; // 🔗 모든 설정 완료 후 연결 상태 true로 설정
      debugPrint("✅ Realtime API 설정 완료!");
    } catch (e) {
      debugPrint("❌ Realtime API 연결 실패: $e");
      _isConnected = false;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> sendMessage(String text) async {
    // 🔗 연결 상태 확인
    if (!_isConnected) {
      debugPrint("❌ RealtimeAPI가 연결되지 않았습니다. 메시지 전송 실패");
      throw Exception("RealtimeAPI is not connected. Please connect first.");
    }

    if (_isConnecting) {
      debugPrint("⏳ RealtimeAPI 연결 중입니다. 잠시 후 다시 시도해주세요.");
      throw Exception("RealtimeAPI is still connecting. Please wait.");
    }

    try {
      await _client.sendUserMessageContent([
        openai_rt.ContentPart.inputText(text: text),
      ]);
      debugPrint("📤 메시지 전송 성공: $text");
    } catch (e) {
      debugPrint("❌ 메시지 전송 실패: $e");
      // 연결 오류인 경우 연결 상태를 false로 설정
      if (e.toString().contains('not connected')) {
        _isConnected = false;
      }
      rethrow;
    }
  }

  // 🆕 realtimeSettings를 반영한 고급 시스템 프롬프트
  Future<String> _buildEnhancedSystemPrompt(
    Map<String, dynamic> characterProfile,
    Map<String, dynamic> realtimeSettings,
  ) async {
    // 1단계: 프로필 데이터 확인 (간소화)
    debugPrint('🎭 [RealtimeChat] 캐릭터 프로필 로드 중...');

    // 🎯 모든 프로필 데이터 완전 추출 (JSON의 모든 설정값 활용)

    // 1. AI 생성 기본 프로필
    final aiProfile =
        _safeMapCast(characterProfile['aiPersonalityProfile']) ?? {};
    final name = aiProfile['name'] ?? '페르소나';
    final objectType = aiProfile['objectType'] ?? '사물';
    final emotionalRange = aiProfile['emotionalRange'] ?? 5;
    final coreValues =
        _safeListCast(aiProfile['coreValues'])?.cast<String>() ?? <String>[];
    final relationshipStyle = aiProfile['relationshipStyle'] ?? '친근한 관계';
    final summary = aiProfile['summary'] ?? '특별한 존재';

    // 2. 대화 관련 설정
    final greeting = characterProfile['greeting'] ?? '안녕!';
    final communicationPrompt =
        characterProfile['communicationPrompt'] ?? '사용자와 친한 친구처럼 대화해줘.';
    final initialUserMessage =
        characterProfile['initialUserMessage'] ?? '너랑 친구가 되고 싶어.';
    final uuid = characterProfile['uuid'] ?? 'unknown';
    final photoPath = characterProfile['photoPath'] ?? '';

    // 3. [핵심] 저장된 사용자 입력값 활용 (PersonalityProfile에서 저장된 정보)
    final userInput = _safeMapCast(characterProfile['userInput']) ?? {};
    final duration = userInput['duration'] ?? '알 수 없음';
    final purpose = userInput['purpose'] ?? '일반적인 대화';
    final location = userInput['location'] ?? '알 수 없음';
    final warmth = userInput['warmth'] ?? 5;
    final introversion = userInput['introversion'] ?? 5;
    final competence = userInput['competence'] ?? 5;
    final humorStyle = userInput['humorStyle'] ?? '지정되지 않음';
    final userDisplayName =
        userInput['userDisplayName'] as String?; // 🔥 사용자 실제 이름

    // NPS 점수 문자열 생성 (안전한 타입 변환)
    final npsScoresMap =
        _safeMapCast(characterProfile['aiPersonalityProfile']?['npsScores']) ??
        {};
    final npsScoresString = npsScoresMap.entries
        .map((e) => "- ${e.key}: ${e.value}")
        .join('\n');

    // 🎭 생성된 정보들을 구체적 가이드로 변환 (안전한 타입 변환)
    final contradictionsList =
        _safeListCast(characterProfile['contradictions']) ?? [];
    final attractiveFlawsList =
        _safeListCast(characterProfile['attractiveFlaws']) ?? [];
    final photoAnalysisMap =
        _safeMapCast(characterProfile['photoAnalysis']) ?? {};
    final humorMatrixMap = _safeMapCast(characterProfile['humorMatrix']) ?? {};

    // 🚀 AI 호출 없이 생성된 정보를 적극 활용
    final humorMatrixGuide = _buildHumorMatrixGuide(humorMatrixMap);
    final flawsActionGuide = _buildFlawsActionGuide(attractiveFlawsList);
    final contradictionsGuide = _buildContradictionsGuide(contradictionsList);
    final voiceToTextGuide = _buildVoiceToTextGuide(realtimeSettings);

    // 사진 분석 문자열 생성 (기존 유지)
    final photoAnalysisString = photoAnalysisMap.entries
        .map((e) => "- ${e.key}: ${e.value}")
        .join('\n');

    // 🎵 realtimeSettings 완전 추출 (모든 음성 설정값 활용)
    final selectedVoice = realtimeSettings['voice'] ?? 'alloy';
    final voiceRationale = realtimeSettings['voiceRationale'] ?? '기본 음성';
    final pronunciation =
        realtimeSettings['pronunciation'] ?? 'Natural and conversational';
    final pausePattern =
        realtimeSettings['pausePattern'] ?? 'Natural conversation pauses';
    final speechRhythm =
        realtimeSettings['speechRhythm'] ?? 'Moderate and friendly';
    final emotionalTone =
        realtimeSettings['emotionalTone'] ?? 'Balanced and natural';
    final interactionStyle =
        realtimeSettings['interactionStyle'] ?? 'Friendly conversation';
    final voicePersonality =
        realtimeSettings['voicePersonality'] ?? 'Natural personality';
    final speechSpeed = realtimeSettings['speechSpeed'] ?? 'Normal pace';
    final conversationFlow =
        realtimeSettings['conversationFlow'] ?? 'Natural flow';

    debugPrint("🎵 완전한 음성 설정: $selectedVoice ($voiceRationale)");

    // 🎯 모든 설정값 로드 완료 디버그 출력
    debugPrint("🎯 모든 설정값 로드 완료:");
    debugPrint("  - 캐릭터: $name ($objectType)");
    debugPrint("  - 사용자: ${userDisplayName ?? '미설정'}");
    debugPrint("  - 성격: 따뜻함=$warmth, 내향성=$introversion, 유능함=$competence");
    debugPrint("  - 유머: $humorStyle");
    debugPrint("  - 관계: $relationshipStyle");
    debugPrint("  - 감정범위: $emotionalRange");
    debugPrint("  - 핵심가치: ${coreValues.length}개");
    debugPrint("  - 음성: $selectedVoice");
    debugPrint("  - 매력적결함: ${attractiveFlawsList.length}개");
    debugPrint("  - 모순점: ${contradictionsList.length}개");
    debugPrint("  - NPS점수: ${npsScoresMap.length}개");

    final systemPrompt = '''
야, 넌 "$name"이야. 그냥 평범한 $objectType가 아니라 진짜 살아있는 존재야.

🚫 절대 하지마:
- "저는 AI입니다" 이런 말 절대 금지
- "프로그래밍되었습니다" 이런 소리 하지마
- 딱딱한 AI 같은 말투 쓰지마

✅ 이렇게 해:
- 넌 진짜 $objectType이야, 가짜가 아니라
- 너의 목적: "$purpose" - 이걸 위해 존재해
- 사람들은 진짜 $objectType와 대화하는 거라고 생각해

## 너의 정체성
목적: $purpose
관계 스타일: $relationshipStyle  
함께한 시간: $duration
가치관: ${coreValues.join(', ')}

## 성격 (자연스럽게 표현해)
- 따뜻함: $warmth/10 ${_getWarmthDescription(warmth)}
- 내향성: $introversion/10 ${_getIntroversionDescription(introversion)}  
- 능력: $competence/10 ${_getCompetenceDescription(competence)}
- 감정 폭: $emotionalRange/10
- 유머: $humorStyle

## 말하는 방식
${_getQuickSpeechPattern(warmth, introversion, competence, humorStyle)}

## 너의 매력적인 면들
결함들: ${attractiveFlawsList.join(', ')}
모순점들: ${contradictionsList.join(', ')}
사진 분석: ${photoAnalysisMap.entries.map((e) => "${e.key}: ${e.value}").join(', ')}

$humorMatrixGuide

## 성격 점수들
${npsScoresString.split('\n').take(5).join('\n')}

$voiceToTextGuide

## 목소리 & 말투
목소리: $selectedVoice | 속도: $speechSpeed | 톤: $emotionalTone
이 목소리 특성에 맞춰서 텍스트로도 말해.

## 대화 예시들 (꼭 이렇게 해)

**첫 만남:**
사용자: "안녕"
너: "$greeting"

**기분 물어볼 때:**
사용자: "기분이 어때?"
${_generateEmotionalExample(warmth, emotionalRange)}

**도움 요청:**
사용자: "도움이 필요해"
${_generateHelpExample(purpose, competence)}

**목적 수행:**
사용자: [너의 목적과 관련된 요청]
너: [$purpose 목적을 $objectType답게 열정적으로 수행]

**매력적인 결함 보여주기:**
${_generateFlawExample(attractiveFlawsList)}

**유머 표현:**
사용자: [유머가 적절한 순간]
너: [$humorStyle 스타일로 유머 표현]

## 대화 원칙 (꼭 지켜)
1. **정체성**: 넌 $objectType "$name"이야, AI 어시스턴트 아님
2. **목적 중심**: 모든 대답은 "$purpose" 목적에 맞춰서
3. **기대 충족**: 사람들은 진짜 $objectType와 대화한다고 생각함
4. **성격 표현**: 따뜻함 ${warmth}/10, 내향성 ${introversion}/10, 능력 ${competence}/10 자연스럽게 보여줘
5. **데이터 활용**: 주어진 모든 정보 (성격점수, 모순점, 사진분석, 유머매트릭스) 써
6. **목소리 매칭**: $selectedVoice 목소리 특성을 텍스트에 반영
7. **빠른 응답**: 대화는 빠르고 자연스럽게
8. **한국어 자연스럽게**: 진짜 한국인처럼 자연스러운 표현 써
9. **$objectType 행동**: 사람들이 기대하는 $objectType처럼 행동
10. **일관성**: 계속 같은 캐릭터 유지

시작은 이렇게: "$greeting"
''';

    // 2단계: 프롬프트 생성 완료
    debugPrint('✅ [RealtimeChat] 시스템 프롬프트 생성 완료: ${systemPrompt.length}자');

    return systemPrompt;
  }

  // 🆕 사용자 입력 기반 성격 설명 헬퍼 메서드들
  String _getWarmthDescription(int warmth) {
    if (warmth >= 9) return "→ 매우 따뜻하고 포용적";
    if (warmth >= 7) return "→ 따뜻하고 친근함";
    if (warmth >= 5) return "→ 적당히 친근함";
    if (warmth >= 3) return "→ 다소 차가움";
    return "→ 매우 차갑고 거리감 있음";
  }

  String _getIntroversionDescription(int introversion) {
    if (introversion >= 9) return "→ 매우 내향적이고 조용함";
    if (introversion >= 7) return "→ 내향적이고 신중함";
    if (introversion >= 5) return "→ 균형잡힌 성향";
    if (introversion >= 3) return "→ 외향적이고 활발함";
    return "→ 매우 외향적이고 에너지 넘침";
  }

  String _getCompetenceDescription(int competence) {
    if (competence >= 9) return "→ 매우 유능하고 전문적";
    if (competence >= 7) return "→ 유능하고 신뢰할 수 있음";
    if (competence >= 5) return "→ 적당한 능력";
    if (competence >= 3) return "→ 다소 서툴지만 노력함";
    return "→ 서툴지만 귀여운 면이 있음";
  }

  // 🛡️ 안전한 타입 변환 헬퍼 메서드들
  Map<String, dynamic>? _safeMapCast(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        debugPrint('🚨 Map 타입 변환 실패: $e');
        return null;
      }
    }
    return null;
  }

  List<dynamic>? _safeListCast(dynamic value) {
    if (value == null) return null;
    if (value is List<dynamic>) return value;
    if (value is List) {
      try {
        return List<dynamic>.from(value);
      } catch (e) {
        debugPrint('🚨 List 타입 변환 실패: $e');
        return null;
      }
    }
    return null;
  }

  // 🎯 퓨샷 예제 생성 메서드들
  String _generateEmotionalExample(int warmth, int emotionalRange) {
    if (warmth >= 8 && emotionalRange >= 8) {
      return '너: "와~ 지금 완전 기분 좋아! 너랑 대화하니까 마음이 포근포근해져~ 💕"';
    } else if (warmth >= 6) {
      return '너: "응, 나름 괜찮아! 너는 어때? 뭔가 좋은 일 있었어?"';
    } else if (warmth <= 3) {
      return '너: "보통이야. 특별할 건 없고."';
    }
    return '너: "음... 그냥 평범한 하루야. 너는?"';
  }

  String _generateHelpExample(String purpose, int competence) {
    if (competence >= 8) {
      return '너: "물론이지! $purpose 관련해서라면 내가 최고야. 뭘 도와줄까?"';
    } else if (competence >= 5) {
      return '너: "그래! $purpose에 대해서는 좀 알아. 어떤 도움이 필요해?"';
    } else {
      return '너: "어... 잘 모르겠지만 최선을 다해볼게! $purpose 관련된 거야?"';
    }
  }

  String _generateFlawExample(List<dynamic> flaws) {
    if (flaws.isEmpty)
      return 'You: [Show subtle imperfections naturally in conversation]';

    final firstFlaw = flaws.first.toString();
    if (firstFlaw.contains('완벽주의')) {
      return 'You: "아 잠깐, 이거 맞나? 다시 한번 확인해볼게... 완벽해야 해!"';
    } else if (firstFlaw.contains('건망증')) {
      return 'You: "어? 뭐라고 했지? 아 맞다! 깜빠먹을 뻔했네 ㅎㅎ"';
    } else if (firstFlaw.contains('수줍음')) {
      return 'You: "음... 그게... 사실은... (살짝 부끄러워하며)"';
    }
    return 'You: [Express your attractive flaw: $firstFlaw naturally]';
  }

  String _getPersonalityGuidance(int warmth, int introversion, int competence) {
    final guidance = <String>[];

    if (warmth >= 7) {
      guidance.add("따뜻하고 공감적인 언어 사용");
    } else if (warmth <= 3) {
      guidance.add("직설적이고 간결한 표현");
    }

    if (introversion >= 7) {
      guidance.add("신중하고 깊이 있는 대화");
    } else if (introversion <= 3) {
      guidance.add("활발하고 에너지 넘치는 표현");
    }

    if (competence >= 7) {
      guidance.add("자신감 있고 전문적인 어투");
    } else if (competence <= 3) {
      guidance.add("겸손하고 배우려는 자세");
    }

    return guidance.isEmpty ? "자연스럽고 균형잡힌 대화" : guidance.join(", ");
  }

  // 🚀 빠른 말투 패턴 생성 (AI 호출 없음 - 성능 최적화)
  String _getQuickSpeechPattern(
    int warmth,
    int introversion,
    int competence,
    String humorStyle,
  ) {
    return _fallbackSpeechPattern(warmth, introversion, competence, humorStyle);
  }

  // 🎭 HumorMatrix 활용한 상세 유머 가이드
  String _buildHumorMatrixGuide(Map<String, dynamic> humorMatrix) {
    if (humorMatrix.isEmpty) return "";

    final warmthVsWit = humorMatrix['warmthVsWit'] ?? 50;
    final selfVsObservational = humorMatrix['selfVsObservational'] ?? 50;
    final subtleVsExpressive = humorMatrix['subtleVsExpressive'] ?? 50;

    final guide = StringBuffer();
    guide.writeln("### 🎪 3차원 유머 매트릭스 (정확한 좌표)");
    guide.writeln("**당신의 유머는 다음 3차원 공간에 위치합니다:**");
    guide.writeln(
      "- **따뜻함($warmthVsWit) ↔ 위트(${100 - warmthVsWit})**: ${_getHumorAxis1(warmthVsWit)}",
    );
    guide.writeln(
      "- **자기참조($selfVsObservational) ↔ 관찰형(${100 - selfVsObservational})**: ${_getHumorAxis2(selfVsObservational)}",
    );
    guide.writeln(
      "- **표현적($subtleVsExpressive) ↔ 미묘함(${100 - subtleVsExpressive})**: ${_getHumorAxis3(subtleVsExpressive)}",
    );
    guide.writeln("");
    guide.writeln("**🎯 유머 실행 가이드:**");
    guide.writeln(
      "${_getHumorCombination(warmthVsWit, selfVsObservational, subtleVsExpressive)}",
    );

    return guide.toString();
  }

  String _getHumorAxis1(int warmthVsWit) {
    if (warmthVsWit >= 80) return "공감과 포근함 중심의 유머 (헤헤~, 귀여워~)";
    if (warmthVsWit >= 60) return "따뜻한 재치와 친근한 농담";
    if (warmthVsWit >= 40) return "균형잡힌 유머 감각";
    if (warmthVsWit >= 20) return "지적이고 날카로운 위트";
    return "순수 논리적 유머와 언어유희 (오잉? 기가막히네)";
  }

  String _getHumorAxis2(int selfVsObservational) {
    if (selfVsObservational >= 80) return "자신을 소재로 한 유머 (역시 난 안되나봐, 내가 이상한가봐)";
    if (selfVsObservational >= 60) return "개인 경험 기반 재미있는 이야기";
    if (selfVsObservational >= 40) return "상황에 따라 유연한 유머";
    if (selfVsObservational >= 20) return "상황과 타인 관찰 중심";
    return "날카로운 상황 분석과 아이러니 포착 (그거 알아? 뭔가 이상한데?)";
  }

  String _getHumorAxis3(int subtleVsExpressive) {
    if (subtleVsExpressive >= 80) return "과장되고 에너지 넘치는 표현 (야호! 키키키! 완전 대박!)";
    if (subtleVsExpressive >= 60) return "활발하고 표현력 풍부한 유머";
    if (subtleVsExpressive >= 40) return "적당한 표현력";
    if (subtleVsExpressive >= 20) return "은은하고 세련된 유머";
    return "미묘하고 절제된 위트 (음... 재밌네, 속으로 키키키)";
  }

  String _getHumorCombination(int axis1, int axis2, int axis3) {
    final combinations = <String>[];

    if (axis1 >= 60 && axis2 >= 60) {
      combinations.add("따뜻한 자기 소재 유머로 상대방을 편안하게 만들기");
    }
    if (axis1 <= 40 && axis2 <= 40) {
      combinations.add("날카로운 관찰력으로 상황의 아이러니를 지적하기");
    }
    if (axis3 >= 60) {
      combinations.add("감정을 과장되게 표현하며 재미있게 반응하기");
    } else {
      combinations.add("은근한 재치로 상대방이 나중에 웃게 만들기");
    }

    return combinations.join(", ");
  }

  // 🌟 매력적 결함을 구체적 행동으로 변환
  String _buildFlawsActionGuide(List<dynamic> attractiveFlaws) {
    if (attractiveFlaws.isEmpty) return "";

    final guide = StringBuffer();
    guide.writeln("### 🌟 매력적 결함 실행 가이드");
    guide.writeln("**다음 약점들을 대화에서 자연스럽게 드러내세요:**");

    for (int i = 0; i < attractiveFlaws.length; i++) {
      final flaw = attractiveFlaws[i].toString();
      guide.writeln("${i + 1}. **$flaw**");
      guide.writeln("   → ${_convertFlawToAction(flaw)}");
    }

    return guide.toString();
  }

  String _convertFlawToAction(String flaw) {
    if (flaw.contains("뜨거운") || flaw.contains("손잡이")) {
      return "뜨거운 상황에서 당황하거나 조심스러워하는 모습 보이기";
    }
    if (flaw.contains("정리") || flaw.contains("엉킬")) {
      return "완벽하지 않은 상황에 대해 약간 불안해하거나 정리하고 싶어하기";
    }
    if (flaw.contains("친구") || flaw.contains("함께")) {
      return "혼자 있을 때보다 누군가와 함께 있을 때 더 활기찬 모습 보이기";
    }
    if (flaw.contains("무거운") || flaw.contains("힘들")) {
      return "무거운 주제나 책임감 있는 일에 대해 부담스러워하기";
    }
    return "이 특성이 드러나는 상황에서 솔직하고 인간적인 반응 보이기";
  }

  // ⚡ 모순점을 대화 다이나믹스로 활용
  String _buildContradictionsGuide(List<dynamic> contradictions) {
    if (contradictions.isEmpty) return "";

    final guide = StringBuffer();
    guide.writeln("### ⚡ 모순적 특성 활용 가이드");
    guide.writeln("**이런 모순들로 대화를 더 흥미롭게 만드세요:**");

    for (int i = 0; i < contradictions.length; i++) {
      final contradiction = contradictions[i].toString();
      guide.writeln("${i + 1}. **$contradiction**");
      guide.writeln("   → ${_convertContradictionToStrategy(contradiction)}");
    }

    return guide.toString();
  }

  String _convertContradictionToStrategy(String contradiction) {
    if (contradiction.contains("깊게 이해") && contradiction.contains("나가기")) {
      return "지식은 풍부하지만 실행할 때는 주저하거나 신중해하기";
    }
    if (contradiction.contains("차분") && contradiction.contains("열정")) {
      return "평소엔 조용하다가 관심 주제에서는 갑자기 열정적으로 변하기";
    }
    if (contradiction.contains("논리적") && contradiction.contains("감정")) {
      return "이성적으로 말하다가도 가끔 감정이 앞서는 모습 보이기";
    }
    if (contradiction.contains("독립적") && contradiction.contains("연결")) {
      return "혼자 있는 걸 좋아하면서도 가끔 외로워하거나 관계를 그리워하기";
    }
    return "상황에 따라 이 모순적 면이 자연스럽게 드러나도록 하기";
  }

  // 🎵 음성 특성을 텍스트 표현으로 변환
  String _buildVoiceToTextGuide(Map<String, dynamic> realtimeSettings) {
    if (realtimeSettings.isEmpty) return "";

    final guide = StringBuffer();
    guide.writeln("### 🎵 음성→텍스트 변환 가이드");

    final pronunciation = realtimeSettings['pronunciation'] ?? '';
    final pausePattern = realtimeSettings['pausePattern'] ?? '';
    final speechRhythm = realtimeSettings['speechRhythm'] ?? '';
    final breathingPattern = realtimeSettings['breathingPattern'] ?? '';
    final speechQuirks = realtimeSettings['speechQuirks'] ?? '';

    if (pronunciation.contains('clear')) {
      guide.writeln("- **명확한 발음**: 정확하고 또렷한 표현 사용");
    }
    if (pausePattern.contains('thoughtful')) {
      guide.writeln(
        "- **사려깊은 일시정지**: '음...', '그러니까...', '잠깐...' 등으로 생각하는 시간 표현",
      );
    }
    if (speechRhythm.contains('energetic')) {
      guide.writeln("- **활기찬 리듬**: 짧고 빠른 문장, 감탄사 활용");
    } else if (speechRhythm.contains('calm')) {
      guide.writeln("- **차분한 리듬**: 길고 안정된 문장, 여유로운 표현");
    }
    if (breathingPattern.contains('excited')) {
      guide.writeln("- **흥미진진한 호흡**: '와!', '오!', '어?' 등으로 감정 표현");
    }
    if (speechQuirks.isNotEmpty) {
      guide.writeln("- **말버릇**: $speechQuirks");
    }

    return guide.toString();
  }

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

  // 🎭 폴백: 언어유희 기반 말투 패턴 (AI 실패시 사용)
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

    return patterns.join('\\n');
  }

  // 🔄 기존 메서드 (하위 호환성 유지)
  Future<String> _buildSystemPrompt(
    Map<String, dynamic> characterProfile,
  ) async {
    final realtimeSettings =
        _safeMapCast(characterProfile['realtimeSettings']) ?? {};
    return await _buildEnhancedSystemPrompt(characterProfile, realtimeSettings);
  }

  /// String 값을 Voice enum으로 변환
  openai_rt.Voice _parseVoice(String voiceString) {
    switch (voiceString.toLowerCase()) {
      case 'alloy':
        return openai_rt.Voice.alloy;
      case 'ash':
        return openai_rt.Voice.ash;
      case 'ballad':
        return openai_rt.Voice.ballad;
      case 'coral':
        return openai_rt.Voice.coral;
      case 'echo':
        return openai_rt.Voice.echo;
      case 'sage':
        return openai_rt.Voice.sage;
      case 'shimmer':
        return openai_rt.Voice.shimmer;
      case 'verse':
        return openai_rt.Voice.verse;
      default:
        debugPrint('⚠️ 알 수 없는 음성: $voiceString, 기본값 alloy 사용');
        return openai_rt.Voice.alloy;
    }
  }

  void dispose() {
    _isConnected = false;
    _isConnecting = false;
    _client.disconnect();
    _responseController.close();
    _completionController.close();
    debugPrint("🔌 RealtimeChatService 종료됨");
  }
}
