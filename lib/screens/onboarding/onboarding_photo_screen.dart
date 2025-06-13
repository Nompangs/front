import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'dart:io';
import 'dart:async';

/// 온보딩 사물 사진 촬영 화면
/// onboarding_purpose_screen.dart의 디자인 패턴을 따라 재구현
class OnboardingPhotoScreen extends StatefulWidget {
  const OnboardingPhotoScreen({super.key});

  @override
  State<OnboardingPhotoScreen> createState() => _OnboardingPhotoScreenState();
}

class _OnboardingPhotoScreenState extends State<OnboardingPhotoScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _capturedImagePath;
  final ImagePicker _imagePicker = ImagePicker();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(_cameras.first, ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showCameraPermissionDialog();
      return;
    }

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
        _validationError = null;
      });
    } catch (e) {
      print('사진 촬영 실패: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _capturedImagePath = image.path;
          _validationError = null;
        });
      }
    } catch (e) {
      print('갤러리에서 선택 실패: $e');
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      barrierColor: const Color(0x4D000000),
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(40),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(25)),
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '카메라 권한 허용',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'A dialog is a type of modal window that appears in front of app content to provide critical information, or prompt for a decision to be made.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                  topRight: Radius.zero,
                                  bottomRight: Radius.zero,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '허용하지 않음',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _initializeCamera();
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDAB7FA).withOpacity(0.7),
                                border: Border.all(
                                  color: const Color(
                                    0xFFDAB7FA,
                                  ).withOpacity(0.7),
                                  width: 1,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.zero,
                                  bottomLeft: Radius.zero,
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '허용',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
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
    );
  }

  void _proceedToNext() {
    if (_capturedImagePath != null) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);

      // 디버그 정보 출력
      print('📸 Photo Screen Debug - Before setting photo:');
      print('  - UserInput: ${provider.state.userInput}');
      print('  - Purpose: ${provider.state.purpose}');
      print('  - HumorStyle: ${provider.state.humorStyle}');
      print('  - CapturedImagePath: $_capturedImagePath');

      provider.setPhotoPath(_capturedImagePath!);

      print('📸 Photo Screen Debug - After setting photo:');
      print('  - PhotoPath: ${provider.state.photoPath}');
      print('  - Navigating to generation screen...');

      Navigator.pushNamed(context, '/onboarding/generation');
    } else {
      setState(() {
        _validationError = '사진을 선택해주세요!';
      });
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImagePath = null;
      _validationError = null;
    });
  }

  void _shakeToWakeUp() {
    // 단순히 UI용 버튼 - 실제 기능 없음
    print('흔들어 깨우기 버튼 클릭됨 (기능 없음)');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따른 반응형 높이 계산
    final yellowHeight = screenHeight * 0.5; // 노란색 섹션 높이 더 크게

    return Scaffold(
      backgroundColor: Colors.white, // 기본 배경만 흰색으로 변경
      resizeToAvoidBottomInset: true,
      // AppBar - onboarding_purpose_screen.dart와 동일 (색상 유지)
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E9), // 앱바 색상 유지
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: const Text(
              '건너뛰기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 아이보리 섹션 (제목) - 색상 유지
            Container(
              width: double.infinity,
              color: const Color(0xFFFDF7E9), // 섹션 색상 유지
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.1,
                32,
                screenWidth * 0.05,
                32, // 하단 패딩 늘려서 노란색 섹션과 여백 추가
              ),
              child: const Text(
                '사진을 찍으면\n내가 깨어날 수 있어.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.5,
                ),
              ),
            ),

            // 노란색 섹션 (이미지 영역) - 색상 유지
            Container(
              width: double.infinity,
              height: yellowHeight.clamp(350.0, 450.0), // 높이 더 크게
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F), // 노란색 섹션 색상 유지
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.1,
                  40, // 상단 패딩 늘리기
                  screenWidth * 0.1,
                  40, // 하단 패딩 늘리기
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // 날짜 표시 (폴라로이드 위쪽)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '탄생일 ${DateTime.now().year} - ${DateTime.now().month.toString().padLeft(2, '0')} - ${DateTime.now().day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: screenWidth * 0.88, // 폴라로이드 더 크게 (버튼과 시작지점 맞춤)
                          height: screenWidth * 1.0, // 폴라로이드 높이
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              0,
                            ), // 완전히 각진 폴라로이드
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.3,
                                ), // 그림자 더 진하게
                                offset: const Offset(0, 6),
                                blurRadius: 8, // 그림자가 덜 퍼지게
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  0.1,
                                ), // 추가 그림자로 입체감
                                offset: const Offset(0, 2),
                                blurRadius: 4, // 더 선명한 그림자
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12, // 좌 (테두리 더 얇게)
                              12, // 상 (테두리 더 얇게)
                              12, // 우 (테두리 더 얇게)
                              40, // 하 (폴라로이드 특유의 넓은 하단 여백)
                            ),
                            child: Column(
                              children: [
                                // 이미지 영역 (정사각형)
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          _capturedImagePath != null
                                              ? Colors.transparent
                                              : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(
                                        0,
                                      ), // 이미지 영역도 각지게
                                    ),
                                    child:
                                        _capturedImagePath != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    0,
                                                  ), // 이미지도 각지게
                                              child: Image.file(
                                                File(_capturedImagePath!),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            )
                                            : _isCameraInitialized &&
                                                _controller != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    0,
                                                  ), // 카메라 프리뷰도 각지게
                                              child: AspectRatio(
                                                aspectRatio:
                                                    _controller!
                                                        .value
                                                        .aspectRatio,
                                                child: OverflowBox(
                                                  alignment: Alignment.center,
                                                  child: FittedBox(
                                                    fit: BoxFit.cover,
                                                    child: SizedBox(
                                                      width:
                                                          _controller!
                                                              .value
                                                              .previewSize!
                                                              .height,
                                                      height:
                                                          _controller!
                                                              .value
                                                              .previewSize!
                                                              .width,
                                                      child: CameraPreview(
                                                        _controller!,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      0,
                                                    ), // 플레이스홀더도 각지게
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.camera_alt,
                                                      size: 40,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '카메라 활성화',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Pretendard',
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                                // 폴라로이드 하단 여백 (빈 공간)
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 오류 메시지
            if (_validationError != null)
              Container(
                width: double.infinity,
                color: Colors.white, // 하단 배경은 흰색
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 하단 흰색 배경
            Container(
              width: double.infinity,
              color: Colors.white, // 하단 배경은 흰색
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                32, // 상단 패딩 늘리기
                screenWidth * 0.06,
                56, // 하단 패딩 늘리기
              ),
              child: Column(
                children: [
                  // 사진 촬영 전: 이미지 업로드 + 카메라 촬영 버튼
                  // 사진 촬영 후: 흔들어 깨우기(기능없음) + 다시 찍기/다음 버튼
                  if (_capturedImagePath == null) ...[
                    // 이미지 업로드(반원) + 카메라 촬영(네모) 버튼 - 양쪽 대칭
                    Row(
                      children: [
                        // 이미지 업로드 버튼 (반원형 - 왼쪽)
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),
                                bottomLeft: Radius.circular(28),
                              ),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _pickFromGallery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    bottomLeft: Radius.circular(28),
                                  ),
                                ),
                              ),
                              child: const Text(
                                '이미지 업로드',
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

                        const SizedBox(width: 3), // 버튼 사이 간격 추가
                        // 카메라 촬영 버튼 (네모형 - 오른쪽)
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F), // 노란색 버튼
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(28), // 반원형으로 대칭
                                bottomRight: Radius.circular(28), // 반원형으로 대칭
                              ),
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _takePicture,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD54F),
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(28), // 반원형으로 대칭
                                    bottomRight: Radius.circular(
                                      28,
                                    ), // 반원형으로 대칭
                                  ),
                                ),
                              ),
                              child: const Text(
                                '카메라 촬영',
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
                      ],
                    ),
                  ] else ...[
                    // 사진 촬영 후: 흔들어 깨우기 버튼만 표시 (다시찍기, 다음 버튼 제거)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white, // 노란색 → 흰색으로 변경
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // 흔들어 깨우기 기능과 함께 다음 단계로 이동
                          _shakeToWakeUp();
                          _proceedToNext();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // 노란색 → 흰색으로 변경
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '흔들어 깨우기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
