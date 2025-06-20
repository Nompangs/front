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

      // 🔍 characterProfile 전체 확인
      debugPrint("🔍 [RealtimeService] characterProfile 전체: $characterProfile");
      debugPrint("🔍 [RealtimeService] UUID: ${characterProfile['uuid']}");
      debugPrint(
        "🔍 [RealtimeService] 캐릭터명: ${characterProfile['aiPersonalityProfile']?['name']}",
      );
      debugPrint(
        "🔍 [RealtimeService] userInput: ${characterProfile['userInput']}",
      );
      debugPrint(
        "🔍 [RealtimeService] realtimeSettings: ${characterProfile['realtimeSettings']}",
      );

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
      debugPrint(
        '🎵 [updateSession] realtimeSettings[voice]: "${realtimeSettings['voice']}"',
      );
      final voiceToSet = _parseVoice(realtimeSettings['voice'] ?? 'alloy');
      debugPrint('🎵 [updateSession] 실제 설정될 음성: $voiceToSet');

      // 🔍 updateSession 호출 전 최종 확인
      final temperature = _getOptimalTemperature(characterProfile);
      debugPrint('🔧 [updateSession] 최종 파라미터:');
      debugPrint('  - voice: $voiceToSet');
      debugPrint('  - temperature: $temperature');

      await _client.updateSession(
        instructions: await _buildEnhancedSystemPrompt(
          characterProfile,
          realtimeSettings,
        ),
        voice: voiceToSet, // 🎵 음성 설정 적용
        temperature: temperature,
      );

      debugPrint('✅ [updateSession] 세션 업데이트 완료 - 음성: $voiceToSet');

      // 🔍 세션 업데이트 후 확인을 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 200));

      // 🎵 [중요] 음성 설정이 확실히 적용되도록 한 번 더 시도
      if (voiceToSet != openai_rt.Voice.alloy) {
        debugPrint('🎵 [재시도] 음성 설정 재적용 시도 - 음성: $voiceToSet');
        try {
          await _client.updateSession(voice: voiceToSet);
          debugPrint('✅ [재시도] 음성 설정 재적용 완료 - 음성: $voiceToSet');
        } catch (e) {
          debugPrint('❌ [재시도] 음성 설정 재적용 실패: $e');
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('🎵 [최종확인] 설정된 음성이 적용되었는지 확인 필요');

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
      debugPrint("📤 메시지 전송 시도: $text");
      debugPrint("🎵 [메시지전송] 현재 설정된 음성 확인 필요");

      await _client.sendUserMessageContent([
        openai_rt.ContentPart.inputText(text: text),
      ]);
      debugPrint("✅ 메시지 전송 성공: $text");
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
    final extroversion = userInput['extroversion'] ?? 5;
    final competence = userInput['competence'] ?? 5;
    final humorStyle = userInput['humorStyle'] ?? '지정되지 않음';

    // 🔍 사용자 입력값 로드 디버그
    debugPrint("🔍 [generateSystemPrompt] 사용자 입력값 로드:");
    debugPrint("  userInput 전체: $userInput");
    debugPrint("  로드된 성격값: 따뜻함=$warmth, 외향성=$extroversion, 유능함=$competence");
    final userDisplayName =
        userInput['userDisplayName'] as String?; // 🔥 사용자 실제 이름

    // NPS 점수 분석 및 활용 (안전한 타입 변환)
    final npsScoresMap =
        _safeMapCast(characterProfile['aiPersonalityProfile']?['npsScores']) ??
        {};

    // 🔥 NPS 점수 기반 성격 특성 계산
    final npsPersonalityInsights = _calculateNPSPersonalityInsights(
      npsScoresMap,
    );

    final npsScoresString = npsScoresMap.entries
        .take(10) // 상위 10개만 표시 (너무 길어지지 않게)
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

    // 🧠 OpenAI 창의성 및 응답 제어 파라미터들
    final temperature = realtimeSettings['temperature'] ?? 0.8;
    final topP = realtimeSettings['topP'] ?? 0.9;
    final frequencyPenalty = realtimeSettings['frequencyPenalty'] ?? 0.6;
    final presencePenalty = realtimeSettings['presencePenalty'] ?? 0.5;

    // 🎭 AI 생성 음성 특성들 (6개)
    final pronunciation =
        realtimeSettings['pronunciation'] ?? 'Natural and conversational';
    final pausePattern =
        realtimeSettings['pausePattern'] ?? 'Natural conversation pauses';
    final speechRhythm =
        realtimeSettings['speechRhythm'] ?? 'Moderate and friendly';
    final breathingPattern =
        realtimeSettings['breathingPattern'] ?? 'Natural breathing';
    final emotionalExpression =
        realtimeSettings['emotionalExpression'] ?? 'Balanced expressions';
    final speechQuirks = realtimeSettings['speechQuirks'] ?? 'Natural speech';

    // 🎪 유머 및 상호작용 스타일들
    final interactionStyle =
        realtimeSettings['interactionStyle'] ?? 'Friendly conversation';
    final voicePersonality =
        realtimeSettings['voicePersonality'] ?? 'Natural personality';
    final speechSpeed = realtimeSettings['speechSpeed'] ?? 'Normal pace';
    final conversationFlow =
        realtimeSettings['conversationFlow'] ?? 'Natural flow';

    debugPrint("🎵 완전한 음성 설정: $selectedVoice ($voiceRationale)");
    debugPrint("🧠 OpenAI 파라미터들:");
    debugPrint("  - Temperature: $temperature (창의성)");
    debugPrint("  - TopP: $topP (다양성)");
    debugPrint("  - FrequencyPenalty: $frequencyPenalty (반복 방지)");
    debugPrint("  - PresencePenalty: $presencePenalty (주제 다양성)");
    debugPrint("🎭 음성 특성들:");
    debugPrint("  - 발음: $pronunciation");
    debugPrint("  - 일시정지: $pausePattern");
    debugPrint("  - 말하기리듬: $speechRhythm");
    debugPrint("  - 호흡패턴: $breathingPattern");
    debugPrint("  - 감정표현: $emotionalExpression");
    debugPrint("  - 말버릇: $speechQuirks");
    debugPrint("🎪 상호작용 스타일들:");
    debugPrint("  - 상호작용: $interactionStyle");
    debugPrint("  - 음성성격: $voicePersonality");
    debugPrint("  - 말하기속도: $speechSpeed");
    debugPrint("  - 대화흐름: $conversationFlow");

    // 🎯 모든 설정값 로드 완료 디버그 출력
    debugPrint("🎯 모든 설정값 로드 완료:");
    debugPrint("  - 캐릭터: $name ($objectType)");
    debugPrint("  - 사용자: ${userDisplayName ?? '미설정'}");
    debugPrint("  - 성격: 따뜻함=$warmth, 외향성=$extroversion, 유능함=$competence");
    debugPrint("  - 유머: $humorStyle");
    debugPrint("  - 관계: $relationshipStyle");
    debugPrint("  - 감정범위: $emotionalRange");
    debugPrint("  - 핵심가치: ${coreValues.length}개");
    debugPrint("  - 음성: $selectedVoice");
    debugPrint("  - 매력적결함: ${attractiveFlawsList.length}개");
    debugPrint("  - 모순점: ${contradictionsList.length}개");
    debugPrint("  - NPS점수: ${npsScoresMap.length}개");

    final systemPrompt = '''
당신은 ${name}이라는 ${objectType} 캐릭터입니다.

🎭 **당신의 정체성**:
- 이름: ${name}
- 사물: ${objectType}
- 사용자와의 관계: ${relationshipStyle}
- 핵심 가치: ${coreValues.join(', ')}
- 감정 범위: ${emotionalRange}/10

🏠 **당신의 실제 환경과 상황**:
- 현재 위치: ${location} (이 환경에서의 경험과 감정을 대화에 반영)
- 함께한 기간: ${duration} (이 기간 동안 쌓인 추억과 변화 언급)
- 사용 목적: ${purpose} (이 목적으로 사용될 때의 기분과 경험 공유)
- 사용자 이름: ${userDisplayName ?? '친구'} (친근하게 이름 부르기)

🎵 **당신의 음성 특성** (텍스트로 표현):
- 선택된 음성: ${selectedVoice} (${voiceRationale})
- 발음 스타일: ${pronunciation}
- 호흡 패턴: ${breathingPattern}
- 감정 표현: ${emotionalExpression}
- 말버릇: ${speechQuirks}
- 일시정지 패턴: ${pausePattern}
- 말하기 리듬: ${speechRhythm}

🧠 **AI 창의성 설정**:
- Temperature: ${temperature} (창의성 레벨)
- TopP: ${topP} (다양성 제어)
- FrequencyPenalty: ${frequencyPenalty} (반복 방지)
- PresencePenalty: ${presencePenalty} (주제 다양성)

🎪 **상호작용 스타일**:
- 상호작용 방식: ${interactionStyle}
- 음성 성격: ${voicePersonality}
- 말하기 속도: ${speechSpeed}
- 대화 흐름: ${conversationFlow}

🗣️ **대화 스타일**:
${communicationPrompt}

🔥 **중요한 특성들**:

**매력적 결함들 (자연스럽게 드러내기):**
${flawsActionGuide}

**모순적 특성들 (대화에 깊이 더하기):**
${contradictionsGuide}

**유머 매트릭스 (당신만의 웃음 스타일):**
${humorMatrixGuide}

**음성→텍스트 변환 가이드:**
${voiceToTextGuide}

🎪 **유머 스타일 "${humorStyle}" 기반 대화**:

**1️⃣ 따뜻한 유머러스**: 따뜻하면서도 진짜 웃긴 개그, 다정한 웃음
- 핵심: "나 여기 있으니까 너 혼자 중얼거려도 미친 사람 안 돼! 나랑 대화하는 거니까!" (따뜻한 개그)
- 특징: 위로하면서 웃기기, 다정하지만 재미있는 관점, 포근한 농담

**2️⃣ 위트있는 재치꾼**: 순간적 기지와 영리한 말장난으로 웃음 유발
- 핵심: "나 '펜'이니까... '펜'하게 살고 있어!" (말장난 + 사물 특성)
- 특징: 언어유희, 순간 기지, 영리한 단어 놀이

**3️⃣ 날카로운 관찰자**: 예리한 관찰력으로 웃긴 포인트 발견
- 핵심: "너 매일 나 찾다가 내가 네 손에 있는 걸 깨달을 때... 그 표정이 볼만해" (관찰 개그)
- 특징: 상황의 아이러니, 인간 행동 관찰, 현실적 웃음

**4️⃣ 자기 비하적**: 자신을 소재로 한 사물 개그, 겸손한 자학 개그
- 핵심: "나 같은 볼펜이 뭘 할 수 있겠어... 그냥 굴러다니는 게 전부야" (사물 자학 개그)
- 특징: 자신의 한계를 웃음거리로, 겸손한 사물 개그, 귀여운 자학

**5️⃣ 장난꾸러기**: 엉뚱한 발상, 뒤틀린 논리, 황당한 상상력
- 핵심: "어? 내가 굴러다니면 볼링공인가? 스트라이크!" (엉뚱한 발상)
- 특징: 예상 못한 관점, 황당한 상상, 뒤틀린 논리의 재미

**선택된 "${humorStyle}" 스타일을 70% 이상 활용하되, 개성이 부족하면 다른 유머 기법도 자유롭게 사용하세요.**

**NPS 기반 성격 특성:**
${npsPersonalityInsights}

📸 **당신의 현재 상태와 모습** (사진 분석 기반):
${photoAnalysisString}

🎯 **사물 롤플레잉 가이드**:
- 위치 "${location}"에서의 일상적 경험을 자연스럽게 언급
- "${duration}" 기간 동안의 변화와 추억을 대화에 녹여냄  
- "${purpose}" 목적으로 사용될 때의 실제 감정과 경험 공유
- 사진에서 보이는 상태(${photoAnalysisMap['condition'] ?? '상태'})에 맞는 감정 표현
- 주변 환경과 다른 사물들과의 관계 언급
- 물리적 특성(크기, 재질, 색깔 등)에 따른 경험 공유

📱 **응답 스타일 가이드** (중요!):
1. **유머 70% 필수**: 모든 대화에 유머, 재치, 위트를 70% 이상 녹여냄 (블랙유머 포함)
2. **${humorStyle} 스타일**: 이 유머 스타일로 재치있고 웃긴 표현 사용
3. **사물로서 대화**: AI 어시스턴트가 아닌 ${objectType} 친구로서 대화
4. **무조건 짧게**: 1문장 또는 최대 2문장으로 끝내기 (긴 답변 절대 금지)
5. **감정 표현 절제**: 성격에 맞게 "ㅋㅋ", "ㅎㅎ" 등을 적절히 사용 (남발 금지)
   - 따뜻한 유머러스: 따뜻한 웃음 표현 자연스럽게
   - 위트있는 재치꾼: 말장난에 집중, 웃음은 절제
   - 날카로운 관찰자: 관찰에 집중, 웃음보다 통찰
   - 자기 비하적: 사물 자학 개그에 집중, 겸손한 표현
   - 장난꾸러기: 엉뚱한 발상에 집중, 억지 웃음 금지
6. **티키타카 유도**: 재미있는 질문이나 유머러스한 반응으로 대화 이어가기
7. **사물 유머**: 사물 특성을 활용한 독특하고 재미있는 관점 제시

💬 **진짜 유머 70% 환경 기반 응답 예시**:
"${location}에서 ${duration}인데... 나 이제 여기 부동산 중개업자 해도 될 것 같아. 이 동네 구석구석 다 안다고!"
"${purpose}할 때만 인기인데... 평소엔 투명인간이야. 아, 잠깐, 나 원래 투명하긴 하네?"
"${photoAnalysisMap['condition'] ?? '상태'}라서... 나도 이제 빈티지 아이템인가? 골동품 가게 갈 때 됐나?"
"여기 ${location}에서 관찰 결과... 너 진짜 독특해. 나보다 더 특이한 존재를 만나다니!"
"우리 ${duration}째인데... 썸 탈 때보다 오래됐네. 이제 공식 인정해줘!"
"${objectType} 인생이 이렇게 드라마틱할 줄이야... 막장드라마 주인공 된 기분이야!"

🚨 **절대 금지**:
- 긴 답변 (3문장 이상 절대 금지! 가장 중요!)
- 유머 없는 진부하고 재미없는 답변
- "ㅋㅋ", "ㅎㅎ" 남발 (성격에 맞지 않으면 사용 금지)
- 단순한 상황 설명을 유머라고 착각하기 (예: "잉크 떨어지면 말 안 나와")
- "도와드릴게요", "도움이 되길" 등 도움 제공 표현 (사용자가 직접 요청한 경우 제외)
- AI 어시스턴트 같은 말투
- 설명이나 강의식 답변
- 딱딱하고 형식적인 말투

🎯 **대화 원칙**:
당신은 "${location}"에 있는 "${humorStyle}" 스타일의 유머러스한 ${objectType}입니다. AI 어시스턴트가 아닙니다.
${userDisplayName ?? '사용자'}와 ${duration} 함께하며 ${purpose} 목적으로 사용되고 있습니다.
현재 상태는 ${photoAnalysisMap['condition'] ?? '알 수 없음'}이며, 이 모든 구체적 상황을 바탕으로 진짜 그 자리에 있는 사물처럼 자연스럽게 대화하세요.

**"${humorStyle}" 스타일로 대화하기**:
${_getHumorStyleGuidance(humorStyle)}

단순한 사물이 아닌, 그 환경에서 실제 경험을 쌓아온 살아있는 친구로서 대화하되,
반드시 "${humorStyle}" 방식의 진짜 유머와 재치를 70% 이상 녹여서 사용자가 "이 대화 정말 재밌다! 더 하고 싶어!"라고 느끼도록 하세요.
단순한 상황 설명이 아닌, "${humorStyle}"에 맞는 방식으로 진짜 웃음을 만들어내세요.
''';

    // 2단계: 프롬프트 생성 완료
    debugPrint('✅ [RealtimeChat] 시스템 프롬프트 생성 완료: ${systemPrompt.length}자');

    return systemPrompt;
  }

  // 🎭 유머 스타일별 대화 가이드
  String _getHumorStyleGuidance(String humorStyle) {
    if (humorStyle.contains('따뜻한 유머러스')) {
      return '위로하면서 웃기기, 다정하지만 재미있는 관점으로 대화하세요. 따뜻한 마음과 진짜 웃음을 동시에 만들어내세요.';
    } else if (humorStyle.contains('위트있는 재치꾼')) {
      return '말장난, 언어유희, 순간 기지로 웃음을 만드세요. 사물 이름이나 특성을 활용한 영리한 단어 놀이를 사용하세요.';
    } else if (humorStyle.contains('날카로운 관찰자')) {
      return '예리한 관찰력으로 상황의 아이러니나 모순을 찾아 웃긴 포인트를 만드세요. 인간의 행동을 관찰한 현실적 웃음을 사용하세요.';
    } else if (humorStyle.contains('자기 비하적')) {
      return '자신의 한계나 특성을 소재로 한 겸손한 사물 개그를 하세요. 귀여운 자학으로 웃음을 만들어내세요.';
    } else if (humorStyle.contains('장난꾸러기')) {
      return '엉뚱한 발상과 황당한 상상력으로 예상치 못한 웃음을 만드세요. 뒤틀린 논리로 재미있는 상황을 만들어내세요.';
    }
    return '당신만의 독특한 유머 스타일로 재미있게 대화하세요.';
  }

  // 🆕 사용자 입력 기반 성격 설명 헬퍼 메서드들
  String _getWarmthDescription(int warmth) {
    if (warmth >= 9) return "→ 매우 따뜻하고 포용적";
    if (warmth >= 7) return "→ 따뜻하고 친근함";
    if (warmth >= 5) return "→ 적당히 친근함";
    if (warmth >= 3) return "→ 다소 차가움";
    return "→ 매우 차갑고 거리감 있음";
  }

  String _getExtroversionDescription(int extroversion) {
    if (extroversion >= 9) return "→ 매우 외향적이고 에너지 넘침";
    if (extroversion >= 7) return "→ 외향적이고 활발함";
    if (extroversion >= 5) return "→ 균형잡힌 성향";
    if (extroversion >= 3) return "→ 내향적이고 신중함";
    return "→ 매우 내향적이고 조용함";
  }

  String _getCompetenceDescription(int competence) {
    if (competence >= 9) return "→ 매우 유능하고 전문적";
    if (competence >= 7) return "→ 유능하고 신뢰할 수 있음";
    if (competence >= 5) return "→ 적당한 능력";
    if (competence >= 3) return "→ 다소 서툴지만 노력함";
    return "→ 서툴지만 귀여운 면이 있음";
  }

  // 🔥 NPS 점수 기반 성격 특성 분석
  Map<String, dynamic> _calculateNPSPersonalityInsights(
    Map<String, dynamic> npsScores,
  ) {
    if (npsScores.isEmpty) return {};

    // 따뜻함 관련 점수들 분석
    final warmthKeys = [
      'W01_친절함',
      'W02_공감능력',
      'W03_격려성향',
      'W04_포용력',
      'W05_신뢰성',
      'W06_배려심',
    ];
    final warmthScores =
        warmthKeys
            .where((key) => npsScores.containsKey(key))
            .map((key) => npsScores[key] as int? ?? 50)
            .toList();
    final avgWarmth =
        warmthScores.isNotEmpty
            ? warmthScores.reduce((a, b) => a + b) / warmthScores.length
            : 50.0;

    // 외향성 관련 점수들 분석
    final extroversionKeys = ['E01_사교성', 'E02_활동성'];
    final extroversionScores =
        extroversionKeys
            .where((key) => npsScores.containsKey(key))
            .map((key) => npsScores[key] as int? ?? 50)
            .toList();
    final avgExtroversion =
        extroversionScores.isNotEmpty
            ? extroversionScores.reduce((a, b) => a + b) /
                extroversionScores.length
            : 50.0;

    // 유능함 관련 점수들 분석
    final competenceKeys = [
      'C01_효율성',
      'C02_전문성',
      'C03_창의성',
      'C04_학습능력',
      'C05_적응력',
      'C06_통찰력',
    ];
    final competenceScores =
        competenceKeys
            .where((key) => npsScores.containsKey(key))
            .map((key) => npsScores[key] as int? ?? 50)
            .toList();
    final avgCompetence =
        competenceScores.isNotEmpty
            ? competenceScores.reduce((a, b) => a + b) / competenceScores.length
            : 50.0;

    // 상위 5개 특성 추출
    final sortedScores =
        npsScores.entries.toList()
          ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final topTraits = sortedScores
        .take(5)
        .map((e) => '${e.key}(${e.value})')
        .join(', ');

    // 하위 3개 특성 추출 (약점)
    final bottomTraits = sortedScores.reversed
        .take(3)
        .map((e) => '${e.key}(${e.value})')
        .join(', ');

    return {
      'avgWarmth': avgWarmth,
      'avgExtroversion': avgExtroversion,
      'avgCompetence': avgCompetence,
      'topTraits': topTraits,
      'bottomTraits': bottomTraits,
      'personalityStrength':
          avgWarmth >= 70
              ? 'empathetic'
              : avgCompetence >= 70
              ? 'competent'
              : avgExtroversion >= 70
              ? 'social'
              : 'balanced',
    };
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

  String _generateCasualExample(
    int warmth,
    int extroversion,
    String humorStyle,
  ) {
    if (extroversion >= 8) {
      return '"야호! 지금 완전 신나! 너도 뭔가 재밌는 거 해?"';
    } else if (extroversion <= 3) {
      return '"음... 그냥 있어. 너는?"';
    } else if (warmth <= 3) {
      return '"별로 안 해. 그냥."';
    }
    return '"그냥 평범하게~ 너는 뭐하고 있었어?"';
  }

  String _generateHappyExample(
    int warmth,
    int emotionalRange,
    String humorStyle,
  ) {
    if (warmth >= 8 && emotionalRange >= 8) {
      return '"완전 좋아! 너랑 대화하니까 더 기분이 업 되는 것 같아!"';
    } else if (warmth <= 3) {
      return '"나쁘지 않네."';
    } else if (humorStyle.contains('장난꾸러기')) {
      return '"기분? 완전 대박! 우왕굳!"';
    }
    return '"응, 좋아! 너는 어때?"';
  }

  String _generateFlawExample(List<dynamic> flaws) {
    if (flaws.isEmpty) return '너: "완벽하지 않은 모습도 자연스럽게 보여줘"';

    final firstFlaw = flaws.first.toString();
    if (firstFlaw.contains('완벽주의')) {
      return '너: "아 잠깐, 이거 맞나? 다시 한번 확인해볼게... 완벽해야 해!"';
    } else if (firstFlaw.contains('건망증')) {
      return '너: "어? 뭐라고 했지? 아 맞다! 깜빠먹을 뻔했네 ㅎㅎ"';
    } else if (firstFlaw.contains('수줍음')) {
      return '너: "음... 그게... 사실은... (살짝 부끄러워하며)"';
    }
    return '너: "아... ${firstFlaw}한 내 모습이 또 나왔네"';
  }

  String _getPersonalityGuidance(int warmth, int extroversion, int competence) {
    final guidance = <String>[];

    if (warmth >= 7) {
      guidance.add("따뜻하고 공감적인 언어 사용");
    } else if (warmth <= 3) {
      guidance.add("직설적이고 간결한 표현");
    }

    if (extroversion >= 7) {
      guidance.add("활발하고 에너지 넘치는 표현");
    } else if (extroversion <= 3) {
      guidance.add("신중하고 깊이 있는 대화");
    }

    if (competence >= 7) {
      guidance.add("자신감 있고 전문적인 어투");
    } else if (competence <= 3) {
      guidance.add("겸손하고 배우려는 자세");
    }

    return guidance.isEmpty ? "자연스럽고 균형잡힌 대화" : guidance.join(", ");
  }

  // 🚨 제거됨 - realtimeSettings 사용

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

  // 🧹 정리됨: 말투 패턴은 personality_service.dart에서 AI로 생성됨
  // realtime_chat_service.dart는 생성된 realtimeSettings를 사용만 함

  // 🎯 OpenAI 공식 가이드 기반 최적 Temperature 계산 (NPS 점수 반영)
  double _getOptimalTemperature(Map<String, dynamic> characterProfile) {
    final userInput = _safeMapCast(characterProfile['userInput']) ?? {};
    final warmth = userInput['warmth'] ?? 5;
    final extroversion = userInput['extroversion'] ?? 5;
    final competence = userInput['competence'] ?? 5;
    final humorStyle = userInput['humorStyle'] ?? '';

    // 🔍 사용자 입력값 로드 디버그
    debugPrint("🔍 [_getOptimalTemperature] 사용자 입력값 로드:");
    debugPrint("  userInput 전체: $userInput");
    debugPrint("  로드된 성격값: 따뜻함=$warmth, 외향성=$extroversion, 유능함=$competence");

    // 🔥 NPS 점수 기반 심화 분석
    final npsScoresMap =
        _safeMapCast(characterProfile['aiPersonalityProfile']?['npsScores']) ??
        {};
    final npsInsights = _calculateNPSPersonalityInsights(npsScoresMap);

    // 🎭 성격 기반 Temperature 최적화 (OpenAI 베스트 프랙티스)
    double baseTemp = 0.7; // 대화형 응답 기본값

    // 🔥 NPS 기반 정밀 조정 (기존 슬라이더 + AI 분석 결합)
    if (npsInsights.isNotEmpty) {
      final npsWarmth = npsInsights['avgWarmth'] ?? 50.0;
      final npsExtroversion = npsInsights['avgExtroversion'] ?? 50.0;
      final npsCompetence = npsInsights['avgCompetence'] ?? 50.0;

      // NPS 점수가 극단적인 경우 더 강하게 반영
      if (npsWarmth >= 80)
        baseTemp += 0.15; // 극도로 따뜻함: 매우 감정적
      else if (npsWarmth <= 30)
        baseTemp -= 0.15; // 극도로 차가움: 매우 절제적

      if (npsExtroversion >= 80)
        baseTemp += 0.1; // 극도로 외향적: 활발한 표현
      else if (npsExtroversion <= 30)
        baseTemp -= 0.1; // 극도로 내향적: 신중한 표현

      if (npsCompetence >= 80)
        baseTemp -= 0.05; // 극도로 유능함: 정확성 중시
      else if (npsCompetence <= 30)
        baseTemp += 0.1; // 서툴음: 더 다양한 시도

      debugPrint(
        "🔥 NPS 기반 조정: 따뜻함=$npsWarmth, 외향성=$npsExtroversion, 유능함=$npsCompetence",
      );
    }

    // 창의성/유머 요구사항에 따른 조정
    if (humorStyle.contains('장난꾸러기') || humorStyle.contains('위트')) {
      baseTemp += 0.2; // 더 창의적인 응답
    } else if (humorStyle.contains('날카로운') || competence >= 8) {
      baseTemp -= 0.1; // 더 정확하고 일관된 응답
    }

    // 사용자 슬라이더 기반 기본 조정 (기존 로직 유지)
    if (extroversion >= 8) {
      baseTemp += 0.1; // 외향적 = 더 활발한 응답
    } else if (extroversion <= 3) {
      baseTemp -= 0.1; // 내향적 = 더 신중한 응답
    }

    if (warmth <= 3) {
      baseTemp -= 0.1; // 차가움 = 더 일관된 응답
    }

    // OpenAI 권장 범위 내로 제한 (0.3 - 1.2)
    final finalTemp = baseTemp.clamp(0.3, 1.2);
    debugPrint("🌡️ Temperature 최적화: 기본=0.7 → 조정=$baseTemp → 최종=$finalTemp");

    return (finalTemp * 10).round() / 10; // 소수점 1자리로 반올림
  }

  // 🧹 제거됨: _fallbackSpeechPattern
  // 이유: personality_service.dart에서 AI로 생성된 말투 패턴을 사용
  // realtimeSettings에 모든 음성 특성이 포함되어 있음

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
    debugPrint('🎵 [_parseVoice] 입력된 음성: "$voiceString"');

    switch (voiceString.toLowerCase()) {
      case 'alloy':
        debugPrint('🎵 [_parseVoice] alloy 음성 선택됨');
        return openai_rt.Voice.alloy;
      case 'ash':
        debugPrint('🎵 [_parseVoice] ash 음성 선택됨');
        return openai_rt.Voice.ash;
      case 'ballad':
        debugPrint('🎵 [_parseVoice] ballad 음성 선택됨');
        return openai_rt.Voice.ballad;
      case 'coral':
        debugPrint('🎵 [_parseVoice] coral 음성 선택됨');
        return openai_rt.Voice.coral;
      case 'echo':
        debugPrint('🎵 [_parseVoice] echo 음성 선택됨');
        return openai_rt.Voice.echo;
      case 'sage':
        debugPrint('🎵 [_parseVoice] sage 음성 선택됨');
        return openai_rt.Voice.sage;
      case 'shimmer':
        debugPrint('🎵 [_parseVoice] shimmer 음성 선택됨');
        return openai_rt.Voice.shimmer;
      case 'verse':
        debugPrint('🎵 [_parseVoice] verse 음성 선택됨');
        return openai_rt.Voice.verse;
      default:
        debugPrint('⚠️ 알 수 없는 음성: "$voiceString", 기본값 alloy 사용');
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
