class ChatSessionEntity {
  final String id;
  final String name;
  final String profileUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isGroup;
  final List<String> groupMembers;

  ChatSessionEntity({
    required this.id,
    required this.name,
    this.profileUrl = '',
    this.lastMessage = '',
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isGroup = false,
    this.groupMembers = const [],
  });

  ChatSessionEntity copyWith({
    String? id,
    String? name,
    String? profileUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    bool? isGroup,
    List<String>? groupMembers,
  }) {
    return ChatSessionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileUrl: profileUrl ?? this.profileUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isGroup: isGroup ?? this.isGroup,
      groupMembers: groupMembers ?? this.groupMembers,
    );
  }
}
