class ChatSessionEntity {
  final String id;
  final String name;
  final String profileUrl;
  final String lastMessage;
  final bool isOnline;
  final bool isGroup;
  final List<String> groupMembers;

  ChatSessionEntity({
    required this.id,
    required this.name,
    this.profileUrl = '',
    this.lastMessage = '',
    this.isOnline = false,
    this.isGroup = false,
    this.groupMembers = const [],
  });

  ChatSessionEntity copyWith({
    String? id,
    String? name,
    String? profileUrl,
    String? lastMessage,
    bool? isOnline,
    bool? isGroup,
    List<String>? groupMembers,
  }) {
    return ChatSessionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      profileUrl: profileUrl ?? this.profileUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      isOnline: isOnline ?? this.isOnline,
      isGroup: isGroup ?? this.isGroup,
      groupMembers: groupMembers ?? this.groupMembers,
    );
  }
}
