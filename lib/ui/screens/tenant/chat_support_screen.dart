import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/chat_provider.dart';
import '../../../services/auth_service.dart';
import '../chat_screen.dart';

/// Lấy admin UID thật từ Firestore rồi mở ChatScreen
class ChatSupportScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatSupportScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  bool _loading = true;
  String? _chatRoomId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    try {
      // Lấy UID thật của admin từ Firestore
      final adminUid = await AuthService().getAdminUid();
      if (adminUid == null) throw Exception('Không tìm thấy admin');

      final id = await context.read<ChatProvider>().getOrCreateChatRoom(
            tenantId: widget.userId,
            tenantName: widget.userName,
            landlordId: adminUid,
          );
      if (mounted) setState(() { _chatRoomId = id; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Lỗi: $_error')),
      );
    }
    return ChatScreen(
      chatRoomId: _chatRoomId!,
      currentUserId: widget.userId,
      otherUserName: 'Young House Hỗ trợ',
      isAdmin: false,
    );
  }
}
