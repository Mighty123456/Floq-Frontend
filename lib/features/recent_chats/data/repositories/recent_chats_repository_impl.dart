import '../../domain/entities/chat_session_entity.dart';
import '../../domain/repositories/recent_chats_repository.dart';

class MockRecentChatsRepository implements RecentChatsRepository {
  final List<ChatSessionEntity> _users = [
    ChatSessionEntity(
      id: '3',
      name: 'Marcus Chen',
      profileUrl: 'https://i.pravatar.cc/150?u=3',
      isOnline: true,
      lastMessage: 'The design system looks amazing, let\'s proceed!',
    ),
    ChatSessionEntity(
      id: '1',
      name: 'Alex Rivera',
      profileUrl: 'https://i.pravatar.cc/150?u=1',
      isOnline: true,
      lastMessage: 'I reviewed the pull request. Looks good!',
    ),
    ChatSessionEntity(
      id: '2',
      name: 'Sarah Jenkins',
      profileUrl: 'https://i.pravatar.cc/150?u=2',
      isOnline: false,
      lastMessage: 'See you at the meeting tomorrow.',
    ),
    ChatSessionEntity(
      id: '10',
      name: 'Elena Rodriguez',
      profileUrl: 'https://i.pravatar.cc/150?u=10',
      isOnline: false,
      lastMessage: 'Sent you the files you requested.',
    ),
    ChatSessionEntity(
      id: '11',
      name: 'James Wilson',
      profileUrl: 'https://i.pravatar.cc/150?u=11',
      isOnline: true,
      lastMessage: 'Did you see the new Flutter update?',
    ),
  ];

  final List<ChatSessionEntity> _groups = [
    ChatSessionEntity(
      id: 'g1',
      name: 'Floq Product',
      isGroup: true,
      groupMembers: ['You', 'Marcus Chen', 'Alex Rivera', 'Sarah Jenkins'],
    ),
    ChatSessionEntity(
      id: 'g2',
      name: 'Frontend Guild',
      isGroup: true,
      groupMembers: ['You', 'James Wilson', 'Elena Rodriguez'],
    ),
    ChatSessionEntity(
      id: 'g3',
      name: 'Weekend Plans 🌴',
      isGroup: true,
      groupMembers: ['You', 'Alex Rivera', 'Sarah Jenkins'],
    ),
  ];

  @override
  Future<List<ChatSessionEntity>> getRecentUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_users);
  }

  @override
  Future<List<ChatSessionEntity>> getRecentGroups() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_groups);
  }

  @override
  Future<void> createGroup(String groupName, List<String> members) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _groups.add(
      ChatSessionEntity(
        id: DateTime.now().toString(),
        name: groupName,
        isGroup: true,
        groupMembers: members,
      ),
    );
  }

  @override
  Future<void> updateGroupMembers(String groupId, List<String> updatedMembers) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      _groups[index] = _groups[index].copyWith(groupMembers: updatedMembers);
    }
  }
}

