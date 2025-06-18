import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:nompangs/screens/main/find_momenti_screen.dart';
import 'package:nompangs/screens/main/chat_screen.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nompangs/services/api_service.dart';
import 'package:nompangs/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momenti App',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Pretendard'),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  String selectedFilter = "전체";
  final List<String> filterOptions = [
    "전체",
    "NEW",
    "내 방",
    "우리집 안방",
    "사무실",
    "단골 카페",
  ];
  int? selectedCardIndex;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<ObjectData> objectData = [];
  bool _isLoading = true;
  String? _error;
  String? displayName;

  AnimationController? _morphController1;
  AnimationController? _morphController2;
  AnimationController? _morphController3;
  Animation<double>? _scaleAnimation1;
  Animation<double>? _scaleAnimation2;
  Animation<double>? _scaleAnimation3;
  Animation<double>? _shapeAnimation1;
  Animation<double>? _shapeAnimation2;
  Animation<double>? _shapeAnimation3;

  AnimationController? _notificationIconController;
  Animation<double>? _notificationIconRotation;

  @override
  void initState() {
    super.initState();
    _fetchDisplayName();
    _initializeData();

    // 각 버튼별 애니메이션 컨트롤러 초기화
    _morphController1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _morphController2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _morphController3 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 스케일 애니메이션 (크기 변화)
    _scaleAnimation1 = _createScaleAnimation(_morphController1!, 1.2);
    _scaleAnimation2 = _createScaleAnimation(_morphController2!, 1.2);
    _scaleAnimation3 = _createScaleAnimation(_morphController3!, 1.2);

    _shapeAnimation1 = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _morphController1!, curve: Curves.elasticOut),
    );
    _shapeAnimation2 = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _morphController2!, curve: Curves.elasticOut),
    );
    _shapeAnimation3 = Tween<double>(begin: 1.0, end: 0.65).animate(
      CurvedAnimation(parent: _morphController3!, curve: Curves.elasticOut),
    );

    // 파란색과 초록색 버튼 애니메이션 시작
    _morphController1?.repeat(reverse: true);
    _morphController3?.repeat(reverse: true);

    // 분홍색 버튼 애니메이션 딜레이 시작
    Future.delayed(const Duration(milliseconds: 750), () {
      _morphController2?.repeat(reverse: true);
    });

    if (objectData.isNotEmpty) {
      _notificationIconController = AnimationController(
        duration: const Duration(seconds: 9),
        vsync: this,
      )..repeat();
      _notificationIconRotation = Tween<double>(
        begin: 0,
        end: 2 * 3.141592,
      ).animate(
        CurvedAnimation(
          parent: _notificationIconController!,
          curve: Curves.linear,
        ),
      );
    } else {
      _notificationIconController = null;
      _notificationIconRotation = null;
    }
  }

  Future<void> _fetchDisplayName() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    setState(() {
      displayName = doc.data()?['displayName'] ?? '게스트';
    });
  }

  Future<void> _initializeData() async {
    if (_authService.currentUser == null) {
      setState(() {
        _error = '로그인이 필요합니다.';
        _isLoading = false;
      });
      // 로그인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await _loadAwokenObjects();
  }

  Future<void> _loadAwokenObjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final objects = await _apiService.getAwokenObjects();
      setState(() {
        objectData = objects.map((obj) => ObjectData.fromMap(obj)).toList();
        _isLoading = false;
      });
      _updateIconAnimation();
    } catch (e) {
      print('🚨 사물 목록 로드 실패: $e');
      if (e.toString().contains('Authentication required')) {
        setState(() {
          _error = '로그인이 필요합니다.';
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // 에러 시 기본 테스트 데이터 사용
      setState(() {
        objectData = [
          ObjectData(
            title: "디자인 체어",
            location: "내 방",
            duration: "42 min",
            isNew: true,
            imageUrl: "assets/testImg_1.png",
            uuid: "test-1",
            uid: "test-1-uid",
          ),
          ObjectData(
            title: "제임쓰 카페인쓰",
            location: "사무실",
            duration: "5 min",
            imageUrl: "assets/testImg_2.png",
            uuid: "test-2",
            uid: "test-2-uid",
          ),
          ObjectData(
            title: "빈백",
            location: "우리집 안방",
            duration: "139 min",
            imageUrl: "assets/testImg_3.png",
            uuid: "test-3",
            uid: "test-3-uid",
          ),
          // 테스트 카드 1
          ObjectData(
            title: "테스트 소파",
            location: "단골 카페",
            duration: "12 min",
            isNew: false,
            imageUrl: "assets/testImg_4.png",
            uuid: "test-4",
            uid: "test-4-uid",
          ),
          // 테스트 카드 2
          ObjectData(
            title: "테스트 램프",
            location: "내 방",
            duration: "88 min",
            isNew: true,
            imageUrl: "assets/testImg_5.png",
            uuid: "test-5",
            uid: "test-5-uid",
          ),
        ];
        _isLoading = false;
        _error = '데이터를 불러오는데 실패했습니다. 테스트 데이터를 표시합니다.';
      });
      _updateIconAnimation();
    }
  }

  // 버튼 클릭 애니메이션 함수들 - 이제 즉시 화면 전환
  void _playAnimation1() {
    Navigator.pushNamed(context, '/chat-history');
  }

  void _playAnimation2() {
    Navigator.pushNamed(context, '/onboarding/intro');
  }

  void _playAnimation3() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FindMomentiScreen()),
    );
  }

  @override
  void dispose() {
    _morphController1?.dispose();
    _morphController2?.dispose();
    _morphController3?.dispose();
    _notificationIconController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isPortrait = height > width;
    final baseWidth = 375.0;
    final scale = width / baseWidth;

    return Scaffold(
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          children: [
            Column(
              children: [
                // Header with cream background (높이 240)
                Container(
                  width: double.infinity,
                  height: 230 * scale,
                  color: const Color.fromRGBO(253, 247, 233, 1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24 * scale,
                            top: 105 * scale,
                            bottom: 32 * scale,
                            right: 8 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '오늘, ${_getTodayString()}',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12 * scale),
                              Text(
                                '안냥,${(displayName != null && displayName!.isNotEmpty) ? displayName : '게스트'}님',
                                style: TextStyle(
                                  color: Color(0xFF222222),
                                  fontSize: 26 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2 * scale),
                              Text(
                                '오늘은 누구랑 대화할까요?',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 60 * scale,
                          right: 32 * scale,
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(
                                'assets/profile_1.png',
                              ),
                              radius: 28 * scale,
                            ),
                            SizedBox(height: 8 * scale),
                            IconButton(
                              icon: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.black,
                                size: 28 * scale,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/qr-scanner');
                              },
                              tooltip: '카메라로 스캔',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 파랑/핑크/초록 타원 버튼 영역 - 화면 정중앙에 배치
                Container(
                  width: double.infinity,
                  height: 215 * scale,
                  //margin: EdgeInsets.only(bottom: 10 * scale),
                  color: const Color.fromARGB(255, 0, 0, 0),
                  child: Transform.translate(
                    offset: Offset(10 * scale, 15 * scale),
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final overlap = 15 * scale;
                          final buttonWidth = 125 * scale;
                          final buttonHeight = 190 * scale;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 첫 번째 버튼 (파랑)
                              AnimatedBuilder(
                                animation: Listenable.merge(
                                  [
                                    _scaleAnimation1,
                                    _shapeAnimation1,
                                  ].whereType<Listenable>().toList(),
                                ),
                                builder: (context, child) {
                                  return GestureDetector(
                                    onTap: _playAnimation1,
                                    child: Transform.scale(
                                      scale: _scaleAnimation1?.value ?? 1.0,
                                      child: Transform.rotate(
                                        angle: 40 * 3.141592 / 180,
                                        child: ClipPath(
                                          clipper: MorphingEllipseClipper(
                                            _shapeAnimation1?.value ?? 1.0,
                                          ),
                                          child: Material(
                                            color: Color.fromRGBO(
                                              87,
                                              179,
                                              230,
                                              1,
                                            ),
                                            child: InkWell(
                                              onTap: _playAnimation1,
                                              splashColor: Colors.white
                                                  .withOpacity(0.3),
                                              highlightColor: Colors.white
                                                  .withOpacity(0.1),
                                              child: SizedBox(
                                                width: buttonWidth,
                                                height: buttonHeight,
                                                child: Align(
                                                  alignment: Alignment(0, 0.8),
                                                  child: Transform.rotate(
                                                    angle: -40 * 3.141592 / 180,
                                                    child: Text(
                                                      '나와\n접촉한\n모멘티\n',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 16 * scale,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.left,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // 두 번째 버튼 (핑크)
                              Transform.translate(
                                offset: Offset(-overlap * 0.5, 0),
                                child: AnimatedBuilder(
                                  animation: Listenable.merge(
                                    [
                                      _scaleAnimation2,
                                      _shapeAnimation2,
                                    ].whereType<Listenable>().toList(),
                                  ),
                                  builder: (context, child) {
                                    return GestureDetector(
                                      onTap: _playAnimation2,
                                      child: Transform.scale(
                                        scale: _scaleAnimation2?.value ?? 1.0,
                                        child: Transform.rotate(
                                          angle: 40 * 3.141592 / 180,
                                          child: ClipPath(
                                            clipper: MorphingEllipseClipper(
                                              _shapeAnimation2?.value ?? 1.0,
                                            ),
                                            child: Material(
                                              color: Color.fromRGBO(
                                                255,
                                                216,
                                                241,
                                                1,
                                              ),
                                              child: InkWell(
                                                onTap: _playAnimation2,
                                                splashColor: Colors.white
                                                    .withOpacity(0.3),
                                                highlightColor: Colors.white
                                                    .withOpacity(0.1),
                                                child: SizedBox(
                                                  width: buttonWidth,
                                                  height: buttonHeight,
                                                  child: Align(
                                                    alignment: Alignment(
                                                      0,
                                                      0.8,
                                                    ),
                                                    child: Transform.rotate(
                                                      angle:
                                                          -40 * 3.141592 / 180,
                                                      child: Text(
                                                        '새로운\n모멘티\n깨우기\n',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16 * scale,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // 세 번째 버튼 (초록)
                              Transform.translate(
                                offset: Offset(-overlap, 0),
                                child: AnimatedBuilder(
                                  animation: Listenable.merge(
                                    [
                                      _scaleAnimation3,
                                      _shapeAnimation3,
                                    ].whereType<Listenable>().toList(),
                                  ),
                                  builder: (context, child) {
                                    return GestureDetector(
                                      onTap: _playAnimation3,
                                      child: Transform.scale(
                                        scale: _scaleAnimation3?.value ?? 1.0,
                                        child: Transform.rotate(
                                          angle: 40 * 3.141592 / 180,
                                          child: ClipPath(
                                            clipper: MorphingEllipseClipper(
                                              _shapeAnimation3?.value ?? 1.0,
                                            ),
                                            child: Material(
                                              color: Color.fromRGBO(
                                                63,
                                                203,
                                                128,
                                                1,
                                              ),
                                              child: InkWell(
                                                onTap: _playAnimation3,
                                                splashColor: Colors.white
                                                    .withOpacity(0.3),
                                                highlightColor: Colors.white
                                                    .withOpacity(0.1),
                                                child: SizedBox(
                                                  width: buttonWidth,
                                                  height: buttonHeight,
                                                  child: Align(
                                                    alignment: Alignment(
                                                      0,
                                                      0.8,
                                                    ),
                                                    child: Transform.rotate(
                                                      angle:
                                                          -40 * 3.141592 / 180,
                                                      child: Text(
                                                        '내주변\n모멘티\n탐색\n',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 16 * scale,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Black section with filters (타원 영역과 바로 붙임)
                Container(
                  width: double.infinity,
                  height: 45 * scale,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 5 * scale),
                    child: Row(
                      children:
                          filterOptions
                              .map(
                                (filter) => FilterChip(
                                  label: filter,
                                  selected: selectedFilter == filter,
                                  onTap:
                                      () => setState(
                                        () => selectedFilter = filter,
                                      ),
                                  scale: scale,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),

                // Cards section - 남은 공간을 모두 차지
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      21 * scale,
                      16 * scale,
                      8 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              '내가 깨운 사물들',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Container(
                              width: 20 * scale,
                              height: 20 * scale,
                              decoration: BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10 * scale),
                              ),
                              child: Center(
                                child: Text(
                                  '${filteredObjectData.length}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scale),
                        // Horizontal scrollable cards
                        Expanded(
                          child:
                              _isLoading
                                  ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3FCB80),
                                      ),
                                    ),
                                  )
                                  : Column(
                                    children: [
                                      if (_error != null)
                                        Padding(
                                          padding: EdgeInsets.all(16 * scale),
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 14 * scale,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: filteredObjectData.length,
                                          separatorBuilder:
                                              (context, index) =>
                                                  SizedBox(width: 12 * scale),
                                          itemBuilder:
                                              (
                                                context,
                                                index,
                                              ) => GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedCardIndex =
                                                        selectedCardIndex ==
                                                                index
                                                            ? null
                                                            : index;
                                                  });
                                                },
                                                child: ObjectCard(
                                                  data:
                                                      filteredObjectData[index],
                                                  scale: scale,
                                                  isSelected:
                                                      selectedCardIndex ==
                                                      index,
                                                  index: index,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Float된 노란색 알림바 (최상단 레이어)
            Positioned(
              top: 210 * scale,
              left: 20 * scale,
              right: 20 * scale,
              child: Container(
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 207, 0, 1),
                  borderRadius: BorderRadius.circular(40 * scale),
                  border: Border.all(color: Colors.black),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30 * scale),
                    Expanded(
                      child: Center(
                        child:
                            (objectData.isEmpty)
                                ? Text(
                                  '대화기록이 없어요. 모멘티를 깨워보세요!',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13 * scale,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                                : RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13 * scale,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: lastChattedObjectName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '와 마지막으로 대화했어요.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (objectData.isEmpty) return;
                        final lastObject = objectData.reduce((a, b) {
                          int aMinutes = _parseDurationToMinutes(a.duration);
                          int bMinutes = _parseDurationToMinutes(b.duration);
                          return aMinutes < bMinutes ? a : b;
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create:
                                      (_) => ChatProvider(
                                        uuid: lastObject.uuid,
                                        characterName: lastObject.title,
                                        characterHandle: lastObject.location,
                                        personalityTags:
                                            lastObject.personalityTags ??
                                            ['기본값'],
                                        greeting:
                                            lastObject.greeting ?? '기본 인사말',
                                      ),
                                  child: ChatTextScreen(),
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 54 * scale,
                        height: 54 * scale,
                        margin: EdgeInsets.only(right: 1 * scale),
                        child:
                            (objectData.isEmpty)
                                ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/ui_assets/btn_quickchat.png',
                                      width: 54 * scale,
                                      height: 54 * scale,
                                      fit: BoxFit.contain,
                                    ),
                                    Icon(
                                      Icons.north_east,
                                      color: Colors.black,
                                      size: 20 * scale,
                                    ),
                                  ],
                                )
                                : (_notificationIconRotation != null)
                                ? AnimatedBuilder(
                                  animation: _notificationIconRotation!,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _notificationIconRotation!.value,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/ui_assets/btn_quickchat.png',
                                            width: 54 * scale,
                                            height: 54 * scale,
                                            fit: BoxFit.contain,
                                          ),
                                          Icon(
                                            Icons.north_east,
                                            color: Colors.black,
                                            size: 20 * scale,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                                : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/ui_assets/btn_quickchat.png',
                                      width: 54 * scale,
                                      height: 54 * scale,
                                      fit: BoxFit.contain,
                                    ),
                                    Icon(
                                      Icons.north_east,
                                      color: Colors.black,
                                      size: 20 * scale,
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}년 ${now.month.toString().padLeft(2, '0')}월 ${now.day.toString().padLeft(2, '0')}일';
  }

  // 가장 마지막으로 대화한 사물카드의 이름을 반환
  String get lastChattedObjectName {
    if (objectData.isEmpty) return '';
    // duration이 '숫자 min' 또는 '숫자 h' 형식이라고 가정
    ObjectData? lastObject = objectData.reduce((a, b) {
      int aMinutes = _parseDurationToMinutes(a.duration);
      int bMinutes = _parseDurationToMinutes(b.duration);
      return aMinutes < bMinutes ? a : b;
    });
    return lastObject.title;
  }

  int _parseDurationToMinutes(String duration) {
    // 예: '42 min', '5 min', '2 h', '1 h', '139 min'
    if (duration.contains('min')) {
      return int.tryParse(duration.split(' ')[0]) ?? 99999;
    } else if (duration.contains('h')) {
      return (int.tryParse(duration.split(' ')[0]) ?? 99999) * 60;
    }
    return 99999;
  }

  List<ObjectData> get filteredObjectData {
    if (selectedFilter == "전체") {
      return objectData;
    } else if (selectedFilter == "NEW") {
      return objectData.where((data) => data.isNew == true).toList();
    } else {
      return objectData
          .where((data) => data.location == selectedFilter)
          .toList();
    }
  }

  // 스케일 애니메이션 생성 헬퍼 메소드
  Animation<double> _createScaleAnimation(
    AnimationController controller,
    double startValue,
  ) {
    return Tween<double>(begin: startValue, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(0.15, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  void _updateIconAnimation() {
    if (objectData.isNotEmpty) {
      if (_notificationIconController == null) {
        _notificationIconController = AnimationController(
          duration: const Duration(seconds: 9),
          vsync: this,
        )..repeat();
        _notificationIconRotation = Tween<double>(
          begin: 0,
          end: 2 * 3.141592,
        ).animate(
          CurvedAnimation(
            parent: _notificationIconController!,
            curve: Curves.linear,
          ),
        );
      }
    } else {
      _notificationIconController?.stop();
      _notificationIconController?.reset();
      _notificationIconRotation = null;
    }
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28 * scale,
        margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
        padding: EdgeInsets.symmetric(
          horizontal: 13 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(24 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 11 * scale, color: Colors.black),
              SizedBox(width: 6 * scale),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 12 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectCard extends StatelessWidget {
  final ObjectData data;
  final double scale;
  final bool isSelected;
  final int index;

  const ObjectCard({
    super.key,
    required this.data,
    this.scale = 1.0,
    this.isSelected = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final maskPath = 'assets/ui_assets/cardShape_${(index % 3) + 1}.png';

    return SizedBox(
      width: 130 * scale,
      height: 220 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130 * scale,
            height: 130 * scale,
            child: MaskedImage(
              image: AssetImage(data.imageUrl!),
              mask: AssetImage(maskPath),
              width: 130 * scale,
              height: 130 * scale,
            ),
          ),

          SizedBox(height: 12 * scale),

          // Location
          Text(
            data.location,
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12 * scale,
              height: 1.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 2 * scale),

          // Title and NEW badge
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14 * scale,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.isNew) ...[
                SizedBox(width: 8 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 207, 0, 1),
                    borderRadius: BorderRadius.circular(2 * scale),
                    border: Border.all(
                      color: Color(0xFFE0E0E0),
                      width: 0.4 * scale,
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 6 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 2 * scale),

          // Duration
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${data.duration.split(' ')[0]} ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: data.duration.split(' ')[1],
                  style: TextStyle(color: Colors.black, fontSize: 12 * scale),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class MaskedImage extends StatefulWidget {
  final ImageProvider image;
  final ImageProvider mask;
  final double width;
  final double height;

  const MaskedImage({
    super.key,
    required this.image,
    required this.mask,
    this.width = 130,
    this.height = 130,
  });

  @override
  State<MaskedImage> createState() => _MaskedImageState();
}

class _MaskedImageState extends State<MaskedImage> {
  ui.Image? maskImage;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  Future<void> _loadMask() async {
    final completer = Completer<ui.Image>();
    final stream = widget.mask.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      completer.complete(info.image);
    });
    stream.addListener(listener);
    final image = await completer.future;
    stream.removeListener(listener);

    setState(() {
      maskImage = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (maskImage == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Container(color: Colors.grey[200]),
      );
    }
    // 마스크 이미지를 카드 크기에 맞게 스케일링
    final double scaleX = widget.width / maskImage!.width;
    final double scaleY = widget.height / maskImage!.height;
    final Matrix4 matrix = Matrix4.identity()..scale(scaleX, scaleY);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return ImageShader(
            maskImage!,
            TileMode.clamp,
            TileMode.clamp,
            matrix.storage,
          );
        },
        blendMode: BlendMode.dstIn,
        child: Image(
          image: widget.image,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Create a rounded diamond-like shape
    double width = size.width;
    double height = size.height;

    path.moveTo(width * 0.5, 0);
    path.quadraticBezierTo(width * 0.85, height * 0.15, width, height * 0.3);
    path.quadraticBezierTo(width * 0.85, height * 0.5, width, height * 0.7);
    path.quadraticBezierTo(width * 0.85, height * 0.85, width * 0.5, height);
    path.quadraticBezierTo(width * 0.15, height * 0.85, 0, height * 0.7);
    path.quadraticBezierTo(width * 0.15, height * 0.5, 0, height * 0.3);
    path.quadraticBezierTo(width * 0.15, height * 0.15, width * 0.5, 0);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MorphingEllipseClipper extends CustomClipper<Path> {
  final double morphValue;

  MorphingEllipseClipper(this.morphValue);

  @override
  Path getClip(Size size) {
    Path path = Path();

    double width = size.width;
    double height = size.height;
    double centerX = width / 2;
    double centerY = height / 2;

    // morphValue에 따라 타원의 비율 변경
    double radiusX = (width / 2) * morphValue;
    double radiusY = height / 2;

    // 타원 경로 생성
    path.addOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radiusX * 2,
        height: radiusY * 2,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class ObjectData {
  final String title;
  final String location;
  final String duration;
  final String? imageUrl;
  final bool isNew;
  final String uuid;
  final String uid;
  final String? greeting;
  final List<String>? personalityTags;

  ObjectData({
    required this.title,
    required this.location,
    required this.duration,
    this.imageUrl,
    this.isNew = false,
    required this.uuid,
    required this.uid,
    this.greeting,
    this.personalityTags,
  });

  factory ObjectData.fromMap(Map<String, dynamic> map) {
    final DateTime lastInteraction = DateTime.parse(
      map['lastInteraction'] ?? DateTime.now().toIso8601String(),
    );
    final Duration difference = DateTime.now().difference(lastInteraction);

    String duration;
    if (difference.inHours > 24) {
      duration = '${difference.inDays} d';
    } else if (difference.inMinutes > 60) {
      duration = '${difference.inHours} h';
    } else {
      duration = '${difference.inMinutes} min';
    }

    return ObjectData(
      uuid: map['uuid'] ?? '',
      uid: map['uid'] ?? '',
      title: map['name'] ?? '알 수 없는 사물',
      location: map['location'] ?? '위치 없음',
      duration: duration,
      imageUrl: map['imageUrl'] ?? 'assets/testImg_1.png',
      isNew: difference.inHours < 24,
      greeting: map['greeting'],
      personalityTags: (map['personalityTags'] as List?)?.cast<String>(),
    );
  }
}
