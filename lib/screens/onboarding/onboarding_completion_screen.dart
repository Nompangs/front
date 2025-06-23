import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/models/onboarding_state.dart';
import 'package:nompangs/widgets/personality_chart.dart';
import 'package:nompangs/services/personality_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nompangs/services/api_service.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nompangs/widgets/masked_image.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class OnboardingCompletionScreen extends StatefulWidget {
  const OnboardingCompletionScreen({super.key});

  @override
  State<OnboardingCompletionScreen> createState() =>
      _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _bounceController;
  late AnimationController _floatingAnimationController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  final GlobalKey _qrKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;
  String? _qrImageData;
  final ApiService _apiService = ApiService();
  final PersonalityService _personalityService = PersonalityService();
  String? _qrCodeUrl;
  bool _isLoading = true;
  String _message = "최종 페르소나를 완성하고 있어요...";
  bool _isProfileReady = false;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // 스크롤 리스너 추가
    _scrollController.addListener(_onScroll);

    // 축하 애니메이션 시작
    _celebrationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _bounceController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finalizeAndSaveProfile();
      _performAutoScroll();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = maxScroll * 0.9; // 90% 스크롤 시 하단으로 간주

      final isAtBottom = currentScroll >= threshold;
      if (isAtBottom != _isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = isAtBottom;
        });
      }
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _bounceController.dispose();
    _floatingAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _performAutoScroll() async {
    // 프로필이 로드되고 스크롤 컨트롤러가 준비될 때까지 대기
    while (!_isProfileReady ||
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent == 0.0) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 시작 위치로 즉시 이동
    _scrollController.jumpTo(129.0);

    // 잠시 후, 맨 위로 스크롤 애니메이션 시작
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finalizeAndSaveProfile() async {
    final provider = context.read<OnboardingProvider>();
    if (provider.draft == null) {
      // 비정상적인 접근 처리
      setState(() {
        _isLoading = false;
        _message = "오류: AI 초안 데이터가 없습니다. 처음부터 다시 시도해주세요.";
      });
      return;
    }

    try {
      // 1. 최종 프로필 생성
      setState(() => _message = "당신의 선택을 페르소나에 반영하는 중...");
      final finalProfile = await _personalityService.finalizeUserProfile(
        draft: provider.draft!,
        finalState: provider.state,
      );

      // 2. 생성된 프로필을 Provider에 저장하여 UI를 업데이트
      final profileMap = finalProfile.toMap();
      print('\n[프로필 정제 전] 원본 데이터:');
      print('----------------------------------------');
      profileMap.forEach((key, value) {
        print(' [33m$key:  [0m${value.runtimeType} = $value');
      });
      print('----------------------------------------\n');

      // Base64 인코딩 및 photoBase64 저장 코드 제거
      // photoPath(로컬 파일 경로)는 profileMap에 그대로 남겨둠

      // Firestore 호환을 위한 데이터 정제
      Map<String, dynamic> sanitizedProfile = {};
      profileMap.forEach((key, value) {
        if (value != null) {
          if (value is Map) {
            // 중첩된 Map을 정제
            Map<String, dynamic> sanitizedMap = {};
            value.forEach((k, v) {
              if (v != null && v is! Function) {
                sanitizedMap[k.toString()] = v;
              }
            });
            sanitizedProfile[key] = sanitizedMap;
          } else if (value is List) {
            // List 내부의 객체들도 정제
            sanitizedProfile[key] =
                value.where((item) => item != null).map((item) {
                  if (item is Map) {
                    return Map.fromEntries(
                      item.entries.where(
                        (e) => e.value != null && e.value is! Function,
                      ),
                    );
                  }
                  return item;
                }).toList();
          } else if (value is! Function) {
            sanitizedProfile[key] = value;
          }
        }
      });

      print('\n[프로필 정제 후] Firestore 저장 데이터:');
      print('----------------------------------------');
      sanitizedProfile.forEach((key, value) {
        print('$key:  [36m${value.runtimeType}\u001b[0m = $value');
      });
      print('----------------------------------------\n');

      // 4. 서버에 저장하고 ID와 QR코드 받기
      setState(() => _message = "서버에 안전하게 저장하는 중...");
      final result = await _apiService.createQrProfile(
        generatedProfile: profileMap, // 가공된 맵 전달
        userInput: provider.getUserInputAsMap(),
      );

      // 5. 서버에서 받은 uuid를 profile에 주입하고 Provider 상태 업데이트
      final serverUuid = result['uuid'] as String?;
      final profileWithUuid = finalProfile.copyWith(uuid: serverUuid);
      provider.setPersonalityProfile(profileWithUuid);

      debugPrint('\n[API 응답] 성공:');
      debugPrint('----------------------------------------');
      debugPrint('UUID: ${result['uuid']}');
      debugPrint('QR URL: ${result['qrUrl']}');
      debugPrint('----------------------------------------\n');

      setState(() {
        _qrImageData = result['qrUrl'] as String?;
        _isLoading = false;
        _message = "페르소나 생성 완료!";
        _isProfileReady = true;
      });
    } catch (e) {
      debugPrint('\n[API 오류]:');
      debugPrint('----------------------------------------');
      debugPrint(e.toString());
      debugPrint('----------------------------------------\n');

      setState(() {
        _isLoading = false;
        _message = "오류가 발생했어요: ${e.toString()}";
      });
    }
  }

  // Base64 데이터를 이미지 바이트로 변환하는 헬퍼 함수
  Uint8List? _decodeQrImage(String? base64String) {
    if (base64String == null || !base64String.startsWith('data:image')) {
      return null;
    }
    // "data:image/png;base64," 부분을 제거하고 순수 base64 데이터만 추출
    final pureBase64 = base64String.substring(base64String.indexOf(',') + 1);
    try {
      return base64Decode(pureBase64);
    } catch (e) {
      print("Base64 디코딩 실패: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        final characterName =
            provider.personalityProfile.aiPersonalityProfile?.name ?? '페르소나';
        final character = provider.personalityProfile;
        final qrBytes = _decodeQrImage(_qrImageData);

        if (_isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(_message),
                ],
              ),
            ),
          );
        }

        if (character == null) {
          return Scaffold(
            body: Center(child: Text(_message)), // 에러 메시지 표시
          );
        }

        final appBar = PreferredSize(
          preferredSize: const Size.fromHeight(90.0),
          child: Container(
            height: 90.0,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(119, 206, 255, 1),
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications,
                    size: 18,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${character.aiPersonalityProfile?.name.isNotEmpty == true ? character.aiPersonalityProfile!.name : '털찐말랑이'}가 깨어났어요!',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // 아이콘 색상 (어둡게)
          ),
          child: Scaffold(
            backgroundColor: Colors.white, // 전체 배경은 흰색으로 유지
            extendBodyBehindAppBar: true,
            appBar: appBar,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                // 전체 스크롤 가능한 컨테이너 (앱바 아래부터 시작)
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 90, bottom: 0),
                  child: Column(
                    children: [
                      // 분홍+연보라 섹션 (QR 코드) - 가로로 나눔
                      Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          children: [
                            // 왼쪽 분홍 섹션 (65%) - 70%에서 65%로 줄임
                            Expanded(
                              flex: 70, // 70에서 65로 변경
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD8F1), // 분홍색
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(39),
                                    bottomLeft: Radius.circular(39),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.08,
                                    vertical: 15,
                                  ),
                                  child: Center(
                                    // 전체를 중앙 정렬
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // QR 텍스트
                                        Transform.translate(
                                          offset: const Offset(0, 3),
                                          child: const Text(
                                            'QR을 붙이면\n언제 어디서든 대화할 수 있어요!',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ), // 텍스트와 버튼 사이 아주 살짝 띄움
                                        // 저장하기, 공유하기 버튼
                                        Row(
                                          children: [
                                            Expanded(
                                              // 다시 Expanded로 변경
                                              child: ElevatedButton.icon(
                                                onPressed: () => _saveQRCode(),
                                                icon: const Icon(
                                                  Icons.download,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  '저장하기',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF6750A4,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              // 다시 Expanded로 변경
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    () =>
                                                        _shareQRCode(character),
                                                icon: const Icon(
                                                  Icons.share,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                label: const Text(
                                                  '공유하기',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF6750A4,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 오른쪽 연보라 섹션 (35%) - QR 코드 - 30%에서 35%로 증가
                            Expanded(
                              flex: 35, // 30에서 35로 변경
                              child: GestureDetector(
                                onTap: () => _showQRPopup(character),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDBB7FA), // 연보라색
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(39),
                                      bottomRight: Radius.circular(39),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      padding: const EdgeInsets.all(0),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      child:
                                          qrBytes != null
                                              ? RepaintBoundary(
                                                key: _qrKey,
                                                child: Image.memory(
                                                  qrBytes,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                              : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 파란색 섹션 - 1px 위로 이동
                      Transform.translate(
                        offset: const Offset(0, -1),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF7E9),
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                              vertical: 24,
                            ),
                            child: Column(
                              children: [
                                // 캐릭터 이름과 나이
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          characterName,
                                          style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '${DateTime.now().year}년 ${DateTime.now().month}월생',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 15,
                                            color: const Color.fromARGB(
                                              255,
                                              0,
                                              0,
                                              0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              character
                                                      .aiPersonalityProfile
                                                      ?.objectType ??
                                                  '멘탈지기',
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              provider.state.location,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                // 촬영한 사진과 말풍선 겹치게 배치
                                SizedBox(
                                  height: 480, // 420에서 480으로 증가하여 말풍선 잘림 방지
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      // 촬영한 사진 표시 (마스크 이미지 적용 및 중앙 정렬)
                                      Container(
                                        width:
                                            screenWidth * 0.8, // 화면 가로 비율의 80%
                                        height:
                                            screenWidth * 0.8, // 화면 가로 비율의 80%
                                        child:
                                            character.photoPath != null
                                                ? MaskedImage(
                                                  image: FileImage(
                                                    File(character.photoPath!),
                                                  ),
                                                  mask: const AssetImage(
                                                    'assets/ui_assets/cardShape_1.png',
                                                  ),
                                                  stroke: const AssetImage(
                                                    'assets/ui_assets/cardShape_stroke_1.png',
                                                  ),
                                                  width: screenWidth * 0.8,
                                                  height: screenWidth * 0.8,
                                                )
                                                : Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.access_time,
                                                    size: 60,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                      ),

                                      // 버블 배경 이미지 위에 태그와 텍스트
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 170,
                                        ),
                                        child: AnimatedBuilder(
                                          animation:
                                              _floatingAnimationController,
                                          builder: (context, child) {
                                            final angle =
                                                _floatingAnimationController
                                                    .value *
                                                2 *
                                                math.pi;
                                            final offset = Offset(
                                              math.cos(angle) * 5,
                                              math.sin(angle) * 5,
                                            );
                                            return Transform.translate(
                                              offset: offset,
                                              child: child,
                                            );
                                          },
                                          child: RepaintBoundary(
                                            child: Container(
                                              width:
                                                  screenWidth *
                                                  0.8, // 화면 가로 너비의 80%로 설정
                                              height: 320, // 높이는 유지, 필요시 조정
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                    'assets/ui_assets/speechBubble.png',
                                                  ),
                                                  fit:
                                                      BoxFit
                                                          .contain, // 이미지가 잘리지 않고 비율에 맞게 포함되도록 contain으로 변경
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 51,
                                                      vertical: 40,
                                                    ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // 성격 태그들 (성격 슬라이더 기반)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _buildPersonalityTag(
                                                          _getPersonalityTag1(
                                                            provider.state,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        _buildPersonalityTag(
                                                          _getPersonalityTag2(
                                                            provider.state,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    const SizedBox(height: 12),

                                                    // 말풍선 텍스트 (버블 배경 위에)
                                                    Text(
                                                      character.greeting ??
                                                          '만나서 반가워!',
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Pretendard',
                                                        fontSize: 17,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 1.5,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 사진/말풍선과 성격차트 사이 간격
                                const SizedBox(height: 0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 베이지색 카드 (성격 차트 및 요약) - 1px 위로 이동
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF7E9),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (context) {
                                  return PersonalityChart(
                                    warmth: provider.state!.warmth! * 10,
                                    competence:
                                        provider.state!.competence! * 10,
                                    extroversion:
                                        provider.state!.extroversion! * 10,
                                    creativity: _calculateCreativity(character),
                                    humour: _calculateHumour(character),
                                    reliability: _calculateReliability(
                                      character,
                                    ),
                                    realtimeSettings:
                                        character.realtimeSettings,
                                    attractiveFlaws: character.attractiveFlaws,
                                    contradictions: character.contradictions,
                                    communicationPrompt:
                                        character.communicationPrompt,
                                    coreTraits: character.coreTraits,
                                    personalityDescription:
                                        character.personalityDescription,
                                  );
                                },
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 하단에 고정되는 "지금 바로 대화해요" 버튼
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        _isProfileReady
                            ? () async {
                              final provider =
                                  context.read<OnboardingProvider>();
                              final characterProfile =
                                  provider.personalityProfile.toMap();

                              // 🚨 [수정] Firestore에서 현재 유저의 displayName을 가져와 주입합니다.
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final doc =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .get();
                                characterProfile['userDisplayName'] =
                                    doc.data()?['displayName'] ?? '게스트';
                              } else {
                                characterProfile['userDisplayName'] = '게스트';
                              }

                              characterProfile['personalityTags'] =
                                  provider
                                              .personalityProfile
                                              .aiPersonalityProfile
                                              ?.coreValues
                                              .isNotEmpty ==
                                          true
                                      ? provider
                                          .personalityProfile
                                          .aiPersonalityProfile!
                                          .coreValues
                                      : ['친구'];

                              debugPrint(
                                '✅ [온보딩 진입] ChatProvider로 전달되는 프로필: $characterProfile',
                              );

                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ChangeNotifierProvider(
                                        create:
                                            (_) => ChatProvider(
                                              characterProfile:
                                                  characterProfile,
                                            ),
                                        child: const ChatTextScreen(
                                          showHomeInsteadOfBack: true,
                                        ),
                                      ),
                                ),
                                (route) => false,
                              );
                            }
                            : null,
                    child: const Text(
                      '대화 시작하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 플로팅 스크롤 힌트 화살표 (말풍선 아래 오른쪽 고정 위치)
                Positioned(
                  right: 30,
                  bottom:
                      MediaQuery.of(context).padding.bottom +
                      24 +
                      56 +
                      15, // 버튼 아래 여백 + 버튼 높이 + 15px 위
                  child: GestureDetector(
                    onTap: () {
                      if (_scrollController.hasClients) {
                        if (_isScrolledToBottom) {
                          // 하단에서 클릭 시 사물 카드가 앱바 바로 아래에 오도록 스크롤
                          _scrollController.animateTo(
                            129.0, // QR카드 높이(130) - 겹침(1) = 129
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // 상단에서 클릭 시 하늘색 섹션 끝으로 이동
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white, // opacity 100으로 변경 (0.9에서 1.0으로)
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.0),
                        // boxShadow 제거
                      ),
                      child: Icon(
                        _isScrolledToBottom
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9AC28),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showQRPopup(PersonalityProfile character) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(), // 밖 부분 누르면 사라짐
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {}, // QR 영역 클릭 시 팝업이 닫히지 않도록
                onLongPress: () {
                  Navigator.of(context).pop();
                  _saveQRCode(); // 길게 누르면 저장
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8A6FF), // 연보라색
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: _generateQRData(character),
                          version: QrVersions.auto,
                          size: 100.0,
                          backgroundColor: Colors.white,
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
    );
  }

  String _generateQRData(PersonalityProfile character) {
    if (character.uuid == null) return '';
    final data = {
      'characterId': character.uuid,
      'name': character.aiPersonalityProfile?.name,
      'objectType': character.aiPersonalityProfile?.objectType,
      'greeting': character.greeting,
    };

    return 'nompangs://character?data=${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  Future<void> _saveQRCode() async {
    if (_qrKey.currentContext == null) return;
    try {
      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 갤러리에 저장 - 권한 확인 없이 바로 시도
      try {
        await Gal.putImage(file.path, album: 'Nompangs');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (galError) {
        // Gal 저장 실패 시 권한 요청 후 재시도
        print('Gal 저장 실패, 권한 확인 중: $galError');

        bool hasPermission = false;

        if (Platform.isAndroid) {
          // Android 권한 요청
          var photosStatus = await Permission.photos.request();
          var storageStatus = await Permission.storage.request();
          hasPermission = photosStatus.isGranted || storageStatus.isGranted;

          if (!hasPermission) {
            var manageStatus = await Permission.manageExternalStorage.request();
            hasPermission = manageStatus.isGranted;
          }
        } else if (Platform.isIOS) {
          final status = await Permission.photosAddOnly.request();
          hasPermission = status.isGranted;
        }

        if (hasPermission) {
          // 권한 획득 후 재시도
          await Gal.putImage(file.path, album: 'Nompangs');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ QR 코드가 갤러리에 저장되었습니다!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('저장소 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // 임시 파일 삭제
      await file.delete();
    } catch (e) {
      print('QR 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareQRCode(PersonalityProfile character) async {
    if (_qrKey.currentContext == null) return;
    try {
      // QR 코드 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 임시 파일 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'nompangs_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // 이미지와 함께 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${character.aiPersonalityProfile?.name ?? '내 친구'}와 함께하세요! 놈팽쓰 QR 코드입니다 🎉\n\nQR을 스캔하면 ${character.aiPersonalityProfile?.name ?? '내 친구'}과 대화할 수 있어요!',
        subject: '놈팽쓰 친구 공유 - ${character.aiPersonalityProfile?.name ?? '친구'}',
      );

      // 잠시 후 임시 파일 삭제
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.delete();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ QR 코드가 공유되었습니다!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2), // 2초로 단축
          ),
        );
      }
    } catch (e) {
      print('QR 공유 오류: $e');
      if (mounted) {
        // 실패 시 기본 텍스트 공유
        final qrData = _qrCodeUrl ?? 'QR 데이터 없음';
        await Share.share(
          '${character.aiPersonalityProfile?.name ?? '내 친구'}와 함께하세요! 놈팽쓰 QR: $qrData',
          subject: '놈팽쓰 친구 공유',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 이미지 공유 실패, 텍스트로 공유되었습니다'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2), // 2초로 단축
          ),
        );
      }
    }
  }

  String _getPersonalityTag1(OnboardingState state) {
    // 첫 번째 태그: 외향성 기반 (수줍음 ↔ 활발함)
    final extroversion = state.extroversion ?? 5;
    if (extroversion <= 3) {
      return '수줍음';
    } else if (extroversion >= 7) {
      return '활발함';
    } else {
      return '반쯤활발';
    }
  }

  String _getPersonalityTag2(OnboardingState state) {
    // 두 번째 태그: 감정표현과 유능함 조합 기반
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    if (warmth >= 7 && competence >= 7) {
      return '든든다정';
    } else if (warmth >= 7 && competence >= 4) {
      return '포근러';
    } else if (warmth >= 7 && competence < 4) {
      return '다정허당';
    } else if (warmth >= 4 && competence >= 7) {
      return '능력자';
    } else if (warmth >= 4 && competence >= 4) {
      return '평범러';
    } else if (warmth >= 4 && competence < 4) {
      return '허당';
    } else if (warmth < 4 && competence >= 7) {
      return '시크유능';
    } else if (warmth < 4 && competence >= 4) {
      return '쌀쌀맞은';
    } else {
      return '무심엉성';
    }
  }

  // 백엔드 스타일의 성격 데이터 생성 (실제로는 API에서 받아올 데이터)
  Map<String, dynamic> _generatePersonalityData(OnboardingState state) {
    // 사용자가 설정한 값을 기반으로 백엔드 스타일 성격특성 생성
    final warmth = (state.warmth ?? 5).toDouble();
    final competence = (state.competence ?? 5).toDouble();
    final extroversion = (state.extroversion ?? 5).toDouble();

    return {
      "성격특성": {
        "온기": warmth * 10,
        "능력": competence * 10,
        "외향성": (11 - extroversion) * 10,
        "유머감각": 75.0,
        "창의성": 60 + (warmth * 4),
        "신뢰성": 50 + (competence * 5),
      },
      "유머스타일": state.humorStyle.isNotEmpty ? state.humorStyle : "따뜻한 유머러스",
      "매력적결함": ["가끔 털이 엉킬까봐 걱정돼 :(", "완벽하게 정리되지 않으면 불안해함", "친구들과 함께 있을 때 더 빛남"],
    };
  }

  // AI 생성 지표 계산 함수들
  double _calculateCreativity(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;

    final imagination =
        character!.aiPersonalityProfile!.npsScores['O01_상상력'] ?? 50;
    final creativity =
        character.aiPersonalityProfile!.npsScores['C03_창의성'] ?? 50;
    final curiosity =
        character.aiPersonalityProfile!.npsScores['O02_호기심'] ?? 50;

    return (imagination * 0.4 + creativity * 0.4 + curiosity * 0.2).clamp(
      0.0,
      100.0,
    );
  }

  double _calculateStability(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;

    final anxiety = character!.aiPersonalityProfile!.npsScores['N01_불안성'] ?? 50;
    return (100 - anxiety).toDouble().clamp(0.0, 100.0);
  }

  double _calculateConscientiousness(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;

    final responsibility =
        character!.aiPersonalityProfile!.npsScores['CS01_책임감'] ?? 50;
    final orderliness =
        character.aiPersonalityProfile!.npsScores['CS02_질서성'] ?? 50;

    return (responsibility * 0.6 + orderliness * 0.4).clamp(0.0, 100.0);
  }

  double _calculateHumour(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 75.0;

    final playfulness =
        character!.aiPersonalityProfile!.npsScores['E06_유쾌함'] ?? 75;
    final creativity =
        character.aiPersonalityProfile!.npsScores['C03_창의성'] ?? 50;
    final sociability =
        character.aiPersonalityProfile!.npsScores['E01_사교성'] ?? 50;

    return (playfulness * 0.5 + creativity * 0.3 + sociability * 0.2).clamp(
      0.0,
      100.0,
    );
  }

  double _calculateReliability(PersonalityProfile? character) {
    if (character?.aiPersonalityProfile?.npsScores == null) return 50.0;

    final trustworthiness =
        character!.aiPersonalityProfile!.npsScores['A01_신뢰성'] ?? 50;
    final responsibility =
        character.aiPersonalityProfile!.npsScores['CS01_책임감'] ?? 50;
    final consistency =
        character.aiPersonalityProfile!.npsScores['CS02_질서성'] ?? 50;

    return (trustworthiness * 0.4 + responsibility * 0.4 + consistency * 0.2)
        .clamp(0.0, 100.0);
  }
}
