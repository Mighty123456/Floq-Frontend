import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';

class MockUsersRepository implements UsersRepository {
  @override
  Future<List<UserEntity>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      UserEntity(
        id: '1',
        name: 'Alex Rivera',
        profileUrl: 'https://i.pravatar.cc/150?u=1',
        relation: UserRelation.none,
      ),
      UserEntity(
        id: '2',
        name: 'Sarah Jenkins',
        profileUrl: 'https://i.pravatar.cc/150?u=2',
        relation: UserRelation.pending,
      ),
      UserEntity(
        id: '3',
        name: 'Marcus Chen',
        profileUrl: 'https://i.pravatar.cc/150?u=3',
        relation: UserRelation.accepted,
      ),
      UserEntity(
        id: '10',
        name: 'Elena Rodriguez',
        profileUrl: 'https://i.pravatar.cc/150?u=10',
        relation: UserRelation.none,
      ),
      UserEntity(
        id: '11',
        name: 'James Wilson',
        profileUrl: 'https://i.pravatar.cc/150?u=11',
        relation: UserRelation.none,
      ),
    ];
  }

  @override
  Future<List<UserEntity>> getPendingRequests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      UserEntity(
        id: '4',
        name: 'David Thompson',
        profileUrl: 'https://i.pravatar.cc/150?u=4',
        relation: UserRelation.pending,
      ),
      UserEntity(
        id: '5',
        name: 'Emma Watson',
        profileUrl: 'https://i.pravatar.cc/150?u=5',
        relation: UserRelation.pending,
      ),
    ];
  }

  @override
  Future<List<ContactEntity>> getContacts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final contacts = [
      {'name': 'Marcus Chen', 'status': 'Product Designer'},
      {'name': 'Alex Rivera', 'status': 'Busy'},
      {'name': 'Sarah Jenkins', 'status': 'Available'},
      {'name': 'David Thompson', 'status': 'On a call'},
      {'name': 'Emma Watson', 'status': 'At the gym'},
      {'name': 'Elena Rodriguez', 'status': 'Traveling'},
      {'name': 'James Wilson', 'status': 'Coding...'},
      {'name': 'Olivia Smith', 'status': 'Coffee is life'},
      {'name': 'William Brown', 'status': 'Available'},
      {'name': 'Sophia Davis', 'status': 'In a meeting'},
      {'name': 'Liam Garcia', 'status': 'Do not disturb'},
      {'name': 'Isabella Miller', 'status': 'Learning Flutter'},
    ];

    return contacts.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return ContactEntity(
        id: (index + 100).toString(),
        name: data['name']!,
        statusMessage: data['status']!,
        profileUrl: 'https://i.pravatar.cc/150?u=${index + 100}',
      );
    }).toList();
  }

  @override
  Future<void> sendRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> acceptRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> declineRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

