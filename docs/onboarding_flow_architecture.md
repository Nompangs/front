# 놈팽쓰(NomPangS) 온보딩 플로우 및 아키텍처 설계 문서

## 📋 문서 개요

본 문서는 놈팽쓰 Flutter 앱의 온보딩 플로우와 전체 아키텍처를 정의합니다.
Figma 디자인 분석을 바탕으로 체계적인 구조와 구현 방향성을 제시합니다.

---

## 🔄 온보딩 플로우 정의

### 📱 전체 플로우 다이어그램

```
앱 시작 → 온보딩 인트로 → 사물 정보 입력 → 캐릭터 생성 → 완료
   ↓           ↓              ↓              ↓         ↓
 권한체크    사물소개     →  위치/기간/이름   →  로딩    →  QR생성
   ↓           ↓              ↓              ↓         ↓
건너뛰기   사물이미지선택  → 입력값 검증    → AI생성   → 대화시작
```

### 🎯 화면별 상세 정의

#### 1단계: 온보딩 인트로 (`OnboardingIntroScreen`)
**Figma 노드**: `14:3266 - 온보딩 - 인트로`

```dart
// 화면 구성 요소
- StatusBar (시스템 상태바)
- AppBar
  ├── BackButton (이전 버튼)
  ├── Title ("성격 조제 연금술!")
  └── SkipButton ("건너뛰기")
- MainContent
  ├── CharacterImages (3개 캐릭터 이미지)
  ├── MainText ("지금부터 당신의\n애착 사물을 깨워볼께요.")
  └── LoadingText ("기억을 소환하고 있어요..")
- FooterButton ("캐릭터 깨우기" → "다음")
- HomeIndicator
```

**핵심 기능**:
- 서비스 소개 및 컨셉 전달
- 사용자 기대감 조성
- 건너뛰기 옵션 제공

#### 2단계: 사물 정보 입력 (`OnboardingInputScreen`)
**Figma 노드**: `14:3218`, `14:3303`, `14:3361 - 온보딩 - 사물 정보 입력`

```dart
// 화면 구성 요소 (다단계 진행)
- AppBar (동일)
- MainTitle ("말해줘!\n나는 어떤 사물이야?")
- InputSection
  ├── NicknameInput ("애칭" + "털찐 말랑이")
  ├── LocationSelector ("우리집 거실" + "에서")
  ├── DurationSelector ("3개월" + "정도 함께한")  
  └── ObjectTypeSelector ("이 빠진 머그컵" + "(이)에요.")
- ValidationMessage ("이름을 입력해주세요!" - 빨간색)
- LocationDropdown (내 방, 우리집 안방, 사무실, 단골 카페)
- FooterButton ("다음")
```

**핵심 기능**:
- 사물과의 관계 정보 수집
- 위치, 기간, 특징 입력
- 실시간 입력 검증
- 드롭다운 선택 UI

#### 3단계: 캐릭터 생성 과정 (`CharacterCreationScreen`)
**관련 Figma**: 로딩 및 생성 화면

```dart
// 화면 구성 요소
- AppBar (동일)
- LoadingAnimation (AI 생성 중)
- ProgressIndicator
- GenerationStatus ("캐릭터를 생성하고 있어요...")
- PreviewSection (실시간 생성 미리보기)
```

**핵심 기능**:
- AI 기반 캐릭터 생성
- 로딩 상태 표시
- 생성 과정 시각화

#### 4단계: 캐릭터 생성 완료 (`CharacterCompletionScreen`)
**Figma 노드**: `1:2282`, `14:2852` - 캐릭터 생성 완료

