import 'package:equatable/equatable.dart';

class StoryEntity extends Equatable {
  final String id;
  final String mediaUrl;
  final String caption;
  final String type; // 'image' or 'video'
  final DateTime createdAt;
  final List<String> viewers;

  const StoryEntity({
    required this.id,
    required this.mediaUrl,
    required this.caption,
    required this.type,
    required this.createdAt,
    this.viewers = const [],
  });

  @override
  List<Object?> get props => [id, mediaUrl, caption, type, createdAt, viewers];
}

class StoryGroupEntity extends Equatable {
  final String userId;
  final String userName;
  final String userAvatar;
  final List<StoryEntity> stories;

  const StoryGroupEntity({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.stories,
  });

  @override
  List<Object?> get props => [userId, userName, userAvatar, stories];
}
