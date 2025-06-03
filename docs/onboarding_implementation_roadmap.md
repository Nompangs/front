# 🛣️ NomPangS 온보딩 구현 로드맵 v2.2 (Figma 정확 반영)

> **Version**: 2.2  
> **Last Updated**: 2024-12-19  
> **Target**: Figma 디자인 정확 반영 6단계 완전한 온보딩 플로우  
> **핵심**: 로딩 화면, QR 생성, 캐릭터 완료 화면 포함

## 📋 현재 상황 분석 (Figma 정확 기준)

### ✅ **구현 완료 (2/6 단계)**
| 단계 | 화면 | Figma ID | 상태 | 완성도 |
|------|------|----------|------|--------|
| **1** | 온보딩 인트로 | `38:5961` | ✅ 완료 | 95% |
| **2** | 사물 정보 입력 | `38:6025` | ✅ 완료 | 90% |

### ❌ **신규 구현 필요 (4/6 단계 + 완료 화면)**
| 단계 | 화면 | Figma ID | 상태 | 우선순위 |
|------|------|----------|------|----------|
| **3** | 사물의 용도 입력 | `38:6207` | ❌ 신규 | 🔴 High |
| **4** | 사진 촬영 | `38:5998` | ❌ 신규 | 🔴 High |
| **5** | 캐릭터 생성 로딩 | `38:5818` | ❌ 신규 | 🟡 Medium |
| **6** | 성격 조정 | `38:5765` | ❌ 신규 | 🟡 Medium |
| **완료** | 캐릭터 생성 완료 | `38:5701` | ❌ 신규 | 🟡 Medium |

### 🔧 **기능별 구현 요구사항**
- **용도 입력**: 자유 텍스트 + 유머스타일 드롭다운
- **사진 촬영**: 카메라 권한 + 갤러리 선택 + 이미지 처리
- **캐릭터 생성 로딩**: 3단계 로딩 애니메이션 + 프로그레스 바
- **성격 조정**: 3가지 슬라이더 + 실시간 미리보기
- **캐릭터 완료**: QR 코드 생성 + 공유 기능

---

## 🎯 구현 전략 (Figma 정확 기준)

### **Phase 1: 기본 플로우 완성 (Week 1-2)**
기존 2단계 + 새로운 4단계 + 완료 화면

#### **Week 1: Core 화면 구현**
```
Day 1-2: Step 3 - 사물의 용도 입력 화면
- 자유 텍스트 입력 필드 (최대 300자)
- 유머스타일 드롭다운 (5가지 옵션)
- 실시간 말풍선 미리보기
- 입력 검증 및 다음 단계 연결

Day 3-4: Step 4 - 사진 촬영 화면  
- 카메라 권한 요청 처리
- 실시간 카메라 프리뷰
- 갤러리 이미지 선택 옵션
- 이미지 품질 검증
```

#### **Week 2: 고급 기능 구현**
```
Day 1-2: Step 5 - 캐릭터 생성 로딩 화면
- 3단계 순차 로딩 메시지
- 플로팅 버블 애니메이션 
- 프로그레스 바 (0% → 100%)
- AI 처리 시뮬레이션

Day 3-4: Step 6 - 성격 조정 화면
- 3가지 성격 슬라이더 (내외향성, 감정표현, 유능함)
- 실시간 캐릭터 변화 미리보기
- 순환 텍스트 애니메이션

Day 5: 완료 화면 - 캐릭터 생성 완료
- QR 코드 생성 기능
- 캐릭터 정보 요약 표시
- 첫 대화 말풍선
- 공유 및 저장 기능
```

### **Phase 2: AI 연동 및 통합 (Week 3)**
실제 AI 서비스 연동 및 최종 통합

#### **Week 3: AI Integration**
```
Day 1-2: AI 서비스 연동
- 멀티모달 AI API 연결
- 이미지 + 텍스트 분석 파이프라인
- 성격 생성 알고리즘 통합

Day 3-4: QR 코드 시스템
- 딥링크 URL 생성
- QR 이미지 생성 및 저장
- 공유 기능 구현

Day 5: 전체 플로우 통합 테스트
- 6단계 완전한 플로우 테스트
- 에러 핸들링 점검
- 성능 최적화
```

