import 'package:nompangs/main.dart';
import 'package:flutter/material.dart';
import 'package:nompangs/widgets/bottom_nav_bar.dart';
import 'package:nompangs/widgets/mic_button.dart';
import 'package:nompangs/screens/character/character_create_screen.dart';
import 'dart:async';
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/models/personality_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _deeplinkWatcher;
  int _deeplinkCheckCount = 0;
  final int _maxDeeplinkChecks = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // initState에서 _requestMicrophonePermission() 직접 호출을 제거하거나,
    // 앱 로딩 후 필요한 시점에 호출하도록 변경합니다.
    // 현재 문제는 앱 시작부터 권한이 꼬이는 것이므로, 사용자 액션에 따라 요청하는 것이 더 안전할 수 있습니다.
    // print("HomeScreen initState: 권한 요청 로직은 사용자 액션 시점으로 이동 고려.");

    _deeplinkWatcher = Timer.periodic(Duration(milliseconds: 300), (
      timer,
    ) async {
      if (pendingRoomId != null) {
        final roomId = pendingRoomId!;
        try {
          print('🚨 [Timer] 딥링크로 ChatScreen 이동 시 캐릭터 정보 누락. roomId: $roomId');
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
    WidgetsBinding.instance.removeObserver(this);
    _deeplinkWatcher?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("App resumed, re-checking microphone permission.");
      // 앱이 다시 활성화될 때 권한 상태를 확인합니다.
      // 만약 이 시점에 STT가 활성화되어야 한다면 _requestMicrophonePermission를 호출할 수 있습니다.
      // 하지만 사용자가 마이크 버튼을 누르기 전까지는 필수가 아닐 수 있습니다.
      // 현재 상태를 확인하고 UI를 업데이트 하는 용도로만 사용할 수도 있습니다.
      _requestMicrophonePermission(); // OS 설정 변경 후 돌아왔을 때 상태 갱신을 위해 호출 유지
    }
  }

  Future<bool> _checkAndRequestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    print(
      "Checking permission: $status, isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied}, isRestricted: ${status.isRestricted}",
    );

    if (status.isGranted) {
      print("마이크 권한이 이미 허용되어 있습니다.");
      return true;
    }

    if (status.isPermanentlyDenied) {
      print("마이크 권한이 영구적으로 거부된 상태입니다. 설정에서 변경해주세요. (Check)");
      _showPermissionDeniedSnackBar(
        "마이크 사용을 위해서는 권한이 필요합니다. 앱 설정에서 직접 마이크 권한을 허용해주세요.",
      );
      await openAppSettings();
      return false; // 설정 화면으로 보냈으므로 false 반환
    }

    // isDenied 또는 isRestricted 등 (isGranted 아니고 isPermanentlyDenied도 아닌 경우)
    // 여기서 다시 request를 호출합니다.
    final result = await Permission.microphone.request();
    print(
      "Permission request result: $result, isGranted: ${result.isGranted}, isDenied: ${result.isDenied}, isPermanentlyDenied: ${result.isPermanentlyDenied}, isRestricted: ${result.isRestricted}",
    );

    if (result.isGranted) {
      print("마이크 권한이 허용되었습니다.");
      return true;
    } else if (result.isPermanentlyDenied) {
      print("마이크 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요. (After request)");
      _showPermissionDeniedSnackBar(
        "마이크 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.",
      );
      await openAppSettings();
      return false;
    } else {
      // isDenied, isRestricted 등
      print("마이크 권한이 거부되거나 제한되었습니다.");
      _showPermissionDeniedSnackBar("마이크 권한이 거부되어 음성 인식을 사용할 수 없습니다.");
      return false;
    }
  }

  // _requestMicrophonePermission 함수는 didChangeAppLifecycleState에서 사용될 수 있도록 유지
  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    print(
      "(Lifecycle) Initial permission status: $status, isGranted: ${status.isGranted}, isDenied: ${status.isDenied}, isPermanentlyDenied: ${status.isPermanentlyDenied}, isRestricted: ${status.isRestricted}",
    );

    if (status.isGranted) {
      print("(Lifecycle) 마이크 권한이 이미 허용되었습니다.");
      return;
    }

    if (status.isPermanentlyDenied) {
      print(
        "(Lifecycle) 마이크 권한이 영구적으로 거부된 상태입니다. 설정에서 변경해주세요. (Initial check)",
      );
      // 이 경우, 사용자가 앱으로 돌아올 때마다 설정으로 보내는 것은 사용자 경험에 좋지 않을 수 있습니다.
      // _showPermissionDeniedSnackBar를 호출하거나, 앱 내 다른 UI로 안내할 수 있습니다.
      // 여기서는 일단 로그만 남기고, 실제 권한 요청은 MicButton 클릭 시 _checkAndRequestMicrophonePermission 에서 처리하도록 합니다.
      // _showPermissionDeniedSnackBar("마이크 권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 권한을 허용해주세요.");
      // await openAppSettings();
      return;
    }

    // isDenied 또는 isRestricted인 경우, 앱이 foreground로 돌아올 때마다 자동으로 request를 호출하는 것은
    // 사용자에게 반복적인 팝업을 띄울 수 있으므로, 여기서는 상태 확인만 하고 실제 요청은 사용자 인터랙션 시 하도록 합니다.
    if (status.isDenied || status.isRestricted) {
      print("(Lifecycle) 마이크 권한이 거부 또는 제한된 상태입니다. 사용자 액션 시 재요청 필요.");
      // final result = await Permission.microphone.request();
      // ... (이하 로직은 _checkAndRequestMicrophonePermission 과 유사하게 처리 가능하나, 여기서는 생략)
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

  void _handleMicButtonPressed(String recognizedText) async {
    // MicButton이 눌렸을 때 먼저 권한을 확인하고 요청합니다.
    bool permissionGranted = await _checkAndRequestMicrophonePermission();

    if (permissionGranted) {
      // 권한이 허용된 경우에만 _startChatWithDefaultAI를 호출합니다.
      _startChatWithDefaultAI(recognizedText);
    } else {
      // 권한이 허용되지 않은 경우 (이미 스낵바 등이 표시되었을 수 있음)
      print("마이크 권한이 없어 채팅을 시작할 수 없습니다.");
      // 필요하다면 추가적인 사용자 안내 UI 표시
    }
  }

  void _startChatWithDefaultAI(String inputText) {
    if (inputText.trim().isEmpty && mounted) {
      // 입력된 텍스트가 없을 경우 (STT가 최종 결과를 반환했지만 내용이 없는 경우 등)
      // 사용자에게 안내 메시지를 보여주거나, 아무 동작도 하지 않을 수 있습니다.
      // 예를 들어, STT가 활성화 되었다가 아무 말 없이 종료되면 inputText가 비어있을 수 있습니다.
      print("입력된 음성이 없습니다.");
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("음성 입력이 없습니다. 다시 시도해주세요."))
      // );
      return;
    }
    if (inputText.trim().isEmpty) return;

    // 기본 캐릭터 정보를 PersonalityProfile 객체로 생성합니다.
    final defaultProfile = PersonalityProfile(
      aiPersonalityProfile: AiPersonalityProfile(
        name: '야옹이',
        objectType: '고양이',
        emotionalRange: 7,
        coreValues: ['관심', '간식'],
        relationshipStyle: '애교 많은',
        summary: '사람을 잘 따르는 귀여운 고양이입니다.',
        npsScores: {}, // NpsScores.empty() 대신 빈 Map 사용
      ),
      contradictions: ['진지한 대화를 좋아하면서도 가벼운 농담을 즐김'],
      greeting: '안녕이다옹! 무슨 일 있었냐옹?',
      initialUserMessage: inputText,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        // ChatScreen에는 profile 객체 하나만 전달합니다.
        builder: (context) => ChatScreen(profile: defaultProfile),
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
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ),
        ],
      ),
      body: _buildEmptyScreen(),
      bottomNavigationBar: BottomNavBar(),
      floatingActionButton: MicButton(
        // onSpeechResult 콜백을 _handleMicButtonPressed로 변경
        onSpeechResult: _handleMicButtonPressed,
        onEventDetected: (event) {},
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