```dart
// 화면 구성 요소
- StatusBar
- NotificationBanner ("{사물}이 깨어났어요!" - 초록색, floating)
- QRSection
  ├── QRCode (생성된 고유 QR)
  ├── Description ("QR을 붙이면 언제 어디서든 대화할 수 있어요!")
  └── ActionButtons (저장하기, 공유하기)
- CharacterCard
  ├── CharacterImage (AI 생성 캐릭터)
  ├── CharacterInfo
  │   ├── Name ("{털찐 말랑이}")
  │   ├── Role ("{멘탈지기}")
  │   ├── Age ("{25}년생")
  │   └── Location ("{우리집 거실}")
  ├── PersonalityTags ("#심신미약 #소심이")
  └── SpeechBubble ("가끔 털이 엉킬까봐 걱정돼 :(")
- VoicePlayButton (🔊 사운드 아이콘)
- FooterActions
  ├── PrimaryButton ("지금 바로 대화해요")
  └── SecondaryButtons ("성격 바꾸기" | "대화하기")
```

**핵심 기능**:
- 생성 완료 알림 (floating 애니메이션)
- QR 코드 생성 및 공유
- 캐릭터 정보 표시
- 첫 인사말 TTS 재생
- 대화 시작 또는 성격 조정

---

## 🏗️ 디렉토리 구조 설계

### 📁 전체 프로젝트 구조

```
front/
├── lib/
│   ├── main.dart                          # 앱 진입점
│   ├── app.dart                          # 앱 설정 및 라우팅
│   │
│   ├── core/                             # 핵심 시스템
│   │   ├── constants/                    # 상수 정의
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   ├── app_dimensions.dart
│   │   │   └── app_strings.dart
│   │   ├── theme/                        # Material 3 테마
│   │   │   ├── app_theme.dart
│   │   │   ├── color_scheme.dart
│   │   │   └── text_theme.dart
│   │   ├── utils/                        # 유틸리티
│   │   │   ├── logger.dart
│   │   │   ├── validators.dart
│   │   │   └── extensions.dart
│   │   └── errors/                       # 에러 처리
│   │       ├── exceptions.dart
│   │       └── error_handler.dart
│   │
│   ├── features/                         # 기능별 모듈
│   │   ├── onboarding/                   # 온보딩 모듈
│   │   │   ├── data/                     # 데이터 레이어
│   │   │   │   ├── models/
│   │   │   │   │   ├── onboarding_data.dart
│   │   │   │   │   └── character_data.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── onboarding_repository.dart
│   │   │   │   └── services/
│   │   │   │       └── character_generation_service.dart
│   │   │   ├── domain/                   # 비즈니스 로직
│   │   │   │   ├── entities/
│   │   │   │   │   ├── character.dart
│   │   │   │   │   └── user_input.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── onboarding_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── validate_user_input.dart
│   │   │   │       └── generate_character.dart
│   │   │   └── presentation/             # UI 레이어
│   │   │       ├── screens/
│   │   │       │   ├── onboarding_intro_screen.dart
│   │   │       │   ├── onboarding_input_screen.dart
│   │   │       │   ├── character_creation_screen.dart
│   │   │       │   └── character_completion_screen.dart
│   │   │       ├── widgets/
│   │   │       │   ├── intro/
│   │   │       │   │   ├── character_preview_widget.dart
│   │   │       │   │   └── loading_text_widget.dart
│   │   │       │   ├── input/
│   │   │       │   │   ├── nickname_input_widget.dart
│   │   │       │   │   ├── location_selector_widget.dart
│   │   │       │   │   ├── duration_selector_widget.dart
│   │   │       │   │   └── object_type_selector_widget.dart
│   │   │       │   ├── creation/
│   │   │       │   │   ├── loading_animation_widget.dart
│   │   │       │   │   └── progress_indicator_widget.dart
│   │   │       │   └── completion/
│   │   │       │       ├── notification_banner_widget.dart
│   │   │       │       ├── qr_section_widget.dart
│   │   │       │       ├── character_card_widget.dart
│   │   │       │       └── voice_play_button_widget.dart
│   │   │       ├── providers/
│   │   │       │   ├── onboarding_provider.dart
│   │   │       │   └── character_generation_provider.dart
│   │   │       └── routes/
│   │   │           └── onboarding_routes.dart
│   │   │
│   │   ├── authentication/               # 인증 모듈
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── character/                    # 캐릭터 관리 모듈
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── chat/                         # 채팅 모듈
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── profile/                      # 프로필 모듈
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── shared/                           # 공통 컴포넌트
│   │   ├── widgets/                      # 재사용 위젯
│   │   │   ├── buttons/
│   │   │   │   ├── primary_button.dart
│   │   │   │   ├── secondary_button.dart
│   │   │   │   └── floating_action_button.dart
│   │   │   ├── inputs/
│   │   │   │   ├── custom_text_field.dart
│   │   │   │   ├── dropdown_selector.dart
│   │   │   │   └── slider_input.dart
│   │   │   ├── layouts/
│   │   │   │   ├── app_scaffold.dart
│   │   │   │   ├── app_bar_widget.dart
│   │   │   │   └── bottom_navigation_widget.dart
│   │   │   ├── animations/
│   │   │   │   ├── floating_bubble.dart
│   │   │   │   ├── loading_animation.dart
│   │   │   │   └── fade_transition.dart
│   │   │   └── feedback/
│   │   │       ├── snackbar_widget.dart
│   │   │       ├── dialog_widget.dart
│   │   │       └── toast_widget.dart
│   │   └── services/                     # 공통 서비스
│   │       ├── navigation_service.dart
│   │       ├── storage_service.dart
│   │       ├── audio_service.dart
│   │       └── network_service.dart
│   │
│   └── config/                           # 설정 및 환경
│       ├── app_config.dart
│       ├── api_config.dart
│       └── firebase_config.dart
│
├── assets/                               # 정적 리소스
│   ├── images/
│   │   ├── characters/                   # 캐릭터 이미지
│   │   ├── onboarding/                   # 온보딩 이미지
│   │   └── icons/                        # 아이콘
│   ├── fonts/                           # 폰트 파일
│   │   └── Pretendard/
│   └── animations/                       # 애니메이션 파일
│       └── lottie/
│
├── test/                                # 테스트 코드
│   ├── unit/
│   ├── widget/
│   └── integration/
│
└── docs/                                # 문서
    ├── onboarding_flow_architecture.md  # 이 문서
    ├── api_documentation.md
    └── deployment_guide.md
```

