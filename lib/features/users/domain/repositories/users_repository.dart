import '../entities/user_entity.dart';

abstract class UsersRepository {
  Future<List<UserEntity>> getUsers();
  Future<List<UserEntity>> getPendingRequests();
  Future<List<ContactEntity>> getContacts();
  
  Future<void> sendRequest(String userId);
  Future<void> acceptRequest(String userId);
  Future<void> declineRequest(String userId);

  Future<List<UserEntity>> searchUsers(String query);
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<void> reportUser(String userId, String reason);
  Future<List<UserEntity>> getBlockedUsers();

  Future<void> uploadAvatar(String imagePath);
  Future<List<UserEntity>> getFollowers(String userId);
  Future<List<UserEntity>> getFollowing(String userId);
}

