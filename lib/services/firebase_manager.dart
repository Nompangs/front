import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseManager {
  static FirebaseManager? _instance;
  static FirebaseManager get instance => _instance ??= FirebaseManager._();
  FirebaseManager._();

  // Firebase 초기화
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print("✅ Firebase 초기화 성공!");

      // 개발 모드에서만 테스트
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        await instance._testConnection();
      }

      instance._initAuthListener();
    } catch (e) {
      print("❌ Firebase 초기화 실패: $e");
    }
  }

  // 연결 테스트
  Future<void> _testConnection() async {
    try {
      await FirebaseFirestore.instance.collection('test').doc('connection_test').set({
        'message': 'Firebase 연결 테스트',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signInAnonymously();
      print("✅ Firebase 연결 테스트 성공!");
    } catch (e) {
      print("❌ Firebase 연결 테스트 실패: $e");
    }
  }

  // Auth 상태 감지
  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('👤 사용자 로그아웃됨');
      } else {
        print('👤 사용자 로그인됨: ${user.uid} (익명: ${user.isAnonymous})');
      }
    });
  }

  // 현재 사용자 가져오기 (없으면 익명 로그인)
  Future<User?> getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      print("🔐 익명 로그인 완료: ${user?.uid}");
    }
    return user;
  }
}