---

## 🎨 디자인 시스템 정의

### 🎨 색상 팔레트 (Figma 기반)

```dart
// core/constants/app_colors.dart
class AppColors {
  // 브랜드 컬러 (Material 3 기반)
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // 배경색 (Figma 분석 결과)
  static const Color background = Color(0xFFFDF7E9);  // 온보딩 배경
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  
  // 기능별 색상
  static const Color success = Color(0xFF4CAF50);     // 완료 알림
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF5252);       // 검증 에러
  static const Color info = Color(0xFF2196F3);
  
  // 온보딩 특화 색상
  static const Color notificationGreen = Color(0xFF81C784);  // 알림 배너
  static const Color inputSection = Color(0xFF57B3E6);       // 입력 섹션
  static const Color completionSection = Color(0xFFFFD8F1);  // 완료 섹션
  
  // 텍스트 색상
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFFBCBCBC);
  static const Color textHint = Color(0xFFB0B0B0);
}
```

### ✏️ 타이포그래피 시스템

```dart
// core/constants/app_text_styles.dart
class AppTextStyles {
  // Figma에서 추출한 폰트 스타일
  static const String fontFamily = 'Pretendard';
  
  // 헤드라인 (온보딩 타이틀)
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,  // Bold
    fontSize: 26,
    letterSpacing: 0,
    height: 40/26,  // lineHeightPx/fontSize
    color: AppColors.textPrimary,
  );
  
  // 캐릭터 이름
  static const TextStyle characterName = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    letterSpacing: 0,
    height: 28.640625/24,
    color: AppColors.textPrimary,
  );
  
  // 일반 텍스트 (20px)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: 0.15,
    height: 24/20,
    color: AppColors.textPrimary,
  );
  
  // 버튼 텍스트
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: 0,
    height: 19.09375/16,
    color: AppColors.onPrimary,
  );
  
  // 에러 메시지
  static const TextStyle errorText = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 10,
    letterSpacing: 0,
    height: 11.93359375/10,
    color: AppColors.error,
  );
  
  // 힌트 텍스트
  static const TextStyle hintText = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 12,
    letterSpacing: 0,
    height: 14.3203125/12,
    color: AppColors.textHint,
  );
}
```

