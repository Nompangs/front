import 'package:nompangs/main.dart';
import 'package:flutter/material.dart';
import 'package:nompangs/widgets/bottom_nav_bar.dart';
import 'package:nompangs/widgets/mic_button.dart';
import 'package:nompangs/screens/character/character_create_screen.dart';
import 'dart:async';
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:permission_handler/permission_handler.dart';


class HomeScreen extends StatefulWidget {

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _deeplinkWatcher;
  int _deeplinkCheckCount = 0;
  final int _maxDeeplinkChecks = 5;

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();

    _deeplinkWatcher = Timer.periodic(Duration(milliseconds: 300), (timer) async {
      if (pendingRoomId != null) {
        final roomId = pendingRoomId!;
        try {
          // 딥링크로 ChatScreen 이동 시, 캐릭터 정보가 필요합니다.
          // 현재 pendingRoomId만으로는 캐릭터 정보를 알 수 없으므로,
          // 딥링크 처리 로직에서 캐릭터 정보를 가져오거나,
          // roomId에 해당하는 캐릭터 정보를 조회하는 로직이 필요합니다.
          // 임시로 기본 캐릭터로 이동하도록 처리하거나, 에러 처리 필요.
          print('🚨 [Timer] 딥링크로 ChatScreen 이동 시 캐릭터 정보 누락. roomId: $roomId');
          // 예시: Navigator.pushNamed(context, '/chat/$roomId', arguments: { 'characterName': '딥링크 친구', ... });
        } catch (e) {
          print('❌ [Timer] 채팅방 이동 실패: $e');
        } finally {
          pendingRoomId = null;
          timer.cancel();
        }
      } else {
        _deeplinkCheckCount++;
        if (_deeplinkCheckCount >= _maxDeeplinkChecks) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _deeplinkWatcher?.cancel();
    super.dispose();
  }

  Future<void> _requestMicrophonePermission() async { 
    final status = await Permission.microphone.status; 
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) { 
      // 권한이 없거나 영구적으로 거부된 경우 요청 
      final result = await Permission.microphone.request(); 
      if (result.isGranted) { 
        print("마이크 권한이 허용되었습니다."); 
      } else if (result.isDenied) { 
        print("마이크 권한이 거부되었습니다."); 
        _showPermissionDeniedSnackBar("마이크 권한이 거부되어 음성 인식을 사용할 수 없습니다."); 
      } else if (result.isPermanentlyDenied) { 
        print("마이크 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요."); 
        _showPermissionDeniedSnackBar("마이크 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요."); 
        openAppSettings(); // 앱 설정 열기 
      } 
    } else if (status.isGranted) { 
      print("마이크 권한이 이미 허용되었습니다."); 
    } 
  } 

  void _showPermissionDeniedSnackBar(String message) { 
    ScaffoldMessenger.of(context).showSnackBar( 
      SnackBar( 
        content: Text(message), 
        backgroundColor: Colors.red, 
        duration: Duration(seconds: 5), 
        action: SnackBarAction( 
          label: '설정 열기', 
          onPressed: () { 
            openAppSettings(); 
          }, 
        ), 
      ), 
    ); 
  } 

  void _startChatWithDefaultAI(String inputText) {
    if (inputText.trim().isEmpty) return;

    // "기본 AI 친구" 정보 정의 (예: 야옹이)
    // 이 정보는 GeminiService의 기본 프롬프트와 일치하거나,
    // 사용자가 선택한 기본 캐릭터 등으로 동적으로 설정될 수 있습니다.
    final defaultCharacter = {
      'name': '야옹이',
      'tags': ['감성적인', '귀여운', '엉뚱한'],
      'greeting': '안녕이다옹! 무슨 일 있었냐옹?',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          characterName: defaultCharacter['name'] as String,
          personalityTags: defaultCharacter['tags'] as List<String>,
          greeting: defaultCharacter['greeting'] as String,
          initialUserMessage: inputText,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Index',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterCreateScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/qr-scanner');
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundImage: AssetImage('assets/profile.png')),
          )
        ],
      ),
      body: _buildEmptyScreen(), // 채팅 UI 제거, 빈 화면 또는 다른 UI 표시
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(
        onSpeechResult: _startChatWithDefaultAI, // STT 결과를 ChatScreen으로 전달
        onEventDetected: (event) {}, // 일정 감지 기능은 현재 사용되지 않음
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/task_image.png', width: 250),
          SizedBox(height: 20),
          Text(
            '무엇을 도와드릴까요?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '마이크 버튼을 눌러 AI 친구와 대화해보세요!',
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}