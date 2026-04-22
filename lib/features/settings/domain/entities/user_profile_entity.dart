class UserProfileEntity {
  final String id;
  final String name;
  final String email;
  final String profileImagePath;
  final bool isDarkTheme;
  final bool isNotificationsEnabled;
  final bool showOnlineStatus;
  final bool allowFriendRequests;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profileImagePath = '',
    this.isDarkTheme = true,
    this.isNotificationsEnabled = true,
    this.showOnlineStatus = true,
    this.allowFriendRequests = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  UserProfileEntity copyWith({
    String? name,
    String? email,
    String? profileImagePath,
    bool? isDarkTheme,
    bool? isNotificationsEnabled,
    bool? showOnlineStatus,
    bool? allowFriendRequests,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return UserProfileEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
    );
  }
}