---

## 🔧 기술적 구현 세부사항

### **1. State Management 확장**
```dart
// models/onboarding_state.dart 확장
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    // 기존 필드 유지
    @Default('') String nickname,
    @Default('') String location,
    @Default('') String duration,
    @Default('') String objectType,
    
    // 새로운 필드 추가
    @Default('') String purpose,           // Step 3: 용도
    @Default('') String humorStyle,        // Step 3: 유머스타일
    String? photoPath,                     // Step 4: 사진 경로
    String? photoData,                     // Step 4: Base64 데이터
    
    // AI 생성 결과 (Step 5)
    PersonalityScore? aiGeneratedPersonality,
    @Default('') String characterGreeting,
    
    // 최종 성격 (Step 6)
    @Default(5) int introversion,          // 1-10
    @Default(5) int warmth,               // 1-10  
    @Default(5) int competence,           // 1-10
    
    // QR 코드 (완료)
    String? qrCodeUrl,
    String? qrImagePath,
    
    // 메타데이터
    @Default(OnboardingStep.intro) OnboardingStep currentStep,
    @Default(false) bool isLoading,
    String? error,
  }) = _OnboardingState;
}

// 6단계 enum 확장
enum OnboardingStep {
  intro,        // Step 1
  input,        // Step 2  
  purpose,      // Step 3 (신규)
  photo,        // Step 4 (신규)
  generation,   // Step 5 (신규)
  personality,  // Step 6 (신규)
  complete,     // 완료 (신규)
}
```

### **2. Provider 메소드 확장**
```dart
// providers/onboarding_provider.dart 확장
class OnboardingProvider extends ChangeNotifier {
  // 기존 메소드 유지
  
  // Step 3: 용도/유머 입력
  void updatePurpose(String purpose) {
    state = state.copyWith(purpose: purpose);
    notifyListeners();
  }
  
  void updateHumorStyle(String style) {
    state = state.copyWith(humorStyle: style);
    notifyListeners();
  }
  
  // Step 4: 사진 처리
  Future<void> capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        state = state.copyWith(photoPath: photo.path);
        await _processImage(photo.path);
      }
    } catch (e) {
      state = state.copyWith(error: '사진 촬영에 실패했습니다.');
    }
    notifyListeners();
  }
  
  // Step 5: 캐릭터 생성 시뮬레이션
  Future<void> generateCharacter() async {
    state = state.copyWith(
      isLoading: true,
      currentStep: OnboardingStep.generation,
    );
    notifyListeners();
    
    // 3단계 시뮬레이션
    await _simulateStage1(); // "캐릭터 깨우는 중..."
    await _simulateStage2(); // "개성을 찾고 있어요"
    await _simulateStage3(); // "마음을 열고 있어요"
    
    state = state.copyWith(
      isLoading: false,
      currentStep: OnboardingStep.personality,
      aiGeneratedPersonality: _generateMockPersonality(),
      characterGreeting: _generateMockGreeting(),
    );
    notifyListeners();
  }
  
  // Step 6: 성격 조정
  void updatePersonalitySlider(String type, int value) {
    switch (type) {
      case 'introversion':
        state = state.copyWith(introversion: value);
        break;
      case 'warmth':
        state = state.copyWith(warmth: value);
        break;
      case 'competence':
        state = state.copyWith(competence: value);
        break;
    }
    notifyListeners();
  }
  
  // 완료: QR 코드 생성
  Future<void> generateQRCode() async {
    try {
      final characterData = {
        'nickname': state.nickname,
        'personality': {
          'introversion': state.introversion,
          'warmth': state.warmth,
          'competence': state.competence,
        },
        'greeting': state.characterGreeting,
      };
      
      final deepLinkUrl = 'https://nompangs.app/chat/${_generateCharacterId()}';
      final qrImagePath = await _generateQRImage(deepLinkUrl);
      
      state = state.copyWith(
        qrCodeUrl: deepLinkUrl,
        qrImagePath: qrImagePath,
        currentStep: OnboardingStep.complete,
      );
    } catch (e) {
      state = state.copyWith(error: 'QR 코드 생성에 실패했습니다.');
    }
    notifyListeners();
  }
}
```

