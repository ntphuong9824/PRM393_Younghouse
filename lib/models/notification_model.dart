import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? targetUserId;
  final List<String> readBy;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.targetUserId,
    this.readBy = const [],
    this.metadata,
  });

  bool isReadBy(String userId) => readBy.contains(userId);

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    String? targetUserId,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      targetUserId: targetUserId ?? this.targetUserId,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      targetUserId: data['targetUserId'],
      readBy: List<String>.from(data['readBy'] ?? []),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'message': message,
    'createdAt': Timestamp.fromDate(createdAt),
    'targetUserId': targetUserId,
    'readBy': readBy,
    if (metadata != null) 'metadata': metadata,
  };
}
