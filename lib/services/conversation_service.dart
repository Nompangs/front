import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:nompangs/models/conversation.dart';
import 'package:nompangs/models/message.dart';
import 'package:nompangs/services/character_manager.dart';

// TODO: Implement ConversationService
class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CharacterManager _characterManager = CharacterManager.instance;

  // 두 ID를 정렬하여 일관된 대화방 ID를 생성합니다.
  static String getConversationId(String userId, String characterId) {
    return userId.compareTo(characterId) < 0
        ? '$userId-$characterId'
        : '$characterId-$userId';
  }

  // 특정 대화의 메시지 목록을 실시간으로 가져옵니다.
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    });
  }

  // 사용자 또는 챗봇의 메시지를 Firestore에 추가합니다.
  Future<void> addMessage({
    required String conversationId,
    required String sender,
    required String text,
  }) async {
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    final message = Message(
      id: messageRef.id,
      sender: sender,
      text: text,
      timestamp: Timestamp.now(),
    );

    // 트랜잭션을 사용하여 대화 메타데이터와 메시지를 원자적으로 업데이트합니다.
    return _firestore.runTransaction((transaction) async {
      final conversationSnap = await transaction.get(conversationRef);

      if (!conversationSnap.exists) {
        // 새 대화인 경우 초기화
        transaction.set(conversationRef, {
          'messageCount': 1,
          'lastMessageText': text,
          'lastMessageAt': message.timestamp,
        }, SetOptions(merge: true));
      } else {
        transaction.update(conversationRef, {
          'messageCount': FieldValue.increment(1),
          'lastMessageText': text,
          'lastMessageAt': message.timestamp,
        });
      }

      transaction.set(messageRef, message.toMap());
    });
  }

  // AI 응답 생성을 위한 컨텍스트(기억 + 성격)를 가져옵니다.
  Future<Map<String, dynamic>> getConversationContext(
      String conversationId) async {
    final conversationSnap =
        await _firestore.collection('conversations').doc(conversationId).get();
    
    if (!conversationSnap.exists) {
      throw Exception('Conversation not found');
    }

    final conversationData = conversationSnap.data() as Map<String, dynamic>;

    // 1. 장기 기억 (요약본) 로드
    final summary = conversationData['summary'] as String?;

    // 2. 단기 기억 (최근 10개 메시지) 로드
    final messagesSnap = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    
    final recentMessages = messagesSnap.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList()
        .reversed
        .toList(); // 시간 순서대로 다시 뒤집기

    // 3. 성격 프로필 로드
    final characterId = conversationData['characterId'] as String?;
    Map<String, dynamic>? characterProfile;
    if (characterId != null) {
      characterProfile = await _characterManager.loadCharacter(characterId);
    }
    
    return {
      'summary': summary,
      'recentMessages': recentMessages,
      'characterProfile': characterProfile,
    };
  }

  // 생성된 요약본을 Firestore에 업데이트합니다.
  Future<void> updateSummary({
    required String conversationId,
    required String summary,
  }) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    await conversationRef.set({'summary': summary}, SetOptions(merge: true));
  }

  Future<int> getMessageCount(String conversationId) async {
    final snapshot = await _firestore.collection('conversations').doc(conversationId).collection('messages').get();
    return snapshot.size;
  }

  Future<List<Message>> getAllMessages(String conversationId) async {
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .get();
    return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
  }

  // conversation 문서를 직접 가져오는 메서드
  Future<DocumentSnapshot> getConversationDocument(String uid, String uuid) {
    final conversationId = getConversationId(uid, uuid);
    return _firestore.collection('conversations').doc(conversationId).get();
  }

  // 특정 대화의 메타데이터를 가져옵니다.
  Future<Conversation> getConversation(String conversationId) async {
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    if (!doc.exists) {
      throw Exception('Conversation with id $conversationId not found');
    }
    return Conversation.fromFirestore(doc);
  }
} 