### **3. 새로운 화면 구현**

#### **Step 3: 용도 입력 화면**
```dart
// screens/onboarding_purpose_screen.dart
class OnboardingPurposeScreen extends StatefulWidget {
  @override
  State<OnboardingPurposeScreen> createState() => _OnboardingPurposeScreenState();
}

class _OnboardingPurposeScreenState extends State<OnboardingPurposeScreen> {
  final TextEditingController _purposeController = TextEditingController();
  String _selectedHumorStyle = '';
  
  final List<String> _humorStyles = [
    '따뜻한',
    '날카로운 관찰자적',
    '위트있는',
    '자기비하적',
    '(추가 옵션)',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OnboardingProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // 캐릭터 이름 표시
              Text('${provider.state.nickname} 라니..! 😂'),
              
              // 질문 타이틀
              Text('너에게 나는 어떤 존재야?'),
              
              // 캐릭터 말풍선 (실시간 업데이트)
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_purposeController.text.isEmpty 
                  ? '내가 운동 까먹지 않게 인정사정없이 채찍질해줘. 착하게 굴지마. 너는 조교야.'
                  : _purposeController.text
                ),
              ),
              
              // 용도 입력 (자유 텍스트)
              TextFormField(
                controller: _purposeController,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '구체적인 역할이나 상호작용 방식을 적어주세요',
                ),
                onChanged: (value) {
                  provider.updatePurpose(value);
                  setState(() {}); // 말풍선 업데이트
                },
              ),
              
              // 유머스타일 드롭다운
              DropdownButton<String>(
                value: _selectedHumorStyle.isEmpty ? null : _selectedHumorStyle,
                hint: Text('유머 스타일을 선택하세요'),
                items: _humorStyles.map((style) {
                  return DropdownMenuItem(
                    value: style,
                    child: Text(style),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedHumorStyle = value ?? '';
                  });
                  provider.updateHumorStyle(value ?? '');
                },
              ),
              
              Spacer(),
              
              // 다음 버튼
              PrimaryButton(
                text: '다음',
                onPressed: _canProceed() ? () {
                  Navigator.pushNamed(context, '/onboarding/photo');
                } : null,
              ),
            ],
          );
        },
      ),
    );
  }
  
  bool _canProceed() {
    return _purposeController.text.isNotEmpty && _selectedHumorStyle.isNotEmpty;
  }
}
```

#### **Step 5: 캐릭터 생성 로딩 화면**
```dart
// screens/onboarding_generation_screen.dart
class OnboardingGenerationScreen extends StatefulWidget {
  @override
  State<OnboardingGenerationScreen> createState() => _OnboardingGenerationScreenState();
}

class _OnboardingGenerationScreenState extends State<OnboardingGenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _progressController;
  
  int _currentStage = 1;
  final List<String> _stageMessages = [
    '캐릭터 깨우는 중...',
    '개성을 찾고 있어요',
    '마음을 열고 있어요',
  ];
  
  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: Duration(seconds: 15), // 총 15초
      vsync: this,
    );
    
    _startGeneration();
  }
  
  Future<void> _startGeneration() async {
    // Stage 1: 0-30%
    await Future.delayed(Duration(seconds: 5));
    setState(() => _currentStage = 2);
    
    // Stage 2: 30-70%
    await Future.delayed(Duration(seconds: 5));
    setState(() => _currentStage = 3);
    
    // Stage 3: 70-100%
    await Future.delayed(Duration(seconds: 5));
    
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding/personality',
        (route) => false,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 플로팅 버블 애니메이션
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bubbleController.value * 10),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 40),
            
            // 단계별 메시지
            Text(
              _stageMessages[_currentStage - 1],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            
            SizedBox(height: 40),
            
            // 프로그레스 바
            Container(
              width: 200,
              child: LinearProgressIndicator(
                value: (_currentStage / 3) * 0.8 + 0.2, // 20% ~ 100%
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 건너뛰기 버튼
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/onboarding/personality',
                  (route) => false,
                );
              },
              child: Text('건너뛰기'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _bubbleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
```

