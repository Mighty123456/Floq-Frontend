class UserProfileEntity {
  final String id;
  final String name;
  final String email;
  final String profileImagePath;
  final bool isDarkTheme;
  final bool isNotificationsEnabled;
  final bool showOnlineStatus;
  final bool allowFriendRequests;

  UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profileImagePath = '',
    this.isDarkTheme = true,
    this.isNotificationsEnabled = true,
    this.showOnlineStatus = true,
    this.allowFriendRequests = true,
  });

  UserProfileEntity copyWith({
    String? name,
    String? email,
    String? profileImagePath,
    bool? isDarkTheme,
    bool? isNotificationsEnabled,
    bool? showOnlineStatus,
    bool? allowFriendRequests,
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
    );
  }
}
