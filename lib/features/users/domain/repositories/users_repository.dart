import '../entities/user_entity.dart';

abstract class UsersRepository {
  Future<List<UserEntity>> getUsers();
  Future<List<UserEntity>> getPendingRequests();
  Future<List<ContactEntity>> getContacts();
  
  Future<void> sendRequest(String userId);
  Future<void> acceptRequest(String userId);
  Future<void> declineRequest(String userId);
}
