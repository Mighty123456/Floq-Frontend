import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../../../../core/services/api_client.dart';
import '../../../chat/domain/entities/channel_entity.dart';

class UsersRepositoryImpl implements UsersRepository {
  final ApiClient _apiClient;

  UsersRepositoryImpl(this._apiClient);

  @override
  Future<UserEntity?> getMe() async {
    final response = await _apiClient.dio.get('/users/profile/me');
    if (response.data['success']) {
      return _parseUser(response.data['data']);
    }
    return null;
  }
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

  @override
  Future<Map<String, List<UserEntity>>> getConnectionCategories() async {
    final response = await _apiClient.dio.get('/connections/categories');
    if (response.data['success']) {
      final data = response.data['data'];
      return {
        'dontFollowBack': (data['dontFollowBack'] as List).map((u) => _parseUser(u)).toList(),
        'newFollowers': (data['newFollowers'] as List).map((u) => _parseUser(u)).toList(),
      };
    }
    return {'dontFollowBack': [], 'newFollowers': []};
  }

  @override
  Future<List<ChannelEntity>> getTrendingChannels() async {
    final response = await _apiClient.dio.get('/chat/trending/groups');
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((c) => _parseChannel(c)).toList();
    }
    return [];
  }

  @override
  Future<void> updateCameraSettings({required bool alwaysStartOnFrontCamera, required String toolbarSide}) async {
    await _apiClient.dio.patch('/users/camera-settings', data: {
      'cameraSettings': {
        'alwaysStartOnFrontCamera': alwaysStartOnFrontCamera,
        'toolbarSide': toolbarSide,
      }
    });
  }

  ChannelEntity _parseChannel(dynamic c) {
    return ChannelEntity(
      id: c['_id'],
      name: c['name'],
      description: c['description'] ?? '',
      avatarUrl: (c['avatar'] is Map) ? (c['avatar']['url'] ?? '') : (c['avatar'] ?? ''),
      memberCount: c['memberCount'] ?? (c['members'] as List).length,
      adminId: c['admin'].toString(),
    );
  }

  UserEntity _parseUser(dynamic u) {
    return UserEntity(
      id: u['_id'],
      name: u['fullName'] ?? u['username'] ?? 'Unknown',
      profileUrl: (u['avatar'] is Map) ? (u['avatar']['url'] ?? '') : (u['avatar'] ?? ''),
      bio: u['bio'] ?? '',
      email: u['email'] ?? '',
      relation: _parseRelation(u['relation']),
      cameraSettings: u['cameraSettings'] ?? const {'alwaysStartOnFrontCamera': false, 'toolbarSide': 'left'},
    );
  }


  ContactEntity _parseContact(dynamic u) {
     return ContactEntity(
      id: u['_id'],
      name: u['fullName'] ?? u['username'] ?? 'Unknown',
      profileUrl: (u['avatar'] is Map) ? u['avatar']['url'] : (u['avatar'] ?? ''),
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
