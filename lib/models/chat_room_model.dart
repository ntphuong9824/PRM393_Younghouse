import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String tenantId;
  final String tenantName;
  final String landlordId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadByAdmin;
  final int unreadByTenant;

  ChatRoomModel({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.landlordId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadByAdmin = 0,
    this.unreadByTenant = 0,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      tenantId: d['tenant_id'] ?? '',
      tenantName: d['tenant_name'] ?? 'Người thuê',
      landlordId: d['landlord_id'] ?? '',
      lastMessage: d['last_message'],
      lastMessageAt: d['last_message_at'] != null
          ? (d['last_message_at'] as Timestamp).toDate()
          : null,
      unreadByAdmin: d['unread_by_admin'] ?? 0,
      unreadByTenant: d['unread_by_tenant'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tenant_id': tenantId,
        'tenant_name': tenantName,
        'landlord_id': landlordId,
        'last_message': lastMessage,
        'last_message_at':
            lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
        'unread_by_admin': unreadByAdmin,
        'unread_by_tenant': unreadByTenant,
      };
}
