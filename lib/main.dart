import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:nompangs/screens/auth/intro_screen.dart';
import 'package:nompangs/screens/auth/login_screen.dart';
import 'package:nompangs/screens/main/home_screen.dart';
import 'package:nompangs/screens/auth/register_screen.dart';
import 'package:nompangs/screens/main/qr_scanner_screen.dart';
import 'package:nompangs/screens/main/chat_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

String? pendingRoomId;

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
    // Cold start 처리
    final initialUri = await _appLinks.getInitialLink();
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
    final roomId = uri.queryParameters['roomId'];
    final encodedData = uri.queryParameters['data'];
    print('📦 딥링크 수신됨! URI: $uri, roomId: $roomId');
    
    if (roomId != null) {
      if (encodedData != null) {
        try {
          // base64 디코딩 및 JSON 파싱
          final decodedData = utf8.decode(base64Decode(encodedData));
          final characterData = jsonDecode(decodedData);
          
          if (characterData.containsKey('name') && 
              characterData.containsKey('tags')) {
            
            // GlobalKey를 사용하여 Navigator에 접근
            _navigatorKey.currentState?.pushNamed(
              '/chat/$roomId',
              arguments: {
                'characterName': characterData['name'],
                'personalityTags': List<String>.from(characterData['tags']),
                'greeting': characterData['greeting'],
              },
            );
            return;
          }
        } catch (e) {
          print('Error parsing character data: $e');
        }
      }
      
      // 데이터가 없거나 파싱에 실패한 경우
      pendingRoomId = roomId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Nompangs',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/home',
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
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ChatScreen(
                characterName: args?['characterName'] ?? '캐릭터 $roomId',
                personalityTags: args?['personalityTags'] ?? ['친절한', '도움이 되는'],
                greeting: args?['greeting'],
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
