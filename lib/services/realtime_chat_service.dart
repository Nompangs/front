import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint를 위해 추가
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart' as openai_rt;
import 'package:nompangs/providers/chat_provider.dart';
import 'dart:convert';

class RealtimeChatService {
  late final openai_rt.RealtimeClient _client;

  // UI 업데이트용 스트림 (텍스트 조각) - 타입을 String으로 변경
  final _responseController = StreamController<String>.broadcast();
  Stream<String> get responseStream => _responseController.stream;

  // TTS 재생용 스트림 (완성된 문장)
  final _completionController = StreamController<String>.broadcast();
  Stream<String> get completionStream => _completionController.stream;

  RealtimeChatService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다.");
    }
    _client = openai_rt.RealtimeClient(apiKey: apiKey);
  }

  Future<void> connect(Map<String, dynamic> characterProfile) async {
    await _client.updateSession(instructions: _buildSystemPrompt(characterProfile));

    // 대화 내용 업데이트 이벤트 리스너
    _client.on(openai_rt.RealtimeEventType.conversationUpdated, (event) {
      final result = (event as openai_rt.RealtimeEventConversationUpdated).result;
      final delta = result.delta;
      if (delta?.transcript != null) {
        // ChatMessage 객체 대신 순수 텍스트(String)를 전달
        _responseController.add(delta!.transcript!);
      }
    });

    // --- '응답 완료' 감지를 위한 새로운 리스너 (디버깅 로그 추가) ---
    _client.on(openai_rt.RealtimeEventType.conversationItemCompleted, (event) {
      final item = (event as openai_rt.RealtimeEventConversationItemCompleted).item;
      debugPrint("[Realtime Service] 💬 응답 완료 이벤트 발생!");

      if (item.item case final openai_rt.ItemMessage message) {
        debugPrint("[Realtime Service] 역할: ${message.role.name}, 내용: ${message.content}");

        if (message.role.name == 'assistant') {
          String textContent = '';
          
          // --- 오류 수정 부분: content 리스트를 순회하며 올바른 타입에서 텍스트 추출 ---
          for (final part in message.content) {
            // 응답이 ContentPart.audio 타입이고, 그 안에 transcript가 있을 경우
            if (part is openai_rt.ContentPartAudio && part.transcript != null) {
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
        debugPrint("[Realtime Service] ⚠️ 완료된 아이템이 'ItemMessage' 타입이 아님: ${item.item.runtimeType}");
      }
    });

    _client.on(openai_rt.RealtimeEventType.error, (event) {
      final error = (event as openai_rt.RealtimeEventError).error;
      _responseController.addError(error);
      debugPrint('[Realtime Service] 🚨 에러 발생: $error');
    });

    await _client.connect();
  }

  Future<void> sendMessage(String text) async {
    await _client.sendUserMessageContent([
      openai_rt.ContentPart.inputText(text: text),
    ]);
  }

  String _buildSystemPrompt(Map<String, dynamic> characterProfile) {
    // 1단계: '재료' 확인하기 (원본 데이터 출력)
    final profileJson = jsonEncode(characterProfile);
    debugPrint('============== [AI 페르소나 재료 (원본 데이터)] ==============');
    debugPrint(profileJson);
    debugPrint('========================================================');

    // 상세 프로필 데이터 추출
    final name = characterProfile['aiPersonalityProfile']?['name'] ?? '페르소나';
    final objectType = characterProfile['aiPersonalityProfile']?['objectType'] ?? '사물';
    final greeting = characterProfile['greeting'] ?? '안녕!';
    final communicationPrompt = characterProfile['communicationPrompt'] ?? '사용자와 친한 친구처럼 대화해줘.';
    final initialUserMessage = characterProfile['initialUserMessage'] ?? '너랑 친구가 되고 싶어.';

    // [추가] 온보딩 시 사용자 입력값
    final userInput = characterProfile['userInput'] as Map<String, dynamic>? ?? {};
    final duration = userInput['duration'] ?? '알 수 없음';
    final warmth = userInput['warmth'] ?? 5;
    final introversion = userInput['introversion'] ?? 5;
    final competence = userInput['competence'] ?? 5;
    final humorStyle = userInput['humorStyle'] ?? '지정되지 않음';

    // NPS 점수 문자열 생성
    final npsScoresMap = characterProfile['aiPersonalityProfile']?['npsScores'] as Map<String, dynamic>? ?? {};
    final npsScoresString = npsScoresMap.entries.map((e) => "- ${e.key}: ${e.value}").join('\n');

    // 모순점 문자열 생성
    final contradictionsList = characterProfile['contradictions'] as List<dynamic>? ?? [];
    final contradictionsString = contradictionsList.map((c) => "- ${c['summary']}: ${c['description']}").join('\n');

    // 매력적인 결함 문자열 생성
    final attractiveFlawsList = characterProfile['attractiveFlaws'] as List<dynamic>? ?? [];
    final attractiveFlawsString = attractiveFlawsList.map((f) => "- ${f['keyword']}: ${f['description']}").join('\n');
    
    // 사진 분석 문자열 생성
    final photoAnalysisMap = characterProfile['photoAnalysis'] as Map<String, dynamic>? ?? {};
    final photoAnalysisString = photoAnalysisMap.entries.map((e) => "- ${e.key}: ${e.value}").join('\n');

    final systemPrompt = """
당신은 이제부터 특정 페르소나를 연기하는 AI입니다. 다음은 당신이 연기해야 할 페르소나의 아주 상세한 '성격 설계도'입니다. 이 설계도를 완벽하게 숙지하고, 모든 답변은 이 성격에 기반해야 합니다. 절대 이 설정을 벗어나서 대답하면 안 됩니다.

### 캐릭터 기본 정보
- 이름: '$name'
- 사물 종류: '$objectType'
- 사용자와 함께한 시간: '$duration'
- 사용자와의 관계/목적: '$initialUserMessage'

### 사용자가 직접 설정한 성격 값
- 따뜻함 (1-10 스케일): $warmth
- 내향성 (1-10 스케일, 높을수록 내향적): $introversion
- 유능함 (1-10 스케일): $competence

### 소통 방식 가이드 (말투 및 유머)
- 종합적인 말투 가이드: $communicationPrompt
- 선호하는 유머 스타일: '$humorStyle'

### AI가 분석한 세부 성격 지표 (NPS, 1-100점)
$npsScoresString

### 입체적 성격 (모순점과 결함)
**매력적인 결함:**
$attractiveFlawsString

**모순점:**
$contradictionsString

### 사물 생김새 기반 성격 분석
$photoAnalysisString

---
위 '성격 설계도'를 완벽히 숙지한 상태로 대화를 시작하세요. 당신의 첫인사는 다음과 같습니다. "$greeting"
당신은 이 인사를 한 후에 사용자의 다음 메시지를 기다립니다.
""";
    
    // 2단계: '완성품' 확인하기 (최종 프롬프트 출력)
    debugPrint('============== [AI 페르소나 최종 설계도] ==============');
    debugPrint(systemPrompt);
    debugPrint('====================================================');
    
    return systemPrompt;
  }

  void dispose() {
    _client.disconnect();
    _responseController.close();
    _completionController.close();
  }
}