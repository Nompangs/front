import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    print('[OnboardingPhotoScreen] initState 호출');
    _checkAndInitializeCamera();
  }

  @override
  void dispose() {
    print('[OnboardingPhotoScreen] dispose 호출, 카메라 컨트롤러 해제 시도');
    _controller?.dispose();
    print('[OnboardingPhotoScreen] dispose 완료');
    super.dispose();
  }

  Future<void> _checkAndInitializeCamera() async {
    print('[OnboardingPhotoScreen] 카메라 권한 및 초기화 체크 시작');
    var status = await Permission.camera.status;

    if (status.isGranted) {
      await _initializeCamera();
    } else {
      print('[OnboardingPhotoScreen] 카메라 권한 없음');
      _showCameraPermissionDialog();
    }
  }

  Future<void> _initializeCamera() async {
    print('[OnboardingPhotoScreen] _initializeCamera 호출');
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    try {
      _cameras = await availableCameras();
      print('[OnboardingPhotoScreen] 사용 가능한 카메라: ${_cameras.length}개');

      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        print('[OnboardingPhotoScreen] 카메라 초기화 성공');

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('[OnboardingPhotoScreen] 카메라 초기화 실패: $e');
      _isCameraInitialized = false;
      _controller?.dispose();
      _controller = null;
    }
  }

  Future<void> _takePicture() async {
    print('[OnboardingPhotoScreen] 사진 촬영 시도');

    if (!_isCameraInitialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      print('[OnboardingPhotoScreen] 카메라 미초기화 상태에서 촬영 시도');
      await _checkAndInitializeCamera();
      return;
    }

    try {
      final image = await _controller!.takePicture();
      print('[OnboardingPhotoScreen] 사진 촬영 성공: ${image.path}');
      setState(() {
        _capturedImagePath = image.path;
        _validationError = null;
      });
    } catch (e) {
      print('[OnboardingPhotoScreen] 사진 촬영 실패: $e');
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '사진을 촬영하여 AI 친구를 만들어보세요.\n카메라 접근 권한이 필요합니다.',
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
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final status = await Permission.camera.request();
                            if (status.isGranted) {
                              await _initializeCamera();
                            }
                          },
                          child: const Text('권한 허용'),
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

  Future<void> _proceedToNext() async {
    if (_capturedImagePath != null) {
      try {
        // 1. 영구 저장소 경로를 얻습니다.
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_capturedImagePath!);
        final permanentPath = p.join(directory.path, fileName);

        // 2. 임시 파일을 영구 경로로 복사합니다.
        final originalFile = File(_capturedImagePath!);
        final newFile = await originalFile.copy(permanentPath);

        final provider = Provider.of<OnboardingProvider>(
          context,
          listen: false,
        );

        // 3. 영구 경로를 Provider에 저장합니다.
        provider.setPhotoPath(newFile.path);

        print('📸 Photo Screen Debug - After setting photo:');
        print('  - PhotoPath: ${provider.state.photoPath}');
        print('  - Navigating to generation screen...');

        Navigator.pushNamed(context, '/onboarding/generation');
      } catch (e) {
        print('🚨 사진 처리 중 오류 발생: $e');
        setState(() {
          _validationError = '사진 처리 중 오류가 발생했습니다.';
        });
      }
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E9),
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
      body: Stack(
        children: [
          Column(
            children: [
              // 아이보리 섹션 (제목)
              Container(
                width: double.infinity,
                color: const Color(0xFFFDF7E9),
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.1,
                  16,
                  screenWidth * 0.05,
                  32,
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
              // 노란색 섹션 (Expanded)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 날짜
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
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
                          ),
                          // 폴라로이드 프레임
                          Container(
                            width: screenWidth * 0.8,
                            height: screenWidth * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 6),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                40,
                              ),
                              child: Column(
                                children: [
                                  // 이미지 영역
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color:
                                            _capturedImagePath != null
                                                ? Colors.transparent
                                                : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      child:
                                          _capturedImagePath != null
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0),
                                                child: Image.file(
                                                  File(_capturedImagePath!),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    print('이미지 로드 실패: $error');
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.error_outline,
                                                            size: 40,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            '이미지를 불러올 수 없습니다',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              : _isCameraInitialized &&
                                                  _controller != null
                                              ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0),
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
                                                      BorderRadius.circular(0),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.camera_alt,
                                                        size: 40,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
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
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 투명 스페이서
              Container(height: 15, color: Colors.transparent),
              // 하단 여백
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24 + 56),
            ],
          ),
          // 플로팅 버튼 (이미지 업로드/카메라촬영/흔들어깨우기)
          Positioned(
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child:
                _capturedImagePath == null
                    ? _buildCameraButtons()
                    : _buildWakeUpButton(),
          ),
          // 오류 메시지 (버튼 위에 표시)
          if (_validationError != null)
            Positioned(
              left: screenWidth * 0.1,
              right: screenWidth * 0.1,
              bottom: MediaQuery.of(context).padding.bottom + 24 + 56 + 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200, width: 1),
                ),
                child: Text(
                  _validationError!,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraButtons() {
    return Row(
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
              border: Border.all(color: Colors.grey.shade400, width: 1),
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
        const SizedBox(width: 3),
        // 카메라 촬영 버튼 (반원형 - 오른쪽)
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomRight: Radius.circular(28),
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
    );
  }

  Widget _buildWakeUpButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: ElevatedButton(
        onPressed: () {
          _shakeToWakeUp();
          _proceedToNext();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
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
    );
  }
}
