import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final _service = ChatService();

  // ── Admin: danh sách chat rooms ──────────────────────────────
  List<ChatRoomModel> _chatRooms = [];
  StreamSubscription? _roomsSub;

  // ── Tenant: unread count ──────────────────────────────────────
  List<ChatRoomModel> _tenantRooms = [];
  StreamSubscription? _tenantRoomsSub;

  List<ChatRoomModel> get chatRooms => _chatRooms;

  int get totalUnreadByAdmin =>
      _chatRooms.fold(0, (sum, r) => sum + r.unreadByAdmin);

  int get totalUnreadByTenant =>
      _tenantRooms.fold(0, (sum, r) => sum + r.unreadByTenant);

  void listenChatRooms(String landlordId) {
    _roomsSub?.cancel();
    _roomsSub = _service.streamChatRooms(landlordId).listen((rooms) {
      _chatRooms = rooms;
      notifyListeners();
    });
  }

  void listenChatRoomsForTenant(String tenantId) {
    _tenantRoomsSub?.cancel();
    _tenantRoomsSub =
        _service.streamChatRoomsForTenant(tenantId).listen((rooms) {
      _tenantRooms = rooms;
      notifyListeners();
    });
  }

  // ── Messages trong 1 room ────────────────────────────────────
  List<MessageModel> _messages = [];
  StreamSubscription? _msgSub;
  String? _activeChatRoomId;

  List<MessageModel> get messages => _messages;

  void listenMessages(String chatRoomId) {
    // Luôn re-subscribe để đảm bảo stream active
    _msgSub?.cancel();
    _activeChatRoomId = chatRoomId;
    _messages = [];
    notifyListeners();
    _msgSub = _service.streamMessages(chatRoomId).listen((msgs) {
      _messages = msgs;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Chat stream error: $e');
    });
  }

  void stopListeningMessages() {
    _msgSub?.cancel();
    _activeChatRoomId = null;
    _messages = [];
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<String> getOrCreateChatRoom({
    required String tenantId,
    required String tenantName,
    required String landlordId,
  }) {
    return _service.getOrCreateChatRoom(
      tenantId: tenantId,
      tenantName: tenantName,
      landlordId: landlordId,
    );
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String content,
  }) {
    return _service.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      content: content,
    );
  }

  Future<void> markAsRead({required String chatRoomId, required bool isAdmin}) {
    return _service.markAsRead(chatRoomId: chatRoomId, isAdmin: isAdmin);
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _tenantRoomsSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }
}
