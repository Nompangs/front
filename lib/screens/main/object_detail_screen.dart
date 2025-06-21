import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:nompangs/screens/main/chat_text_screen.dart';
import 'package:nompangs/providers/chat_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nompangs/screens/main/flutter_mobile_clone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nompangs/services/api_service.dart';

class ObjectDetailScreen extends StatelessWidget {
  final ObjectData objectData;

  const ObjectDetailScreen({Key? key, required this.objectData})
    : super(key: key);

  Future<void> _deleteObject(BuildContext context) async {
    try {
      print('삭제 시도: qr_profiles/${objectData.uuid}');
      // Firestore에서 qr_profiles 컬렉션의 uuid 문서 삭제
      await FirebaseFirestore.instance
          .collection('qr_profiles')
          .doc(objectData.uuid)
          .delete();
      print('삭제 성공: qr_profiles/${objectData.uuid}');
      // 성공 시 이전 화면에 true 반환
      Navigator.pop(context, true);
    } catch (e) {
      print('삭제 실패: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: ${e.toString()}')));
    }
  }

  Widget buildObjectImage(String? imageUrl) {
    if (imageUrl == null) {
      return Image.asset(
        'assets/testImg_1.png',
        width: 140,
        height: 140,
        fit: BoxFit.cover,
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/testImg_1.png',
            width: 140,
            height: 140,
            fit: BoxFit.cover,
          );
        },
      );
    }
    try {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/testImg_1.png',
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            );
          },
        );
      }
    } catch (_) {}
    return Image.asset(
      'assets/testImg_1.png',
      width: 140,
      height: 140,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final qrData = 'nompangs://object?uuid=${objectData.uuid}';
    final personalityTags = objectData.personalityTags ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(objectData.title),
        backgroundColor: const Color(0xFFC5FF35),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사물 이미지와 기본 정보
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: buildObjectImage(objectData.imageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                objectData.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                objectData.location,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            Center(
              child: Text(
                '최근 대화: ${objectData.duration} 전',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            // 성격 태그
            if (personalityTags.isNotEmpty)
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      personalityTags
                          .map((tag) => _buildPersonalityTag(tag))
                          .toList(),
                ),
              ),
            if (personalityTags.isNotEmpty) const SizedBox(height: 20),
            // 인사말/설명
            if (objectData.greeting != null && objectData.greeting!.isNotEmpty)
              Center(
                child: Text(
                  objectData.greeting!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            // QR 코드
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC8A6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 120.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Share.share('이 사물과 대화하려면 QR을 스캔하세요!\n$qrData');
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('공유하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 통계 (예시)
            const Text(
              '나와의 인터랙션 통계',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const Text('대화 횟수: ', style: TextStyle(fontSize: 14)),
                Text(
                  '5회',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.access_time, size: 18),
                const Text('마지막 대화: ', style: TextStyle(fontSize: 14)),
                Text(
                  objectData.duration.contains('전')
                      ? objectData.duration
                      : objectData.duration + ' 전',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // TODO: 성격 차트 등 추가 가능
            // 하단 버튼들
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // 🚨 [수정] 채팅 시작 시 서버에서 전체 프로필 다시 로드
                    try {
                      final apiService = ApiService();
                      final profile = await apiService.loadProfile(
                        objectData.uuid,
                      );
                      final characterProfile = profile.toMap();

                      // 현재 사용자 이름 주입
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

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChangeNotifierProvider(
                                create:
                                    (_) => ChatProvider(
                                      characterProfile: characterProfile,
                                    ),
                                child: const ChatTextScreen(),
                              ),
                        ),
                      );
                    } catch (e) {
                      print('🚨 상세 화면에서 프로필 로딩 실패: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('캐릭터 정보를 불러오는 데 실패했습니다.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5FF35),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '대화 시작하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: 수정 기능 구현
                          print('수정 버튼 클릭');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '수정하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // TODO: 삭제 기능 구현
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('정말 삭제하시겠어요?'),
                                  content: const Text('이 사물은 되돌릴 수 없이 삭제됩니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text('삭제'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            await _deleteObject(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('삭제하기'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityTag(String tag) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }
}
