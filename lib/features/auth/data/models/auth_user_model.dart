import '../../domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUser {
  AuthUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.profileUrl,
    super.followersCount,
    super.followingCount,
    super.postsCount,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      profileUrl: json['avatar']?['url'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'email': email,
      'avatar': {'url': profileUrl},
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
    };
  }
}