### 📐 레이아웃 및 스페이싱

```dart
// core/constants/app_dimensions.dart
class AppDimensions {
  // 화면 기본값 (Figma: 375x812)
  static const double screenWidth = 375;
  static const double screenHeight = 812;
  
  // 패딩 및 마진
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;
  
  // 버튼 크기
  static const double buttonHeight = 56;
  static const double buttonWidth = 343;
  static const double buttonRadius = 100;  // Figma의 cornerRadius
  
  // 입력 필드
  static const double inputHeight = 55;
  static const double inputRadius = 40;
  
  // 아이콘 크기
  static const double iconS = 16;
  static const double iconM = 24;
  static const double iconL = 32;
  
  // 상태바 및 네비게이션
  static const double statusBarHeight = 44;
  static const double appBarHeight = 60;
  static const double homeIndicatorHeight = 34;
  
  // 카드 및 컨테이너
  static const double cardRadius = 16;
  static const double cardElevation = 4;
  
  // 애니메이션 지속시간
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationLong = Duration(milliseconds: 800);
}
```

---

## 🔄 상태 관리 아키텍처

### 📱 Provider 패턴 구조

```dart
// features/onboarding/presentation/providers/onboarding_provider.dart
class OnboardingProvider extends ChangeNotifier {
  // 현재 단계
  int _currentStep = 0;
  int get currentStep => _currentStep;
  
  // 사용자 입력 데이터
  String? _nickname;
  String? _location;
  String? _duration;
  String? _objectType;
  
  // 생성된 캐릭터 데이터
  Character? _generatedCharacter;
  Character? get generatedCharacter => _generatedCharacter;
  
  // 입력 검증 상태
  Map<String, String?> _validationErrors = {};
  Map<String, String?> get validationErrors => _validationErrors;
  
  // 로딩 상태
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  
  // 동적 텍스트 생성 (Figma의 {} 처리)
  String get welcomeMessage => "${_objectType ?? '사물'}이 깨어났어요!";
  String get characterAge => "${DateTime.now().year - 1999}년생";
  String get fullDescription => "${_location}에서 ${_duration} 함께한 ${_objectType}";
  
  // 메서드들
  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      notifyListeners();
    }
  }
  
  void updateUserInput({
    String? nickname,
    String? location, 
    String? duration,
    String? objectType,
  }) {
    if (nickname != null) _nickname = nickname;
    if (location != null) _location = location;
    if (duration != null) _duration = duration;
    if (objectType != null) _objectType = objectType;
    
    _validateInputs();
    notifyListeners();
  }
  
  Future<void> generateCharacter() async {
    _isGenerating = true;
    notifyListeners();
    
    try {
      // AI 캐릭터 생성 로직
      _generatedCharacter = await _characterService.generateCharacter(
        nickname: _nickname!,
        location: _location!,
        duration: _duration!,
        objectType: _objectType!,
      );
      nextStep();
    } catch (e) {
      // 에러 처리
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  void _validateInputs() {
    _validationErrors.clear();
    
    if (_nickname?.isEmpty ?? true) {
      _validationErrors['nickname'] = '이름을 입력해주세요!';
    }
    // 기타 검증 로직...
  }
  
  bool get isCurrentStepValid {
    switch (_currentStep) {
      case 0: return true; // 인트로는 항상 유효
      case 1: return _validationErrors.isEmpty && 
                     _nickname?.isNotEmpty == true;
      case 2: return _location != null && 
                     _duration != null && 
                     _objectType != null;
      case 3: return _generatedCharacter != null;
      default: return false;
    }
  }
}
```

