import 'package:equatable/equatable.dart';

enum AppNotificationType {
  like,
  comment,
  follow,
  mention,
  repost,
  system
}

class NotificationEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final AppNotificationType type;
  final String? postId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    this.postId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, senderId, senderName, senderAvatar, type, postId, content, isRead, createdAt];

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      postId: postId,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
