# 🎭 NomPangS 온보딩 플로우 재설계 v2.0

> **Based on**: Figma Design System + 놈팽쓰 프로젝트 계획서  
> **Version**: 2.0  
> **Last Updated**: 2024-12-19  
> **Concept**: "놈팽쓰와 첫 만남" - 애착 사물에 생명을 불어넣는 온보딩

## 📋 목차

1. [전체 플로우 개요](#-전체-플로우-개요)
2. [화면별 상세 설계](#-화면별-상세-설계)
3. [AI 페르소나 생성 시스템](#-ai-페르소나-생성-시스템)
4. [데이터 플로우 & API 연동](#-데이터-플로우--api-연동)
5. [구현 로드맵](#-구현-로드맵)

---

## 🎯 전체 플로우 개요

### **Core Concept: "놈팽쓰와 첫 만남"**
애착 사물의 정보와 사진을 바탕으로 AI 멀티모달 기술을 활용해 고유한 놈팽쓰 캐릭터를 생성하는 직관적인 경험

### **Extended User Flow**
```
앱 시작 → 온보딩 인트로 → 사물 정보 입력 → 사물 사진 촬영 → 
놈팽쓰 생성 과정 → 캐릭터 완성 → 첫 대화 → 홈 화면
```

### **플로우 시간 & 단계**
- **예상 완료 시간**: 4-5분 (생성 과정 포함)
- **최소 완료 시간**: 2분 (건너뛰기 사용)
- **총 화면 수**: 6개 화면 (기존 3개 → 확장)

---

## 📱 화면별 상세 설계

### **1. 온보딩 인트로 화면 (Enhanced)**
`/onboarding/intro` | `OnboardingIntroScreen`

#### **피그마 디자인 기반 개선점**
- 캐릭터 프리뷰 → **놈팽쓰 캐릭터 유형 미리보기**로 변경
- "기억을 소환하고 있어요.." → **"놈팽쓰를 깨우고 있어요.."**로 변경

#### **3가지 핵심 놈팽쓰 유형 프리뷰**
```dart
final List<Map<String, dynamic>> nompangsTypes = [
  {
    'name': '활발한 놈팽쓰',
    'description': '에너지 넘치는 대화와 긍정적인 반응',
    'traits': ['친근함', '유머', '활동성'],
    'color': 0xFFFF6B6B,
    'emoji': '😊'
  },
  {
    'name': '차분한 놈팽쓰', 
    'description': '깊이 있는 대화와 신중한 조언',
    'traits': ['지혜', '안정감', '신뢰'],
    'color': 0xFF4ECDC4,
    'emoji': '🤔'
  },
  {
    'name': '창의적 놈팽쓰',
    'description': '상상력 가득한 아이디어와 영감',
    'traits': ['창의력', '감성', '독창성'],
    'color': 0xFF95E1D3,
    'emoji': '✨'
  }
];
```

---

### **2. 사물 정보 입력 화면 (확장)**
`/onboarding/input` | `OnboardingInputScreen`

#### **기존 필드 유지 + 추가 필드**
| 기존 필드 | 추가 필드 | 목적 |
|----------|----------|------|
| 이름, 위치, 기간, 사물종류 | **사물의 역할** | 놈팽쓰 성격 특성 결정 |
| - | **특별한 기억** | 감정적 연결점 생성 |
| - | **원하는 성격** | 사용자 선호도 반영 |

#### **새로운 입력 필드**
```dart
// 추가 필드 1: 사물의 역할 (Dropdown)
final List<String> _roleOptions = [
  '일상 동반자',
  '작업 파트너', 
  '취미 조력자',
  '감정 지지자',
  '영감 제공자',
  '추억 보관자'
];

// 추가 필드 2: 특별한 기억 (TextArea, 선택사항)
// 힌트: "이 사물과 함께한 특별한 순간이 있다면 알려주세요"

// 추가 필드 3: 원하는 성격 (3개 선택)
final List<String> _personalityOptions = [
  '유머러스한', '진지한', '활발한', '차분한', 
  '따뜻한', '냉정한', '창의적인', '현실적인',
  '호기심 많은', '신중한', '낙관적인', '분석적인'
];
```

---

### **3. 사물 사진 촬영 화면 (신규)**
`/onboarding/photo` | `OnboardingPhotoScreen`

#### **화면 목적**
- 멀티모달 AI(Gemini/OpenAI Vision) 연동
- 물리적 특성 분석으로 놈팽쓰 성격 생성
- 사용자 참여도 및 몰입감 증대

#### **UI 구성요소**
| 요소 | 스펙 | 기능 |
|------|------|------|
| **카메라 뷰** | 전체 화면 | 실시간 카메라 프리뷰 |
| **가이드 오버레이** | 반투명 프레임 | 촬영 위치 안내 |
| **촬영 버튼** | 하단 중앙, 놈팽쓰 색상 | 사진 촬영 |
| **갤러리 선택** | 좌하단 | 기존 사진 선택 |
| **재촬영 버튼** | 우하단 | 다시 촬영 |

#### **촬영 가이드라인**
```dart
final List<String> _photoTips = [
  "사물을 화면 중앙에 배치해주세요",
  "밝은 곳에서 촬영하면 더 정확해요", 
  "사물의 전체 모습이 보이도록 해주세요",
  "손이나 그림자가 가리지 않게 해주세요"
];
```

---

### **4. 놈팽쓰 생성 과정 화면 (신규)**
`/onboarding/generation` | `OnboardingGenerationScreen`

#### **화면 목적**
- AI 놈팽쓰 생성 과정의 시각적 표현
- 사용자 대기 시간의 엔터테인먼트 제공
- 3가지 핵심 지표로 직관적 표시

#### **3단계 생성 과정**
```dart
class NompangsGenerationView extends StatefulWidget {
  final Map<String, dynamic> inputData;
  final String imagePath;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1단계: 사물 분석 (0-40%)
        AnimatedAnalysisStep(
          title: "사물을 살펴보고 있어요",
          description: "사진 속 사물의 특성을 파악하고 있어요",
          icon: Icons.image_search,
          duration: Duration(seconds: 10)
        ),
        
        // 2단계: 놈팽쓰 성격 결정 (40-80%)
        AnimatedPersonalityGeneration(
          title: "놈팽쓰 성격을 만들고 있어요", 
          description: "입력하신 정보를 바탕으로 고유한 성격을 생성해요",
          duration: Duration(seconds: 12)
        ),
        
        // 3단계: 캐릭터 완성 (80-100%)
        AnimatedCharacterCompletion(
          title: "놈팽쓰가 깨어났어요!",
          description: "당신만의 특별한 놈팽쓰가 탄생했어요",
          duration: Duration(seconds: 3)
        )
      ]
    );
  }
}
```

#### **3가지 핵심 성격 지표 표시**
| 지표 | 범위 | 설명 | 시각적 표현 |
|------|------|------|------------|
| **친근함** | 1-10 | 대화 스타일의 친밀도 | 하트 게이지 |
| **활발함** | 1-10 | 에너지와 반응성 정도 | 번개 게이지 |
| **깊이감** | 1-10 | 사고의 깊이와 통찰력 | 책 게이지 |

#### **진행 단계 상세**
| 단계 | 진행률 | 소요 시간 | API 호출 | 화면 표시 |
|------|--------|----------|----------|----------|
| **사물 분석** | 0-40% | 10초 | Gemini/OpenAI Vision | 사물 이미지 분석 애니메이션 |
| **성격 생성** | 40-80% | 12초 | Gemini/GPT-4 | 3가지 지표 생성 과정 |
| **캐릭터 완성** | 80-100% | 3초 | 프로필 이미지 생성 | 완성 효과 + 지표 표시 |

---

### **5. 놈팽쓰 캐릭터 완성 화면 (신규)**
`/onboarding/character` | `OnboardingCharacterScreen`

#### **화면 목적**
- 생성된 놈팽쓰 캐릭터 소개
- 3가지 핵심 지표와 특성 표시
- 첫 대화로의 자연스러운 전환

#### **UI 구성요소**
```dart
class CharacterCompletionView extends StatelessWidget {
  final NompangsCharacter character;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 캐릭터 아바타
        CircleAvatar(
          radius: 80,
          backgroundImage: NetworkImage(character.avatarUrl),
        ),
        
        // 캐릭터 이름 & 한줄 소개
        Text(character.name, style: Theme.of(context).textTheme.headlineMedium),
        Text(character.description, style: Theme.of(context).textTheme.bodyLarge),
        
        // 3가지 핵심 지표
        PersonalityIndicators(
          friendliness: character.friendliness,
          energy: character.energy,
          depth: character.depth,
        ),
        
        // 핵심 특성 태그
        Wrap(
          children: character.traits.map((trait) => 
            Chip(label: Text(trait))
          ).toList(),
        ),
        
        // 첫 인사말
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            character.greeting,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        
        // 대화 시작 버튼
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/onboarding/chat'),
          child: Text('놈팽쓰와 대화하기'),
        ),
      ],
    );
  }
}
```

#### **캐릭터 데이터 구조**
```dart
class NompangsCharacter {
  final String id;
  final String name;
  final String description;
  final String avatarUrl;
  final String greeting;
  final int friendliness;  // 1-10
  final int energy;        // 1-10  
  final int depth;         // 1-10
  final List<String> traits;
  final String systemPrompt; // 백엔드 전용
  
  // 백엔드에서만 사용되는 상세 변수들 (프론트엔드 표시 안함)
  final Map<String, dynamic> detailedPersonality;
}
```

---

### **6. 첫 대화 체험 화면 (신규)**
`/onboarding/chat` | `OnboardingChatScreen`

#### **화면 목적**
- 생성된 놈팽쓰와의 첫 대화 경험
- STT-LLM-TTS 파이프라인 체험
- 온보딩 완료 후 홈으로 이동

#### **UI 구성요소**
```dart
class FirstChatView extends StatefulWidget {
  final NompangsCharacter character;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 채팅 헤더 (캐릭터 정보)
        ChatHeader(character: character),
        
        // 대화 영역
        Expanded(
          child: ChatMessageList(
            messages: [
              ChatMessage(
                text: character.greeting,
                isUser: false,
                timestamp: DateTime.now(),
              ),
            ],
          ),
        ),
        
        // 음성/텍스트 입력 영역
        ChatInputArea(
          onTextMessage: _sendTextMessage,
          onVoiceMessage: _sendVoiceMessage,
          isListening: _isListening,
        ),
        
        // 온보딩 완료 버튼 (3-4개 대화 후 표시)
        if (_messageCount >= 3)
          ElevatedButton(
            onPressed: _completeOnboarding,
            child: Text('놈팽쓰와 함께 시작하기'),
          ),
      ],
    );
  }
}
```

#### **첫 대화 시나리오**
| 순서 | 놈팽쓰 메시지 | 사용자 예상 반응 | 목적 |
|------|-------------|----------------|------|
| **1** | 개인화된 첫 인사 | 반갑다는 인사 | 관계 형성 |
| **2** | 사물과 관련된 질문 | 사물에 대한 이야기 | 맥락 확인 |
| **3** | 앞으로의 계획 제안 | 긍정적 반응 | 사용법 안내 |

---

## 🤖 AI 페르소나 생성 시스템

### **멀티모달 AI 활용**
```
입력 데이터:
- 텍스트: 사물 정보 (이름, 위치, 기간, 종류, 역할, 기억, 원하는 성격)
- 이미지: 사물 사진 (멀티모달 분석)

처리 과정:
1. Vision API (Gemini/OpenAI) → 사물 시각적 특성 분석
2. Language Model → 텍스트 정보와 시각 정보 결합
3. 놈팽쓰 성격 시스템 → 3가지 핵심 지표 + 상세 변수(백엔드)
```

### **3가지 핵심 지표 시스템**
```dart
class PersonalityMetrics {
  // 사용자에게 표시되는 직관적 지표
  final int friendliness;  // 친근함 (1-10)
  final int energy;        // 활발함 (1-10)
  final int depth;         // 깊이감 (1-10)
  
  // 백엔드에서만 사용되는 상세 변수들
  final Map<String, dynamic> detailedTraits; // 수십 개 세부 변수
}
```

### **API 연동 구조**
```dart
class PersonalityGenerator {
  // 1단계: 이미지 분석
  Future<Map<String, dynamic>> analyzeObjectImage(String imagePath) async {
    // Gemini Vision API 또는 OpenAI Vision API 호출
    return await visionAPI.analyze(imagePath);
  }
  
  // 2단계: 텍스트+이미지 기반 성격 생성
  Future<NompangsCharacter> generatePersonality({
    required Map<String, dynamic> inputData,
    required Map<String, dynamic> imageAnalysis,
  }) async {
    // 통합 프롬프트로 놈팽쓰 캐릭터 생성
    return await llmAPI.generateCharacter(inputData, imageAnalysis);
  }
}
```

### **오프라인 대응 전략**
- **이미지 분석 실패**: 텍스트 정보만으로 생성
- **API 지연**: 기본 템플릿 기반 임시 캐릭터 제공
- **완전 오프라인**: 로컬 규칙 기반 성격 생성

---

## 📊 데이터 플로우 & API 연동

### **데이터 수집 & 전송**
```dart
class OnboardingData {
  // 기존 필드
  final String nickname;
  final String location; 
  final String duration;
  final String objectType;
  
  // 확장 필드
  final String role;
  final String? specialMemory;
  final List<String> desiredTraits;
  final String imagePath;
  
  // 생성 결과
  final NompangsCharacter? character;
}
```

### **API 호출 시퀀스**
```
1. 사진 업로드 → 이미지 분석 API
2. 전체 데이터 → 성격 생성 API  
3. 프로필 이미지 → 아바타 생성 API
4. 캐릭터 저장 → 백엔드 데이터베이스
5. 첫 대화 → 실시간 채팅 API
```

### **성능 최적화**
- **병렬 처리**: 이미지 업로드와 분석 동시 진행
- **캐싱**: 생성된 캐릭터 로컬 저장
- **점진적 로딩**: 기본 정보 먼저, 상세 정보 나중

---

## 🗓️ 구현 로드맵

### **Week 1-2: 기반 구조**
- [ ] 확장된 데이터 모델 구현
- [ ] 새로운 라우팅 구조 설정
- [ ] 기존 화면 개선 (인트로, 입력)

### **Week 3-4: 신규 화면**
- [ ] 사진 촬영 화면 개발
- [ ] 카메라/갤러리 연동
- [ ] 이미지 품질 검증 로직

### **Week 5-6: AI 연동**
- [ ] 멀티모달 API 연동 (Gemini/OpenAI)
- [ ] 놈팽쓰 생성 로직 구현
- [ ] 3가지 지표 시스템 개발

### **Week 7-8: 완성 & 최적화**
- [ ] 캐릭터 완성 화면 개발
- [ ] 첫 대화 체험 구현
- [ ] 성능 최적화 & 오류 처리

### **주요 KPI**
- **온보딩 완료율**: 85% 이상
- **첫 대화 참여율**: 90% 이상  
- **놈팽쓰 생성 성공률**: 95% 이상
- **평균 온보딩 시간**: 4-5분

---

## 🎯 성공 지표

### **사용자 경험 지표**
- 온보딩 단계별 이탈률 < 15%
- 사용자 만족도 (5점 만점) > 4.2점
- 놈팽쓰 캐릭터 만족도 > 4.0점

### **기술적 지표** 
- API 응답 시간 < 3초
- 이미지 분석 정확도 > 90%
- 시스템 안정성 > 99%

### **비즈니스 지표**
- 온보딩 후 첫 대화 시작률 > 80%
- 7일 리텐션 > 60%
- 놈팽쓰 재생성 요청률 < 10%

---

**🎉 결론**: 피그마 디자인을 기반으로 한 직관적이고 몰입감 있는 놈팽쓰 온보딩 경험을 통해 사용자들이 자연스럽게 AI 컴패니언과의 관계를 시작할 수 있도록 지원합니다. 