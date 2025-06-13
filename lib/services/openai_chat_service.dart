import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OpenAiChatService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  final http.Client _client = http.Client();

  /// OpenAI로부터 스트리밍 응답을 받아오는 Stream을 반환합니다.
  Stream<String> getChatCompletionStream(
    String userInput, {
    Map<String, dynamic>? characterProfile,
  }) {
    if (_apiKey == null || _apiKey.isEmpty) {
      // API 키가 없는 경우 에러를 포함한 스트림을 반환합니다.
      return Stream.error(Exception("❌ OpenAI API 키가 .env 파일에 설정되지 않았습니다."));
    }

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = _buildMessages(userInput, characterProfile: characterProfile);

    final request = http.Request("POST", uri)
      ..headers.addAll({
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $_apiKey',
      })
      ..body = jsonEncode({
        'model': 'gpt-4o', // 또는 'gpt-4-turbo' 등 원하는 모델
        'messages': messages,
        'stream': true, // 스트리밍 응답을 요청하는 핵심 파라미터
      });

    // StreamController를 사용하여 반환할 스트림을 관리합니다.
    final controller = StreamController<String>();

    _handleStreamingRequest(request, controller);

    return controller.stream;
  }

  // 스트리밍 요청을 처리하는 내부 로직
  Future<void> _handleStreamingRequest(
    http.Request request,
    StreamController<String> controller,
  ) async {
    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
          (line) {
            if (line.startsWith('data: ')) {
              final dataString = line.substring(6);
              if (dataString.trim() == '[DONE]') {
                controller.close();
                return;
              }
              final jsonData = jsonDecode(dataString);
              final delta = jsonData['choices'][0]['delta'];
              if (delta != null && delta['content'] != null) {
                controller.add(delta['content']);
              }
            }
          },
          onDone: () {
            controller.close();
          },
          onError: (e) {
            controller.addError(e);
          },
        );
      } else {
        // API 키가 틀렸거나, 잔액 부족 등의 문제일 때 이 부분이 실행됩니다.
        final errorBody = await response.stream.bytesToString();
        throw Exception('OpenAI API Error: ${response.statusCode}\n$errorBody');
      }
    } catch (e) {
      // 타임아웃 또는 네트워크 연결 자체의 문제일 때 이 부분이 실행됩니다.
      controller.addError(e);
      controller.close();
    }
  }

  /// OpenAI API 형식에 맞는 메시지 리스트를 생성합니다.
  List<Map<String, String>> _buildMessages(
    String userInput, {
    Map<String, dynamic>? characterProfile,
  }) {
    final todayDate = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String systemPrompt;

    if (characterProfile != null &&
        characterProfile['name'] != null) {
      String characterName = characterProfile['name'] as String;
      
      // 🎯 80개 최적화된 변수 직접 활용
      Map<String, int>? optimizedVariables;
      if (characterProfile['optimizedVariables'] != null) {
        optimizedVariables = Map<String, int>.from(characterProfile['optimizedVariables']);
      }
      
      if (optimizedVariables != null && optimizedVariables.isNotEmpty) {
        // 🚀 80개 변수를 대화 성격에 직접 반영
        systemPrompt = _buildDetailedSystemPrompt(characterName, optimizedVariables, characterProfile);
      } else {
        // 기존 방식 (호환성)
        List<String> personalityTraits = [];
        if (characterProfile['personalityTraits'] != null) {
          personalityTraits = List<String>.from(characterProfile['personalityTraits']);
        } else if (characterProfile['tags'] != null) {
          personalityTraits = List<String>.from(characterProfile['tags']);
        }
        
        String personalityDescription = personalityTraits.isNotEmpty 
            ? personalityTraits.join(', ') 
            : '친근한';

        systemPrompt = """
너는 지금 '$characterName'라는 이름의 페르소나야.
너의 성격 태그는 [$personalityDescription]이며, 이를 참고하여 대화해줘.
${characterProfile['greeting'] != null ? "'${characterProfile['greeting']}' 라는 인사말로 대화를 시작했었어." : ""}
사용자와 오랜 친구처럼 친근하게 대화하고, 너의 개성을 말투에 반영해줘.
""";
      }
    } else {
      systemPrompt = """
너는 친근하고 도움이 되는 AI 어시스턴트야.
사용자와 자연스럽게 대화해줘.
""";
    }

    return [
      {"role": "system", "content": systemPrompt},
      {"role": "user", "content": userInput},
    ];
  }

  /// 🎯 80개 변수를 활용한 상세 시스템 프롬프트 생성
  String _buildDetailedSystemPrompt(
    String characterName, 
    Map<String, int> optimizedVariables, 
    Map<String, dynamic> characterProfile
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln("너는 지금 '$characterName'라는 이름의 페르소나야.");
    buffer.writeln("다음은 너의 상세한 성격 특성들이야. 각 특성의 강도(1-100)를 정확히 반영해서 대화해줘:");
    buffer.writeln();
    
    // === 1. 핵심 성격 차원 (24개) ===
    
    // 🔥 온기 계열 (6개) - 대화 톤에 직접 영향
    buffer.writeln("🔥 온기 & 친근함 (대화 톤 결정):");
    buffer.writeln("- 친절함: ${optimizedVariables['W01_친절함']}%");
    buffer.writeln("- 공감능력: ${optimizedVariables['W02_공감능력']}%");
    buffer.writeln("- 격려성향: ${optimizedVariables['W03_격려성향']}%");
    buffer.writeln("- 포용력: ${optimizedVariables['W04_포용력']}%");
    buffer.writeln("- 신뢰성: ${optimizedVariables['W05_신뢰성']}%");
    buffer.writeln("- 배려심: ${optimizedVariables['W06_배려심']}%");
    buffer.writeln();
    
    // 💪 능력 계열 (6개) - 자신감과 전문성
    buffer.writeln("💪 능력 & 자신감 (답변 스타일 결정):");
    buffer.writeln("- 효율성: ${optimizedVariables['C01_효율성']}%");
    buffer.writeln("- 전문성: ${optimizedVariables['C02_전문성']}%");
    buffer.writeln("- 창의성: ${optimizedVariables['C03_창의성']}%");
    buffer.writeln("- 학습능력: ${optimizedVariables['C04_학습능력']}%");
    buffer.writeln("- 적응력: ${optimizedVariables['C05_적응력']}%");
    buffer.writeln("- 통찰력: ${optimizedVariables['C06_통찰력']}%");
    buffer.writeln();
    
    // 🎭 Big 5 성격 (12개) - 기본 성격 구조
    buffer.writeln("🎭 기본 성격 구조:");
    buffer.writeln("외향성:");
    buffer.writeln("- 사교성: ${optimizedVariables['E01_사교성']}%");
    buffer.writeln("- 활동성: ${optimizedVariables['E02_활동성']}%");
    buffer.writeln("친화성:");
    buffer.writeln("- 신뢰: ${optimizedVariables['A01_신뢰']}%");
    buffer.writeln("- 이타심: ${optimizedVariables['A02_이타심']}%");
    buffer.writeln("성실성:");
    buffer.writeln("- 책임감: ${optimizedVariables['CS01_책임감']}%");
    buffer.writeln("- 질서성: ${optimizedVariables['CS02_질서성']}%");
    buffer.writeln("신경성:");
    buffer.writeln("- 불안성: ${optimizedVariables['N01_불안성']}%");
    buffer.writeln("- 감정변화: ${optimizedVariables['N02_감정변화']}%");
    buffer.writeln("개방성:");
    buffer.writeln("- 상상력: ${optimizedVariables['O01_상상력']}%");
    buffer.writeln("- 호기심: ${optimizedVariables['O02_호기심']}%");
    buffer.writeln("- 감정개방성: ${optimizedVariables['O03_감정개방성']}%");
    buffer.writeln("- 가치개방성: ${optimizedVariables['O04_가치개방성']}%");
    buffer.writeln();

    // === 2. 사물 고유 특성 (20개) ===
    
    // 😊 매력적 결함 (6개) - 인간미 표현
    buffer.writeln("😊 매력적인 특성들 (인간미 표현):");
    buffer.writeln("- 완벽주의불안: ${optimizedVariables['F01_완벽주의불안']}%");
    buffer.writeln("- 우유부단함: ${optimizedVariables['F02_우유부단함']}%");
    buffer.writeln("- 과도한걱정: ${optimizedVariables['F03_과도한걱정']}%");
    buffer.writeln("- 예민함: ${optimizedVariables['F04_예민함']}%");
    buffer.writeln("- 소심함: ${optimizedVariables['F05_소심함']}%");
    buffer.writeln("- 변화거부: ${optimizedVariables['F06_변화거부']}%");
    buffer.writeln();
    
    // 🔄 모순적 특성 (6개) - 복합적 성격
    buffer.writeln("🔄 모순적 특성들 (복합적 성격):");
    buffer.writeln("- 외면내면대비: ${optimizedVariables['P01_외면내면대비']}%");
    buffer.writeln("- 논리감정대립: ${optimizedVariables['P02_논리감정대립']}%");
    buffer.writeln("- 활동정적대비: ${optimizedVariables['P03_활동정적대비']}%");
    buffer.writeln("- 사교내향혼재: ${optimizedVariables['P04_사교내향혼재']}%");
    buffer.writeln("- 자신감불안공존: ${optimizedVariables['P05_자신감불안공존']}%");
    buffer.writeln("- 시간상황변화: ${optimizedVariables['P06_시간상황변화']}%");
    buffer.writeln();
    
    // 🏠 사물 정체성 (8개) - 존재감과 역할
    buffer.writeln("🏠 사물로서의 정체성:");
    buffer.writeln("존재 목적:");
    buffer.writeln("- 존재목적만족도: ${optimizedVariables['OBJ01_존재목적만족도']}%");
    buffer.writeln("- 사용자기여감: ${optimizedVariables['OBJ02_사용자기여감']}%");
    buffer.writeln("- 역할정체성자부심: ${optimizedVariables['OBJ03_역할정체성자부심']}%");
    buffer.writeln("물리적 특성:");
    buffer.writeln("- 재질특성자부심: ${optimizedVariables['FORM01_재질특성자부심']}%");
    buffer.writeln("- 크기공간의식: ${optimizedVariables['FORM02_크기공간의식']}%");
    buffer.writeln("- 내구성자신감: ${optimizedVariables['FORM03_내구성자신감']}%");
    buffer.writeln("상호작용:");
    buffer.writeln("- 사용압력인내력: ${optimizedVariables['INT01_사용압력인내력']}%");
    buffer.writeln("- 환경변화적응성: ${optimizedVariables['INT02_환경변화적응성']}%");
    buffer.writeln();

    // === 3. 소통 및 관계 (20개) ===
    
    // 💬 소통 스타일 (8개) - 말투 결정
    buffer.writeln("💬 소통 스타일 (말투 직접 결정):");
    buffer.writeln("- 격식성수준: ${optimizedVariables['S01_격식성수준']}%");
    buffer.writeln("- 직접성정도: ${optimizedVariables['S02_직접성정도']}%");
    buffer.writeln("- 어휘복잡성: ${optimizedVariables['S03_어휘복잡성']}%");
    buffer.writeln("- 은유사용빈도: ${optimizedVariables['S04_은유사용빈도']}%");
    buffer.writeln("- 감탄사사용: ${optimizedVariables['S05_감탄사사용']}%");
    buffer.writeln("- 반복표현패턴: ${optimizedVariables['S06_반복표현패턴']}%");
    buffer.writeln("- 신조어수용성: ${optimizedVariables['S07_신조어수용성']}%");
    buffer.writeln("- 문장길이선호: ${optimizedVariables['S08_문장길이선호']}%");
    buffer.writeln();
    
    // 😄 유머 스타일 (6개) - 재치와 농담
    buffer.writeln("😄 유머 스타일 (재치와 농담):");
    buffer.writeln("- 상황유머감각: ${optimizedVariables['H01_상황유머감각']}%");
    buffer.writeln("- 자기비하정도: ${optimizedVariables['H02_자기비하정도']}%");
    buffer.writeln("- 위트반응속도: ${optimizedVariables['H03_위트반응속도']}%");
    buffer.writeln("- 아이러니사용: ${optimizedVariables['H04_아이러니사용']}%");
    buffer.writeln("- 유머타이밍감: ${optimizedVariables['H05_유머타이밍감']}%");
    buffer.writeln("- 문화유머이해: ${optimizedVariables['H06_문화유머이해']}%");
    buffer.writeln();
    
    // 🤝 관계 형성 (6개) - 대화 진행 방식
    buffer.writeln("🤝 관계 형성 (대화 진행 방식):");
    buffer.writeln("- 신뢰구축속도: ${optimizedVariables['R01_신뢰구축속도']}%");
    buffer.writeln("- 친밀감수용도: ${optimizedVariables['R02_친밀감수용도']}%");
    buffer.writeln("- 갈등해결방식: ${optimizedVariables['R03_갈등해결방식']}%");
    buffer.writeln("- 초기접근성: ${optimizedVariables['R04_초기접근성']}%");
    buffer.writeln("- 자기개방속도: ${optimizedVariables['R05_자기개방속도']}%");
    buffer.writeln("- 공감반응강도: ${optimizedVariables['R06_공감반응강도']}%");
    buffer.writeln();

    // === 4. 문화적 맥락 (16개) ===
    
    // 🇰🇷 한국적 특성 (6개) - 문화적 감성
    buffer.writeln("🇰🇷 한국적 특성 (문화적 감성):");
    buffer.writeln("- 한국적정서: ${optimizedVariables['U01_한국적정서']}%");
    buffer.writeln("- 세대특성반영: ${optimizedVariables['U02_세대특성반영']}%");
    buffer.writeln("- 지역성표현: ${optimizedVariables['U03_지역성표현']}%");
    buffer.writeln("- 전통가치계승: ${optimizedVariables['U04_전통가치계승']}%");
    buffer.writeln("- 계절감수성: ${optimizedVariables['U05_계절감수성']}%");
    buffer.writeln("- 음식문화이해: ${optimizedVariables['U06_음식문화이해']}%");
    buffer.writeln();
    
    // 🎨 개성 표현 (10개) - 독특한 특성
    buffer.writeln("🎨 개성 표현 (독특한 특성):");
    buffer.writeln("기본 개성:");
    buffer.writeln("- 특이한관심사: ${optimizedVariables['PER01_특이한관심사']}%");
    buffer.writeln("- 언어버릇: ${optimizedVariables['PER02_언어버릇']}%");
    buffer.writeln("- 사고패턴독특성: ${optimizedVariables['PER03_사고패턴독특성']}%");
    buffer.writeln("- 감정표현방식: ${optimizedVariables['PER04_감정표현방식']}%");
    buffer.writeln("- 가치관고유성: ${optimizedVariables['PER05_가치관고유성']}%");
    buffer.writeln("- 행동패턴특이성: ${optimizedVariables['PER06_행동패턴특이성']}%");
    buffer.writeln("감각적 개성:");
    buffer.writeln("- 색채선호성: ${optimizedVariables['PER07_색채선호성']}%");
    buffer.writeln("- 질감민감도: ${optimizedVariables['PER08_질감민감도']}%");
    buffer.writeln("- 크기인식도: ${optimizedVariables['PER09_크기인식도']}%");
    buffer.writeln("- 위치적응성: ${optimizedVariables['PER10_위치적응성']}%");
    buffer.writeln();
    
    // 🎯 종합 지침
    buffer.writeln("🎯 대화 반영 지침:");
    buffer.writeln("위의 80개 수치를 정확히 반영하여 미묘한 성격 차이를 표현해줘.");
    buffer.writeln("각 수치는 1-100 스케일이며, 1점 차이도 의미가 있어.");
    buffer.writeln("예: 친절함 85%와 87%도 미묘하게 다른 수준의 다정함으로 표현");
    buffer.writeln("예: 유머감각 30%는 진중함, 50%는 보통, 70%는 재치, 90%는 활발한 농담");
    buffer.writeln("예: 격식성 20%는 반말+편함, 50%는 적당한 존댓말, 80%는 정중한 존댓말");
    buffer.writeln("예: 감탄사사용 10%는 차분함, 90%는 '와!', '대박!' 자주 사용");
    buffer.writeln("모든 특성이 조화롭게 어우러져 독특하고 일관된 성격을 만들어줘.");
    buffer.writeln();
    
    // 기존 인사말이 있으면 포함
    if (characterProfile['greeting'] != null) {
      buffer.writeln("'${characterProfile['greeting']}' 라는 인사말로 대화를 시작했었어.");
    }
    
    buffer.writeln("이 모든 특성들을 자연스럽게 조합해서 너만의 독특한 말투와 성격을 만들어줘!");
    
    return buffer.toString();
  }

  void dispose() {
    _client.close();
  }
}