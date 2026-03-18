import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/interfaces/i_chat_service.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatService implements IChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _db = FirebaseFirestore.instance;

  CollectionReference get _rooms => _db.collection(AppConstants.colChatRooms);
  CollectionReference get _messages =>
      _db.collection(AppConstants.colMessages);

  @override
  Future<String> getOrCreateChatRoom({
    required String tenantId,
    required String tenantName,
    required String landlordId,
  }) async {
    // Tìm chat room đã tồn tại
    final existing = await _rooms
        .where('tenant_id', isEqualTo: tenantId)
        .where('landlord_id', isEqualTo: landlordId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    // Tạo mới
    final ref = _rooms.doc();
    final room = ChatRoomModel(
      id: ref.id,
      tenantId: tenantId,
      tenantName: tenantName,
      landlordId: landlordId,
    );
    await ref.set(room.toFirestore());
    return ref.id;
  }

  @override
  Stream<List<MessageModel>> streamMessages(String chatRoomId) {
    return _messages
        .where('chat_room_id', isEqualTo: chatRoomId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => MessageModel.fromFirestore(d))
              .toList();
          // Sort ở client, tránh cần Firestore composite index
          list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          return list;
        });
  }

  @override
  Stream<List<ChatRoomModel>> streamChatRooms(String landlordId) {
    return _rooms
        .where('landlord_id', isEqualTo: landlordId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ChatRoomModel.fromFirestore(d))
              .toList();
          // Sort theo tin nhắn mới nhất, null xuống cuối
          list.sort((a, b) {
            if (a.lastMessageAt == null) return 1;
            if (b.lastMessageAt == null) return -1;
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          });
          return list;
        });
  }

  @override
  Stream<List<ChatRoomModel>> streamChatRoomsForTenant(String tenantId) {
    return _rooms
        .where('tenant_id', isEqualTo: tenantId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatRoomModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    final batch = _db.batch();

    // Thêm message
    final msgRef = _messages.doc();
    final msg = MessageModel(
      id: msgRef.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content,
      type: type,
      sentAt: DateTime.now(),
    );
    batch.set(msgRef, msg.toFirestore());

    // Cập nhật chat room: last_message + tăng unread của bên kia
    // Cần biết sender là admin hay tenant → lấy room trước
    final roomSnap = await _rooms.doc(chatRoomId).get();
    final room = ChatRoomModel.fromFirestore(roomSnap);
    final isAdminSending = senderId == room.landlordId;

    batch.update(_rooms.doc(chatRoomId), {
      'last_message': content,
      'last_message_at': Timestamp.fromDate(DateTime.now()),
      // Tăng unread của bên nhận
      if (isAdminSending)
        'unread_by_tenant': FieldValue.increment(1)
      else
        'unread_by_admin': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> markAsRead({
    required String chatRoomId,
    required bool isAdmin,
  }) async {
    await _rooms.doc(chatRoomId).update({
      if (isAdmin) 'unread_by_admin': 0 else 'unread_by_tenant': 0,
    });
  }
}
