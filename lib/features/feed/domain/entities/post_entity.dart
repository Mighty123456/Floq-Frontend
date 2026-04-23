import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String caption;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked;
  final bool isSaved;
  final PostEntity? repostOf;
  final int repostsCount;
  final List<String> hashtags;
  final String type;

  const PostEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.caption,
    required this.mediaUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.isLiked = false,
    this.isSaved = false,
    this.repostOf,
    this.repostsCount = 0,
    this.hashtags = const [],
    this.type = 'post',
  });


  PostEntity copyWith({
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return PostEntity(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      caption: caption,
      mediaUrls: mediaUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      repostOf: repostOf,
      repostsCount: repostsCount ?? this.repostsCount,
      hashtags: hashtags,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'caption': caption,
      'mediaUrls': mediaUrls,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt.toIso8601String(),
      'isLiked': isLiked,
      'isSaved': isSaved,
      'repostsCount': repostsCount,
      'hashtags': hashtags,
      'type': type,
      if (repostOf != null) 'repostOf': repostOf!.toJson(),
    };
  }

  factory PostEntity.fromJson(Map<String, dynamic> json) {
    return PostEntity(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      caption: json['caption'],
      mediaUrls: List<String>.from(json['mediaUrls']),
      likesCount: json['likesCount'],
      commentsCount: json['commentsCount'],
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      repostsCount: json['repostsCount'] ?? 0,
      hashtags: List<String>.from(json['hashtags'] ?? []),
      type: json['type'] ?? 'post',
      repostOf: json['repostOf'] != null ? PostEntity.fromJson(json['repostOf']) : null,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, userName, userAvatar, caption, mediaUrls, 
    likesCount, commentsCount, createdAt, isLiked, isSaved,
    repostOf, repostsCount, hashtags, type
  ];
}
