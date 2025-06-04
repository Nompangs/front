import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nompangs/providers/onboarding_provider.dart';
import 'package:nompangs/widgets/common/primary_button.dart';
import 'dart:io';

class OnboardingPhotoScreen extends StatefulWidget {
  const OnboardingPhotoScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingPhotoScreen> createState() => _OnboardingPhotoScreenState();
}

class _OnboardingPhotoScreenState extends State<OnboardingPhotoScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _capturedImagePath;
  final ImagePicker _imagePicker = ImagePicker();

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
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.high,
        );
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
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
    } catch (e) {
      print('사진 촬영 실패: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImagePath = image.path;
        });
      }
    } catch (e) {
      print('갤러리에서 선택 실패: $e');
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImagePath = null;
    });
  }

  void _confirmPhoto() {
    if (_capturedImagePath != null) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      provider.setPhotoPath(_capturedImagePath!);
      Navigator.pushNamed(context, '/onboarding/generation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('사진 촬영'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/onboarding/generation'),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
      body: _capturedImagePath != null
          ? _buildPreviewScreen()
          : _buildCameraScreen(),
    );
  }

  Widget _buildCameraScreen() {
    if (!_isCameraInitialized || _controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라를 준비하고 있어요...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // 카메라 미리보기
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),
        
        // 상단 가이드
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '사물을 화면 중앙에 배치해주세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // 중앙 가이드 프레임
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // 하단 컨트롤
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 갤러리 버튼
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    size: 30,
                    color: Colors.black87,
                  ),
                ),
              ),

              // 촬영 버튼
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF6750A4),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: Color(0xFF6750A4),
                  ),
                ),
              ),

              // 플래시 버튼 (임시)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.flash_off,
                  size: 30,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewScreen() {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        Text(
          '사진이 잘 나왔나요?',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // 촬영된 이미지 미리보기
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_capturedImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // 버튼들
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              PrimaryButton(
                text: '이 사진으로 진행',
                onPressed: _confirmPhoto,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _retakePicture,
                child: const Text(
                  '다시 촬영하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }
} 