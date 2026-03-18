import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/chat_room_model.dart';
import '../../../providers/chat_provider.dart';
import '../chat_screen.dart';

class AdminChatListScreen extends StatefulWidget {
  final String landlordId;

  const AdminChatListScreen({
    super.key,
    this.landlordId = AppConstants.tempAdminId,
  });

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Luôn re-subscribe với landlordId thật (không dùng tempAdminId)
      context.read<ChatProvider>().listenChatRooms(widget.landlordId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tin nhắn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          final rooms = provider.chatRooms;
          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có cuộc trò chuyện nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ChatRoomTile(
              room: rooms[i],
              landlordId: widget.landlordId,
            ),
          );
        },
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final String landlordId;

  const _ChatRoomTile({required this.room, required this.landlordId});

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.unreadByAdmin > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              room.tenantName.isNotEmpty
                  ? room.tenantName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '${room.unreadByAdmin}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        room.tenantName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        room.lastMessage ?? 'Chưa có tin nhắn',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? AppColors.textDark : Colors.grey,
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      trailing: room.lastMessageAt != null
          ? Text(
              DateFormatter.formatTime(room.lastMessageAt!),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? AppColors.primary : Colors.grey,
                fontWeight:
                    hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            )
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatRoomId: room.id,
              currentUserId: landlordId,
              otherUserName: room.tenantName,
              isAdmin: true,
            ),
          ),
        );
      },
    );
  }
}
