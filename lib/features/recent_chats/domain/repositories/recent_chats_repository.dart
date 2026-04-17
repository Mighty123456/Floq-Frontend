import '../entities/chat_session_entity.dart';

abstract class RecentChatsRepository {
  Future<List<ChatSessionEntity>> getRecentUsers();
  Future<List<ChatSessionEntity>> getRecentGroups();
  Future<void> createGroup(String groupName, List<String> members);
  Future<void> updateGroupMembers(String groupId, List<String> updatedMembers);
}
