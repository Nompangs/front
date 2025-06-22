import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'dart:async';
import 'package:nompangs/screens/auth/intro_screen.dart';
import 'package:nompangs/screens/auth/login_screen.dart';
import 'package:nompangs/screens/auth/register_screen.dart';
import 'package:nompangs/screens/main/qr_scanner_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_intro_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_input_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_purpose_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_photo_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_generation_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_personality_screen.dart';
import 'package:nompangs/screens/onboarding/onboarding_completion_screen.dart';
import 'package:nompangs/theme/app_theme.dart';
import 'package:nompangs/services/firebase_manager.dart';
import 'package:nompangs/helpers/deeplink_helper.dart';
import 'package:nompangs/screens/chat/chat_history_screen.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/screens/main/flutter_mobile_clone.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String? pendingRoomId;

// 앱 전체에서 사용할 기본/임시 캐릭터 프로필
final Map<String, dynamic> _defaultCharacterProfile = {
  'uuid': 'default_character_uuid',
  'greeting': '안녕하세요! 저와 대화를 시작해 보세요.',
  'communicationPrompt': '사용자에게 친절하고 상냥하게 응답해주세요.',
  'initialUserMessage': '기본 페르소나와 대화하고 싶어.',
  'aiPersonalityProfile': {
    'name': '기본 페르소나',
    'objectType': '사물',
    'npsScores': <String, int>{},
  },
  'photoAnalysis': <String, dynamic>{},
  'attractiveFlaws': <Map<String, String>>[],
  'contradictions': <Map<String, String>>[],
  'userInput': {
    'warmth': 5,
    'extroversion': 5,
    'competence': 5,
    'humorStyle': '기본',
  },
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env 파일 로드 성공!");
  } catch (e) {
    print("🚨 .env 파일 로드 실패: $e");
  }

  await Firebase.initializeApp();
  await FirebaseManager.initialize();

  runApp(NompangsApp());
}

// 간단한 테스트 화면
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('테스트 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChangeNotifierProvider(
                          create:
                              (_) => ChatProvider(
                                characterProfile: _defaultCharacterProfile,
                              ),
                          child: const ChatTextScreen(),
                        ),
                  ),
                );
              },
              child: const Text('정적 캐릭터로 채팅 테스트'),
            ),
            Text(
              '테스트 화면',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Flutter iOS가 작동합니다!',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/flutter-mobile-clone');
              },
              child: Text('뉴홈 화면 UI'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('로그인 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

class NompangsApp extends StatefulWidget {
  const NompangsApp({super.key});

  @override
  State<NompangsApp> createState() => _NompangsAppState();
}

class _NompangsAppState extends State<NompangsApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('App Link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) async {
    final uuid = uri.queryParameters['roomId'] ?? uri.queryParameters['id'];
    print('📦 딥링크 수신됨! URI: $uri, 추출된 UUID: $uuid');

    if (uuid != null) {
      try {
        final apiService = ApiService();
        final profile = await apiService.loadProfile(uuid);

        final characterProfileMap = profile.toMap();

        // 🚨 [수정] Firestore에서 현재 유저의 displayName을 가져와 주입합니다.
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
          characterProfileMap['userDisplayName'] =
              doc.data()?['displayName'] ?? '게스트';
        } else {
          characterProfileMap['userDisplayName'] = '게스트';
        }

        debugPrint('✅ [딥링크 진입] ChatProvider로 전달되는 프로필: $characterProfileMap');

        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (context) => ChangeNotifierProvider(
                  create:
                      (_) =>
                          ChatProvider(characterProfile: characterProfileMap),
                  child: const ChatTextScreen(showHomeInsteadOfBack: true),
                ),
          ),
        );
      } catch (e) {
        print('🚨 딥링크 프로필 로딩 실패: $e');
        if (_navigatorKey.currentContext != null) {
          DeepLinkHelper.showError(
            _navigatorKey.currentContext!,
            '캐릭터 정보를 불러오는 데 실패했습니다.',
          );
        }
      }
    } else {
      print('📦 딥링크에 유효한 ID(roomId 또는 id)가 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => OnboardingProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        title: 'Nompangs',
        theme: AppTheme.lightTheme,
        initialRoute: '/test',
        routes: {
          '/': (context) => IntroScreen(),
          '/test': (context) => TestScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/qr-scanner': (context) => const QRScannerScreen(),
          '/chat-history': (context) => const ChatHistoryScreen(),
          '/onboarding/intro': (context) => const OnboardingIntroScreen(),
          '/onboarding/input': (context) => const OnboardingInputScreen(),
          '/onboarding/purpose': (context) => const OnboardingPurposeScreen(),
          '/onboarding/photo': (context) => const OnboardingPhotoScreen(),
          '/onboarding/generation':
              (context) => const OnboardingGenerationScreen(),
          '/onboarding/personality':
              (context) => const OnboardingPersonalityScreen(),
          '/onboarding/completion':
              (context) => const OnboardingCompletionScreen(),
          '/flutter-mobile-clone': (context) => MainScreen(),
        },
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '');

          // '/chat/{characterId}' 형태의 경로를 처리
          if (uri.pathSegments.length == 2 &&
              uri.pathSegments.first == 'chat') {
            // 이 로직은 딥링크 핸들러(_handleDeepLink)와 중복되므로,
            // _handleDeepLink에서 모든 딥링크를 처리하도록 유도하고 여기서는 비워두거나 제거할 수 있습니다.
            // 현재 앱에서는 _handleDeepLink가 AppLinks를 통해 비동기적으로 처리하므로 onGenerateRoute는 사용되지 않을 가능성이 높습니다.
            // 만약을 위해 null을 반환하여 정의되지 않은 경로임을 명시합니다.
            return null;
          }
          return null; // 처리되지 않은 다른 모든 경로
        },
      ),
    );
  }
}
