import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final Timestamp? lastMessageAt;
  final String? lastMessageText;
  final int? messageCount;
  final String? uid;
  final String? uuid;
  final String? characterId;
  final String? summary;

  Conversation({
    required this.id,
    this.lastMessageAt,
    this.lastMessageText,
    this.messageCount,
    this.uid,
    this.uuid,
    this.characterId,
    this.summary,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Conversation(
      id: doc.id,
      lastMessageAt: data['lastMessageAt'],
      lastMessageText: data['lastMessageText'],
      messageCount: data['messageCount'],
      uid: data['uid'],
      uuid: data['uuid'],
      characterId: data['characterId'],
      summary: data['summary'],
    );
  }
} 