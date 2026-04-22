import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final int likesCount;
  final DateTime createdAt;
  final bool isLiked;
  final String? parentId;
  final List<CommentEntity> replies;

  const CommentEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.likesCount,
    required this.createdAt,
    this.isLiked = false,
    this.parentId,
    this.replies = const [],
  });

  @override
  List<Object?> get props => [
    id, userId, userName, userAvatar, text, likesCount, createdAt, isLiked, parentId, replies
  ];
}
