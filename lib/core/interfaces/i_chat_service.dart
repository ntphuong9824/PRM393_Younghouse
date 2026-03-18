import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';

abstract class IChatService {
  /// Lấy hoặc tạo chat room giữa tenant và admin
  Future<String> getOrCreateChatRoom({
    required String tenantId,
    required String tenantName,
    required String landlordId,
  });

  /// Stream tin nhắn realtime trong 1 chat room
  Stream<List<MessageModel>> streamMessages(String chatRoomId);

  /// Stream danh sách chat rooms của admin
  Stream<List<ChatRoomModel>> streamChatRooms(String landlordId);

  /// Stream chat rooms của tenant
  Stream<List<ChatRoomModel>> streamChatRoomsForTenant(String tenantId);

  /// Gửi tin nhắn
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
    String type,
  });

  /// Đánh dấu đã đọc (reset unread counter)
  Future<void> markAsRead({
    required String chatRoomId,
    required bool isAdmin,
  });
}
