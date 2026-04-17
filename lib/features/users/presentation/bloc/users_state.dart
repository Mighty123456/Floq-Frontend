import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

class UsersState extends Equatable {
  final List<UserEntity> users;
  final List<UserEntity> requests;
  final List<ContactEntity> contacts;
  final bool isLoadingUsers;
  final bool isLoadingRequests;
  final bool isLoadingContacts;

  const UsersState({
    this.users = const [],
    this.requests = const [],
    this.contacts = const [],
    this.isLoadingUsers = false,
    this.isLoadingRequests = false,
    this.isLoadingContacts = false,
  });

  UsersState copyWith({
    List<UserEntity>? users,
    List<UserEntity>? requests,
    List<ContactEntity>? contacts,
    bool? isLoadingUsers,
    bool? isLoadingRequests,
    bool? isLoadingContacts,
  }) {
    return UsersState(
      users: users ?? this.users,
      requests: requests ?? this.requests,
      contacts: contacts ?? this.contacts,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
    );
  }

  @override
  List<Object> get props => [
        users,
        requests,
        contacts,
        isLoadingUsers,
        isLoadingRequests,
        isLoadingContacts,
      ];
}
