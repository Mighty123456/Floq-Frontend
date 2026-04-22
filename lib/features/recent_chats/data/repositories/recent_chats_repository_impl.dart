import '../../domain/entities/chat_session_entity.dart';
import '../../domain/repositories/recent_chats_repository.dart';
import '../../../../core/services/api_client.dart';


class RecentChatsRepositoryImpl implements RecentChatsRepository {
  final ApiClient _apiClient;

  RecentChatsRepositoryImpl(this._apiClient);



  Map<String, dynamic>? _cachedData;

  Future<void> _fetchConversations() async {
    try {
      final response = await _apiClient.dio.get('/chat/conversations');
      if (response.data['success']) {
         _cachedData = response.data['data'];
      }
    } catch (e) {
      // Error fetching
    }
  }

  @override
  Future<List<ChatSessionEntity>> getRecentUsers() async {
    await _fetchConversations();
    if (_cachedData != null) {
      final List individuals = _cachedData!['individuals'] ?? [];
      return individuals.map((c) => _parseChatSession(c, isGroup: false)).toList();
    }
    return [];
  }

  @override
  Future<List<ChatSessionEntity>> getRecentGroups() async {
    if (_cachedData != null) {
      final List groups = _cachedData!['groups'] ?? [];
      _cachedData = null; // Clear after use
      return groups.map((c) => _parseChatSession(c, isGroup: true)).toList();
    }
    return [];
  }

  @override
  Future<void> createGroup(String groupName, List<String> members) async {
    try {
      await _apiClient.dio.post('/chat/groups', data: {
        'name': groupName,
        'members': members,
      });
    } catch (e) {
      // Error creating group
    }
  }

  @override
  Future<void> updateGroupMembers(String groupId, List<String> updatedMembers) async {
    try {
      await _apiClient.dio.patch('/chat/groups/$groupId/members', data: {
        'members': updatedMembers,
      });
    } catch (e) {
      // Error updating group members
    }
  }

  ChatSessionEntity _parseChatSession(dynamic c, {bool isGroup = false}) {
    if (isGroup) {
      return ChatSessionEntity(
        id: c['_id'].toString(), 
        name: c['name'] ?? 'Group',
        profileUrl: c['avatar'] ?? 'https://i.pravatar.cc/150?u=${c['_id']}',
        lastMessage: c['lastMessage'] ?? '',
        lastMessageTime: c['lastMessageTime'] != null ? DateTime.parse(c['lastMessageTime']) : null,
        unreadCount: c['unreadCount'] ?? 0,
        isOnline: false,
        isGroup: true,
      );
    } else {
      final user = c['user'];
      return ChatSessionEntity(
        id: c['_id'].toString(), 
        name: user['fullName'] ?? user['username'] ?? 'Unknown',
        profileUrl: user['avatar'] ?? 'https://i.pravatar.cc/150?u=${c['_id']}',
        lastMessage: c['lastMessage'] ?? '',
        lastMessageTime: c['lastMessageTime'] != null ? DateTime.parse(c['lastMessageTime']) : null,
        unreadCount: c['unreadCount'] ?? 0,
        isOnline: false,
        isGroup: false,
      );
    }
  }
}
