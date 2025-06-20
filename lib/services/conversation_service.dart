import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 대화방 ID 생성 (uid와 uuid를 정렬하여 일관된 ID를 만듭니다)
  String getConversationId(String uid, String uuid) {
    // uid와 uuid를 비교하여 항상 같은 순서로 조합
    return uid.compareTo(uuid) < 0 ? '$uid-$uuid' : '$uuid-$uid';
  }

  // 실시간 메시지 스트림 가져오기
  Stream<QuerySnapshot> getMessagesStream(String uid, String uuid) {
    final conversationId = getConversationId(uid, uuid);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 메시지 전송
  Future<void> sendMessage(String uid, String uuid, String text, String sender) async {
    final conversationId = getConversationId(uid, uuid);
    final timestamp = Timestamp.now();

    final messageData = {
      'content': text, // 필드 이름 통일 (text -> content)
      'sender': sender, // 'user' or 'bot'
      'timestamp': timestamp,
    };

    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);

    // messages 서브컬렉션에 메시지 추가
    await conversationRef.collection('messages').add(messageData);

    // conversations 문서에 마지막 메시지 정보 및 messageCount 업데이트
    await conversationRef.set({
      'uid': uid,
      'uuid': uuid,
      'lastMessageAt': timestamp,
      'lastMessageText': text,
      'messageCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // LLM에 전달할 대화 컨텍스트 가져오기
  Future<Map<String, dynamic>> getConversationContext(String uid, String uuid) async {
    final conversationId = getConversationId(uid, uuid);
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);

    final conversationSnap = await conversationRef.get();
    final conversationData =
        conversationSnap.data() as Map<String, dynamic>? ?? {};

    final summary = conversationData['summary'] as String? ?? '';
    final summaryLastMessageTimestamp =
        conversationData['summaryLastMessageTimestamp'] as Timestamp?;

    // 요약 이후의 모든 메시지를 가져옵니다.
    QuerySnapshot messagesSnap;
    if (summaryLastMessageTimestamp != null) {
      messagesSnap = await conversationRef
          .collection('messages')
          .where('timestamp', isGreaterThan: summaryLastMessageTimestamp)
          .orderBy('timestamp', descending: false)
          .get();
    } else {
      // 요약이 아직 없으면 모든 메시지를 가져옵니다.
      messagesSnap = await conversationRef
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
    }

    final recentMessages = messagesSnap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // LLM에게 전달할 형식으로 가공
      return {
        'role': data['sender'] == 'user' ? 'user' : 'assistant',
        'content': data['content'], // 필드 이름 통일
      };
    }).toList();

    return {
      'summary': summary,
      'recentMessages': recentMessages,
    };
  }

  // conversation 문서를 직접 가져오는 메서드
  Future<DocumentSnapshot> getConversationDocument(String uid, String uuid) {
    final conversationId = getConversationId(uid, uuid);
    return _firestore.collection('conversations').doc(conversationId).get();
  }

  // 요약 및 마지막 요약 시간 업데이트
  Future<void> updateSummary(String uid, String uuid, String summary) {
    final conversationId = getConversationId(uid, uuid);
    return _firestore.collection('conversations').doc(conversationId).update({
      'summary': summary,
      'summaryLastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }
} 