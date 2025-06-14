import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:nompangs/services/character_manager.dart';
import 'package:nompangs/models/personality_profile.dart';
import 'package:nompangs/services/ai_personality_service.dart';
import 'dart:math';

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
  late Animation<double> _celebrationAnimation;
  late Animation<double> _bounceAnimation;
  final GlobalKey _qrKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;
  String? _qrUuid;
  bool _creatingQr = false;

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
      final provider = context.read<OnboardingProvider>();
      final profile = provider.personalityProfile;

      if (profile != null) {
        // 프로필이 있으면 QR 생성을 바로 시작합니다.
        _createQrProfile(profile);
      } else {
        // 만약 프로필이 없다면 오류 상황입니다.
        debugPrint('🚨 완료 화면 오류: PersonalityProfile이 null입니다');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류: 페르소나 정보를 불러올 수 없습니다. 이전 화면으로 돌아가 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createQrProfile(PersonalityProfile profile) async {
    if (_creatingQr || !mounted) return;

    setState(() {
      _creatingQr = true;
    });

    final qrStartTime = DateTime.now();
    debugPrint('🚀 QR 프로필 생성 시작');

    try {
      debugPrint('🔍 QR 생성용 프로필 데이터 확인:');
      debugPrint('   - AI 프로필 이름: ${profile.aiPersonalityProfile?.name}');
      debugPrint('   - 객체 타입: ${profile.aiPersonalityProfile?.objectType}');
      debugPrint('   - 매력적 결함: ${profile.attractiveFlaws.length}개');
      debugPrint('   - 모순적 특성: ${profile.contradictions.length}개');
      debugPrint('   - 성격 변수: ${profile.personalityVariables.length}개');

      // 프로필 직렬화 시간 측정
      final serializationStartTime = DateTime.now();
      final profileMap = profile.toMap();
      final serializationEndTime = DateTime.now();
      final serializationDuration =
          serializationEndTime
              .difference(serializationStartTime)
              .inMilliseconds;
      debugPrint('📦 프로필 직렬화 완료 (${serializationDuration}ms)');

      // 서버 요청 시간 측정
      final requestStartTime = DateTime.now();
      final result = await CharacterManager.saveCharacterForQR({
        'personalityProfile': profileMap,
      });
      final requestEndTime = DateTime.now();
      final requestDuration =
          requestEndTime.difference(requestStartTime).inMilliseconds;
      debugPrint('🌐 서버 요청 완료 (${requestDuration}ms)');

      // 서버 응답 구조 검증
      if (result['uuid'] == null) {
        throw const CharacterManagerException(
          'INVALID_RESPONSE',
          'UUID를 받지 못했습니다',
        );
      }

      final uuid = result['uuid'] as String;
      final qrUrl = result['qrUrl'] as String?;
      final version = result['version'] as String?;

      if (uuid.isNotEmpty && qrUrl != null && qrUrl.isNotEmpty) {
        final qrEndTime = DateTime.now();
        final totalDuration = qrEndTime.difference(qrStartTime).inMilliseconds;

        debugPrint('✅ QR 프로필 생성 성공!');
        debugPrint('   - UUID: $uuid');
        debugPrint('   - 버전: $version');
        debugPrint('   - QR Data URL: ${qrUrl.substring(0, 50)}...');
        debugPrint('⚡ QR 생성 성능 요약:');
        debugPrint('   - 직렬화: ${serializationDuration}ms');
        debugPrint('   - 서버 요청: ${requestDuration}ms');
        debugPrint('   - 전체 시간: ${totalDuration}ms');

        if (mounted) {
          setState(() {
            _qrUuid = uuid;
          });
        }
      } else {
        throw CharacterManagerException(
          'QR_GENERATION_FAILED',
          'QR 코드 생성에 실패했습니다: UUID=${uuid.isEmpty ? '없음' : uuid}, QR=${qrUrl?.isEmpty ?? true ? '없음' : '있음'}',
        );
      }
    } on CharacterManagerException catch (e) {
      final qrEndTime = DateTime.now();
      final totalDuration = qrEndTime.difference(qrStartTime).inMilliseconds;

      debugPrint('🚨 CharacterManagerException: ${e.code} - ${e.message}');
      debugPrint('⏱️ 실패까지 소요 시간: ${totalDuration}ms');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(e.userFriendlyMessage)),
              ],
            ),
            backgroundColor: _getErrorColor(e.code),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '다시 시도',
              textColor: Colors.white,
              onPressed: () => _createQrProfile(profile),
            ),
          ),
        );
      }
    } catch (e) {
      final qrEndTime = DateTime.now();
      final totalDuration = qrEndTime.difference(qrStartTime).inMilliseconds;

      debugPrint('🚨 예상치 못한 QR 생성 오류: $e');
      debugPrint('⏱️ 실패까지 소요 시간: ${totalDuration}ms');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('QR 코드 생성 중 예상치 못한 오류가 발생했습니다')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '다시 시도',
              textColor: Colors.white,
              onPressed: () => _createQrProfile(profile),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _creatingQr = false;
        });
      }
    }
  }

  Color _getErrorColor(String errorCode) {
    switch (errorCode) {
      case 'NETWORK_ERROR':
      case 'CONNECTION_FAILED':
        return Colors.orange;
      case 'TIMEOUT':
        return Colors.amber;
      case 'SERVER_ERROR':
      case 'SERVICE_UNAVAILABLE':
        return Colors.red;
      case 'VALIDATION_FAILED':
        return Colors.purple;
      case 'QR_GENERATION_FAILED':
        return Colors.indigo;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따른 반응형 높이 계산
    final greenHeight = screenHeight * 0.25;
    final pinkHeight = screenHeight * 0.35;
    final blueHeight = screenHeight * 0.4;

    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        // PersonalityProfile을 사용하도록 변경
        final personalityProfile = provider.personalityProfile;

        // PersonalityProfile이 없거나 비어있는 경우 체크
        if (personalityProfile == null ||
            personalityProfile.aiPersonalityProfile == null ||
            personalityProfile.aiPersonalityProfile!.name.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('캐릭터 정보를 불러올 수 없습니다.')),
          );
        }

        // PersonalityProfile에서 Character 정보 추출
        final characterName = personalityProfile.aiPersonalityProfile!.name;
        final characterTraits =
            personalityProfile.aiPersonalityProfile!.personalityTraits;
        final characterGreeting =
            personalityProfile.aiPersonalityProfile!.summary;

        return Scaffold(
          backgroundColor: Colors.white, // 전체 배경은 흰색으로 유지
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 전체 스크롤 가능한 컨테이너 (앱바 아래부터 시작)
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.of(context).padding.top +
                      56, // 시스템 상태바 + 앱바 높이만
                  bottom: 150, // 80에서 150으로 증가하여 버튼과 겹치지 않게
                ),
                controller: _scrollController,
                child: Column(
                  children: [
                    // 분홍+연보라 섹션 (QR 코드) - 가로로 나눔
                    Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          // 왼쪽 분홍 섹션 (65%) - 70%에서 65%로 줄임
                          Expanded(
                            flex: 65, // 70에서 65로 변경
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD8F1), // 분홍색
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.05,
                                  vertical: 15,
                                ),
                                child: Center(
                                  // 전체를 중앙 정렬
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // QR 텍스트
                                      const Text(
                                        'QR을 붙이면\n언제 어디서든 대화할 수 있어요!',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 18, // 16에서 18로 증가
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        maxLines: 2,
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
                                                  fontSize: 12,
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
                                                      BorderRadius.circular(18),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                minimumSize: const Size(0, 36),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            // 다시 Expanded로 변경
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  () => _shareQRCode(
                                                    characterName,
                                                    characterTraits,
                                                  ),
                                              icon: const Icon(
                                                Icons.share,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                '공유하기',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 12,
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
                                                      BorderRadius.circular(18),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                minimumSize: const Size(0, 36),
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
                              onTap: () => _showQRPopup(characterName),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC8A6FF), // 연보라색
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 90, // 80에서 90으로 증가
                                    height: 90, // 80에서 90으로 증가
                                    padding: const EdgeInsets.all(
                                      4,
                                    ), // 8에서 4로 줄임 (여백 축소)
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: RepaintBoundary(
                                      key: _qrKey,
                                      child: QrImageView(
                                        data: _generateQRData(characterName),
                                        version: QrVersions.auto,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 파란색 섹션 (캐릭터 정보) - 아래 라운딩 추가
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C7E8),
                        border: Border.all(color: Colors.black, width: 1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            // 캐릭터 이름과 나이
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      characterName,
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '${DateTime.now().year}년 ${DateTime.now().month}월생',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.work_outline,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        FutureBuilder<String>(
                                          future:
                                              AiPersonalityService.summarizePurpose(
                                                purpose:
                                                    provider.state.purpose ??
                                                    '멘탈지기',
                                                objectType:
                                                    provider
                                                        .state
                                                        .userInput
                                                        ?.objectType ??
                                                    '사물',
                                              ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Text(
                                                '분석중...',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 12,
                                                ),
                                              );
                                            }

                                            final summary =
                                                snapshot.data ??
                                                _summarizePurpose(
                                                  provider.state.purpose ??
                                                      '멘탈지기',
                                                );

                                            return Text(
                                              summary,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontSize: 12,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          provider.state.userInput?.location ??
                                              '우리집 거실',
                                          style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 촬영한 사진과 말풍선 겹치게 배치
                            SizedBox(
                              height: 420, // 전체 높이 증가하여 말풍선 잘림 방지
                              child: Stack(
                                children: [
                                  // 촬영한 사진 표시 (20px 더 증가)
                                  Container(
                                    width: double.infinity,
                                    height: 230, // 210px에서 230px로 20px 증가
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        personalityProfile
                                                    .aiPersonalityProfile !=
                                                null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                File(provider.state.photoPath!),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 230, // 210에서 230으로 변경
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons.access_time,
                                                    size: 60,
                                                    color: Colors.red,
                                                  );
                                                },
                                              ),
                                            )
                                            : const Icon(
                                              Icons.access_time,
                                              size: 60,
                                              color: Colors.red,
                                            ),
                                  ),

                                  // bubble@2x.png 이미지 (말풍선 상단 오른쪽에 위치) - 40px 위로
                                  Positioned(
                                    top: 50, // 90에서 50으로 40px 위로 이동
                                    right: 30,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble@2x.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 버블 배경 이미지 위에 태그와 텍스트 - 20px 위로
                                  Positioned(
                                    top: 90, // 110에서 90으로 20px 위로 이동
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      width: double.infinity,
                                      height: 280, // 높이 더 증가하여 잘림 방지
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/ui_assets/bubble_bg@2x.png',
                                          ),
                                          fit:
                                              BoxFit
                                                  .fitWidth, // 가로 넓이에 맞춰서 비율 유지
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 50,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 성격 태그들 (AI 기반)
                                            FutureBuilder<List<String>>(
                                              future:
                                                  personalityProfile
                                                              .aiPersonalityProfile
                                                              ?.personalityTraits
                                                              .isNotEmpty ==
                                                          true
                                                      ? Future.value([
                                                        personalityProfile
                                                                .aiPersonalityProfile!
                                                                .personalityTraits
                                                                .isNotEmpty
                                                            ? personalityProfile
                                                                .aiPersonalityProfile!
                                                                .personalityTraits
                                                                .first
                                                            : '특별함',
                                                        personalityProfile
                                                                    .aiPersonalityProfile!
                                                                    .personalityTraits
                                                                    .length >=
                                                                2
                                                            ? personalityProfile
                                                                .aiPersonalityProfile!
                                                                .personalityTraits[1]
                                                            : '매력적',
                                                      ])
                                                      : AiPersonalityService.generatePersonalityTags(
                                                        state: provider.state,
                                                        profile:
                                                            personalityProfile,
                                                      ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      _buildPersonalityTag(
                                                        '분석중',
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _buildPersonalityTag(
                                                        '...',
                                                      ),
                                                    ],
                                                  );
                                                }

                                                final tags =
                                                    snapshot.data ??
                                                    ['특별함', '매력적'];
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildPersonalityTag(
                                                      '#${tags.isNotEmpty ? tags[0] : '특별함'}',
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildPersonalityTag(
                                                      '#${tags.length >= 2 ? tags[1] : '매력적'}',
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),

                                            const SizedBox(height: 24),

                                            // 말풍선 텍스트 (버블 배경 위에)
                                            FutureBuilder<String>(
                                              future:
                                                  personalityProfile
                                                              .greeting
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? Future.value(
                                                        personalityProfile
                                                            .greeting!,
                                                      )
                                                      : AiPersonalityService.generateGreeting(
                                                        state: provider.state,
                                                        profile:
                                                            personalityProfile,
                                                      ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text(
                                                    '인사말 생성 중...',
                                                    style: TextStyle(
                                                      fontFamily: 'Pretendard',
                                                      fontSize: 18,
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  );
                                                }

                                                final greeting =
                                                    snapshot.data ??
                                                    personalityProfile
                                                        .aiPersonalityProfile
                                                        ?.summary ??
                                                    '안녕하세요! 만나서 반가워요~';

                                                return Text(
                                                  greeting,
                                                  style: const TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontSize: 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // AI 기반 성격 분석 섹션 (말풍선 밖에 배치)
                            const SizedBox(height: 30),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🎭 성격 분석',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // 매력적 특성
                                  if (personalityProfile
                                      .attractiveFlaws
                                      .isNotEmpty) ...[
                                    const Text(
                                      '✨ 매력적인 특징',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...personalityProfile.attractiveFlaws.map(
                                      (flaw) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '• $flaw',
                                          style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // 모순적 특성
                                  if (personalityProfile
                                      .contradictions
                                      .isNotEmpty) ...[
                                    const Text(
                                      '🎪 복합적인 면',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...personalityProfile.contradictions.map(
                                      (contradiction) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '• $contradiction',
                                          style: const TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 플로팅 대화 시작 버튼 (배경없음)
              Positioned(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/chat/$characterName',
                        arguments: {
                          'characterName': characterName,
                          'characterHandle':
                              '@${characterName}_${DateTime.now().millisecondsSinceEpoch}',
                          'personalityTags': characterTraits,
                          'greeting': characterGreeting,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      '지금 바로 대화해요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                        // 하단에서 클릭 시 하늘색 영역 상단으로 이동 (앱바 바로 아래)
                        _scrollController.animateTo(
                          140.0, // QR 섹션 높이만큼 스크롤하여 하늘색 섹션이 앱바 바로 아래 오도록
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isScrolledToBottom
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
              ),

              // 상단 고정 앱바 (라운딩 처리)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // 시스템 상태바 영역만 연두색
                    Container(
                      height: MediaQuery.of(context).padding.top,
                      width: double.infinity,
                      color: const Color(0xFFC5FF35), // 시스템 상태바만 연두색
                    ),

                    // 앱바 영역 (라운딩된 부분 밖은 투명)
                    Container(
                      height: 56,
                      width: double.infinity,
                      color: Colors.transparent, // 라운딩 밖 영역은 투명
                      child: Stack(
                        children: [
                          // 라운딩된 앱바 배경
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC5FF35), // 앱바만 연두색
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              border: Border(
                                left: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          // 앱바 콘텐츠
                          Row(
                            children: [
                              // 뒤로가기 버튼
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),

                              // 중앙 타이틀
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.notifications,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${characterName}이 깨어났어요!',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 오른쪽 여백 (뒤로가기 버튼과 대칭)
                              const SizedBox(width: 48),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  String _generateQRData(String characterName) {
    // 🎯 간단한 UUID 기반 딥링크 사용
    if (_qrUuid != null) {
      return 'nompangs://character/$_qrUuid';
    }

    // 폴백: 기본 데이터 구조
    final data = {
      'characterId': characterName,
      'name': characterName,
      'objectType': 'personality',
      'createdAt': DateTime.now().toIso8601String(),
    };

    return 'nompangs://character?data=${base64Url.encode(utf8.encode(jsonEncode(data)))}';
  }

  Future<void> _saveQRCode() async {
    if (_qrUuid == null) return;
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

  Future<void> _shareQRCode(String characterName, List<String> traits) async {
    if (_qrUuid == null) return;
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
            '${characterName}와 함께하세요! 놈팽쓰 QR 코드입니다 🎉\n\nQR을 스캔하면 ${characterName}과 대화할 수 있어요!',
        subject: '놈팽쓰 친구 공유 - ${characterName}',
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
        final qrData = _generateQRData(characterName);
        await Share.share(
          '${characterName}와 함께하세요! 놈팽쓰 QR: $qrData',
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

  // QR 코드 팝업 표시
  void _showQRPopup(String characterName) {
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
                          data: _generateQRData(characterName),
                          version: QrVersions.auto,
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

  String _getPersonalityTag1(
    OnboardingState state,
    PersonalityProfile profile,
  ) {
    // PersonalityProfile의 personalityTraits가 있으면 첫 번째 사용
    if (profile.aiPersonalityProfile?.personalityTraits.isNotEmpty == true) {
      final traits = profile.aiPersonalityProfile!.personalityTraits;
      return '#${traits.first}';
    }

    // 없으면 기존 로직: 내향성 기반 (수줍음 ↔ 활발함)
    final introversion = state.introversion ?? 5;
    if (introversion <= 3) {
      return '#수줍음';
    } else if (introversion >= 7) {
      return '#활발함';
    } else {
      return '#적당함';
    }
  }

  String _getPersonalityTag2(
    OnboardingState state,
    PersonalityProfile profile,
  ) {
    // PersonalityProfile의 personalityTraits가 2개 이상 있으면 두 번째 사용
    if (profile.aiPersonalityProfile?.personalityTraits != null &&
        profile.aiPersonalityProfile!.personalityTraits.length >= 2) {
      final traits = profile.aiPersonalityProfile!.personalityTraits;
      return '#${traits[1]}';
    }

    // 없으면 기존 로직: 감정표현과 유능함 조합 기반
    final warmth = state.warmth ?? 5;
    final competence = state.competence ?? 5;

    if (warmth >= 7 && competence >= 7) {
      return '#따뜻하고능숙';
    } else if (warmth >= 7) {
      return '#따뜻함';
    } else if (competence >= 7) {
      return '#능숙함';
    } else if (warmth <= 3 && competence <= 3) {
      return '#차갑고서툰';
    } else if (warmth <= 3) {
      return '#차가움';
    } else if (competence <= 3) {
      return '#서툰';
    } else {
      return '#균형잡힌';
    }
  }

  // 백엔드 스타일의 성격 데이터 생성 (실제로는 API에서 받아올 데이터)
  Map<String, dynamic> _generatePersonalityData(OnboardingState state) {
    // 사용자가 설정한 값을 기반으로 백엔드 스타일 성격특성 생성
    final warmth = (state.warmth ?? 5).toDouble();
    final competence = (state.competence ?? 5).toDouble();
    final introversion = (state.introversion ?? 5).toDouble();

    return {
      "성격특성": {
        "온기": warmth * 10, // 1-10을 10-100으로 변환
        "능력": competence * 10,
        "외향성": (11 - introversion) * 10, // introversion 역변환
        "유머감각": 75.0, // 백엔드에서는 기본적으로 높음
        "창의성": 60 + (warmth * 4), // warmth 기반
        "신뢰성": 50 + (competence * 5), // competence 기반
      },
      "유머스타일": state.humorStyle.isNotEmpty ? state.humorStyle : "따뜻한 유머러스",
      "매력적결함": ["가끔 털이 엉킬까봐 걱정돼 :(", "완벽하게 정리되지 않으면 불안함", "친구들과 함께 있을 때 더 빛남"],
    };
  }

  String _summarizePurpose(String purpose) {
    if (purpose.length <= 10) {
      return purpose;
    }

    // 핵심 키워드 추출 및 요약
    final keywords = {
      '운동': '운동지기',
      '헬스': '헬스지기',
      '다이어트': '다이어트',
      '공부': '공부지기',
      '학습': '학습지기',
      '시험': '시험지기',
      '위로': '위로지기',
      '상담': '상담지기',
      '대화': '대화지기',
      '친구': '친구',
      '알람': '알람지기',
      '깨워': '알람지기',
      '일정': '일정지기',
      '관리': '관리지기',
      '채찍질': '채찍지기',
      '닥달': '닥달지기',
      '응원': '응원지기',
      '격려': '격려지기',
      '멘탈': '멘탈지기',
      '감정': '감정지기',
      '스트레스': '힐링지기',
      '힐링': '힐링지기',
      '음악': '음악지기',
      '독서': '독서지기',
      '요리': '요리지기',
      '청소': '청소지기',
    };

    // 키워드 매칭
    for (final entry in keywords.entries) {
      if (purpose.contains(entry.key)) {
        return entry.value;
      }
    }

    // 키워드가 없으면 첫 10글자 + ...
    return purpose.substring(0, 7) + '...';
  }
}
