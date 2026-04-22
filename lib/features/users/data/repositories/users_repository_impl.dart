import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../../../../core/services/api_client.dart';

class UsersRepositoryImpl implements UsersRepository {
  final ApiClient _apiClient;

  UsersRepositoryImpl(this._apiClient);


  @override
  Future<List<UserEntity>> getUsers() async {
    final response = await _apiClient.dio.get('/users/explore');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  @override
  Future<List<UserEntity>> getPendingRequests() async {
    final response = await _apiClient.dio.get('/connections/requests');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  @override
  Future<List<ContactEntity>> getContacts() async {
    final response = await _apiClient.dio.get('/connections/contacts');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseContact(u)).toList();
    }
    return [];
  }

  @override
  Future<void> sendRequest(String userId) async {
     await _apiClient.dio.post('/connections/follow/$userId');
  }

  @override
  Future<void> acceptRequest(String userId) async {
     await _apiClient.dio.post('/connections/accept/$userId');
  }

  @override
  Future<void> declineRequest(String userId) async {
     await _apiClient.dio.post('/connections/decline/$userId');
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    final response = await _apiClient.dio.get('/users/search', queryParameters: {'q': query});
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  @override
  Future<void> blockUser(String userId) async {
    await _apiClient.dio.post('/users/block/$userId');
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _apiClient.dio.post('/users/unblock/$userId');
  }

  @override
  Future<void> reportUser(String userId, String reason) async {
    await _apiClient.dio.post('/reports', data: {
      'reportedUser': userId,
      'reason': reason,
    });
  }


  @override
  Future<List<UserEntity>> getBlockedUsers() async {
    final response = await _apiClient.dio.get('/users/blocked-list');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  @override
  Future<void> uploadAvatar(String imagePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imagePath),
    });
    await _apiClient.dio.post('/users/avatar', data: formData);
  }

  @override
  Future<List<UserEntity>> getFollowers(String userId) async {
    final response = await _apiClient.dio.get('/connections/followers/$userId');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  @override
  Future<List<UserEntity>> getFollowing(String userId) async {
    final response = await _apiClient.dio.get('/connections/following/$userId');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((u) => _parseUser(u)).toList();
    }
    return [];
  }

  UserEntity _parseUser(dynamic u) {
    return UserEntity(
      id: u['_id'],
      name: u['fullName'] ?? u['username'] ?? 'Unknown',
      profileUrl: u['avatar']?['url'] ?? 'https://i.pravatar.cc/150?u=${u['_id']}',
      bio: u['bio'] ?? '',
      relation: _parseRelation(u['relation']),
    );
  }


  ContactEntity _parseContact(dynamic u) {
     return ContactEntity(
      id: u['_id'],
      name: u['fullName'] ?? u['username'] ?? 'Unknown',
      profileUrl: u['avatar'] ?? 'https://i.pravatar.cc/150?u=${u['_id']}',
      statusMessage: u['bio'] ?? 'Available',
    );
  }

  UserRelation _parseRelation(String? relation) {
    switch (relation) {
      case 'accepted': return UserRelation.accepted;
      case 'pending': return UserRelation.pending;
      case 'blocked': return UserRelation.blocked;
      default: return UserRelation.none;
    }
  }
}