---

## 🎬 애니메이션 시스템

### 🟢 Floating Bubble 애니메이션 (Figma 요구사항)

```dart
// shared/widgets/animations/floating_bubble.dart
class FloatingBubble extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;
  
  const FloatingBubble({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.intensity = 5.0,
  }) : super(key: key);

  @override
  _FloatingBubbleState createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.intensity,
      end: widget.intensity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 📱 화면 전환 애니메이션

```dart
// shared/widgets/animations/fade_transition.dart
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0.0, 1.0);
            var end = Offset.zero;
            var curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: AppDimensions.animationMedium,
        );
}
```

---

## 🧪 테스트 전략

### 🔍 단위 테스트 구조

```dart
// test/unit/features/onboarding/onboarding_provider_test.dart
group('OnboardingProvider', () {
  late OnboardingProvider provider;
  
  setUp(() {
    provider = OnboardingProvider();
  });
  
  test('should start at step 0', () {
    expect(provider.currentStep, 0);
  });
  
  test('should validate nickname input', () {
    provider.updateUserInput(nickname: '');
    expect(provider.validationErrors['nickname'], '이름을 입력해주세요!');
    
    provider.updateUserInput(nickname: '털찐 말랑이');
    expect(provider.validationErrors['nickname'], null);
  });
  
  test('should generate welcome message correctly', () {
    provider.updateUserInput(objectType: '머그컵');
    expect(provider.welcomeMessage, '머그컵이 깨어났어요!');
  });
});
```

### 🎨 위젯 테스트

```dart
// test/widget/features/onboarding/onboarding_intro_screen_test.dart
group('OnboardingIntroScreen', () {
  testWidgets('should display main text and button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingIntroScreen(),
    ));
    
    expect(find.text('지금부터 당신의\n애착 사물을 깨워볼께요.'), findsOneWidget);
    expect(find.text('캐릭터 깨우기'), findsOneWidget);
  });
  
  testWidgets('should navigate to next screen on button tap', (tester) async {
    // 네비게이션 테스트 로직
  });
});
```

---

## 🚀 구현 로드맵

### Phase 1: 기본 온보딩 플로우 (Week 1-2)
- [ ] 디렉토리 구조 설정
- [ ] 디자인 시스템 구현 (색상, 타이포그래피, 컴포넌트)
- [ ] 온보딩 인트로 화면
- [ ] 사물 정보 입력 화면
- [ ] 기본 상태 관리 (Provider)

### Phase 2: 캐릭터 생성 시스템 (Week 3)
- [ ] AI 캐릭터 생성 서비스 연동
- [ ] 캐릭터 생성 로딩 화면
- [ ] 캐릭터 완료 화면
- [ ] QR 코드 생성 및 공유 기능

### Phase 3: 애니메이션 및 UX 개선 (Week 4)
- [ ] Floating bubble 애니메이션 구현
- [ ] 화면 전환 애니메이션
- [ ] 음성 재생 기능 (TTS)
- [ ] 입력 검증 및 에러 처리

### Phase 4: 테스트 및 최적화 (Week 5)
- [ ] 단위 테스트 작성
- [ ] 위젯 테스트 작성
- [ ] 통합 테스트
- [ ] 성능 최적화 및 버그 수정

---

## 📚 참고 자료

- **Figma 디자인**: Material 3 Expression UI Kit 기반
- **Flutter 공식 문서**: https://flutter.dev/docs
- **Material 3 Guidelines**: https://m3.material.io/
- **Provider 패턴**: https://pub.dev/packages/provider
- **Clean Architecture**: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html

---

**문서 버전**: v1.0  
**최종 수정**: 2024년 12월  
**작성자**: NomPangS Development Team 