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
import 'package:nompangs/services/firebase_manager.dart';
import 'package:nompangs/helpers/deeplink_helper.dart';

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
  await FirebaseManager.initialize();
  
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

  void _handleDeepLink(Uri uri) async {
    final roomId = uri.queryParameters['roomId'];
    final encodedData = uri.queryParameters['data'];
    print('📦 딥링크 수신됨! URI: $uri, roomId: $roomId');

    if (roomId != null) {
      if (encodedData != null) {
        final chatData = await DeepLinkHelper.processCharacterData(encodedData);

        if (chatData != null) {
          _navigatorKey.currentState?.pushNamed(
            '/chat/${chatData['personaId']}',
            arguments: chatData,
          );
        } else {
          DeepLinkHelper.showError(
              _navigatorKey.currentContext!,
              '캐릭터 정보를 읽을 수 없습니다.'
          );
        }
      } else {
        // data 파라미터가 없는 경우
        DeepLinkHelper.showError(
            _navigatorKey.currentContext!,
            '캐릭터 정보가 없는 QR 코드입니다.'
        );
      }
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
            
            if (args == null) {
              // 캐릭터 정보가 없는 경우 에러 화면으로 이동
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('오류'),
                    backgroundColor: Colors.black,
                  ),
                  backgroundColor: Colors.black,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          '캐릭터 정보를 찾을 수 없습니다.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '올바른 QR 코드를 스캔해주세요.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('돌아가기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ChatScreen(
                characterName: args['characterName'] ?? '캐릭터 $roomId',
                personalityTags: args['personalityTags'] ?? ['친절한', '도움이 되는'],
                greeting: args['greeting'],
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
