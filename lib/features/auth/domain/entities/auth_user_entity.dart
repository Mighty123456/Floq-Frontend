class AuthUser {
  final String id;
  final String name;
  final String email;
  final String profileUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileUrl = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });
}