---

## 📊 구현 진행률 추적

### **Daily Progress Tracking**
| 날짜 | 목표 | 완료율 | 주요 작업 | 이슈 |
|------|------|--------|----------|------|
| Day 1 | Step 3 UI 완성 | 0% | 화면 레이아웃, 용도 입력 필드 | - |
| Day 2 | Step 3 로직 완성 | 0% | 유머스타일, 실시간 미리보기 | - |
| Day 3 | Step 4 카메라 기본 | 0% | 카메라 권한, 프리뷰 | - |
| Day 4 | Step 4 갤러리/처리 | 0% | 이미지 선택, 품질 검증 | - |
| Day 5 | Step 5 로딩 애니메이션 | 0% | 3단계 로딩, 프로그레스 | - |

### **주차별 Milestone**
```
Week 1 완료 기준:
✅ Step 3: 용도 입력 + 유머스타일 선택 완전 동작
✅ Step 4: 카메라 촬영 + 갤러리 선택 완전 동작

Week 2 완료 기준:  
✅ Step 5: 3단계 로딩 애니메이션 완전 동작
✅ Step 6: 성격 슬라이더 + 실시간 미리보기 완전 동작
✅ 완료: QR 코드 생성 + 공유 기능 완전 동작

Week 3 완료 기준:
✅ AI API 연동 + 실제 성격 생성
✅ QR 딥링크 시스템 구축
✅ 전체 6단계 플로우 완벽 동작
```

---

## 🎯 성공 지표 & KPI

### **기술적 성공 지표**
- **6단계 완주율**: > 80% (현재 목표)
- **단계별 이탈률**: < 5% (각 단계)
- **평균 완료 시간**: 3-4분 (Figma 기준)
- **QR 코드 생성 성공률**: > 95%
- **앱 크래시율**: < 1%

### **사용자 경험 지표**
- **직관성 점수**: > 4.0/5.0 (사용자 피드백)
- **재사용 의향**: > 70% (온보딩 재시도)
- **기능 이해도**: > 85% (QR 코드 용도 이해)

### **비즈니스 지표**
- **캐릭터 생성 완료율**: > 75%
- **첫 대화 시작률**: > 60% (완료 후 24시간 내)
- **QR 코드 활용률**: > 40% (물리적 부착)

---

## ⚠️ 리스크 & 대응 방안

### **High Risk: AI 서비스 의존성**
| 리스크 | 영향도 | 대응 방안 |
|--------|--------|----------|
| AI API 장애 | 높음 | 로컬 기본값 생성 + 에러 복구 |
| 응답 지연 | 중간 | 타임아웃 처리 + 건너뛰기 옵션 |
| 생성 품질 저하 | 중간 | 품질 검증 로직 + 재생성 옵션 |

### **Medium Risk: 플랫폼 의존성**
| 리스크 | 영향도 | 대응 방안 |
|--------|--------|----------|
| 카메라 권한 거부 | 중간 | 갤러리 대체 + 권한 가이드 |
| 저장소 권한 거부 | 낮음 | 임시 저장 + 권한 요청 |
| 구형 디바이스 성능 | 낮음 | 애니메이션 최적화 + fallback |

---

**🎯 Figma 디자인에 정확히 맞춘 6단계 완전한 온보딩 구현 로드맵입니다. 로딩 화면, QR 코드 생성, 캐릭터 완료 화면이 모두 포함된 현실적인 3주 계획입니다.** 