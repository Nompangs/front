import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:nompangs/screens/auth/intro_screen.dart';
import 'package:nompangs/screens/auth/login_screen.dart';
import 'package:nompangs/screens/main/home_screen.dart';
import 'package:nompangs/screens/auth/register_screen.dart';
import 'package:nompangs/screens/main/qr_scanner_screen.dart';
import 'package:nompangs/screens/main/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env 파일 로드 성공!");
  } catch (e) {
    print("🚨 .env 파일 로드 실패: $e");
  }

  await Firebase.initializeApp();
  
  runApp(NompangsApp());
}

class NompangsApp extends StatefulWidget {
  @override
  State<NompangsApp> createState() => _NompangsAppState();
}

class _NompangsAppState extends State<NompangsApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

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
    // Cold start 처리
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Hot start 처리
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('App Link error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    // 위젯이 마운트된 후에 라우팅을 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomId = uri.queryParameters['roomId'];
      if (roomId != null) {
        Navigator.of(context).pushNamed('/chat/$roomId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nompangs',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/': (context) => IntroScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/qr-scanner': (context) => const QRScannerScreen(),
      },
      onGenerateRoute: (settings) {
        // 동적 라우트 처리
        if (settings.name?.startsWith('/chat/') ?? false) {
          final roomId = settings.name?.split('/').last;
          if (roomId != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ChatScreen(
                characterName: '캐릭터 $roomId',
                personalityTags: ['친절한', '도움이 되는'],
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
