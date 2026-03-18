import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String content;
  final String type; // text / image
  final String? fileUrl;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.fileUrl,
    required this.sentAt,
    this.isRead = false,
  });

  bool get isImage => type == 'image';

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatRoomId: d['chat_room_id'] ?? '',
      senderId: d['sender_id'] ?? '',
      content: d['content'] ?? '',
      type: d['type'] ?? 'text',
      fileUrl: d['file_url'],
      sentAt: d['sent_at'] != null
          ? (d['sent_at'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: d['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'chat_room_id': chatRoomId,
        'sender_id': senderId,
        'content': content,
        'type': type,
        'file_url': fileUrl,
        'sent_at': Timestamp.fromDate(sentAt),
        'is_read': isRead,
      };
}
