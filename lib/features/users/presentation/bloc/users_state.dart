import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../features/feed/domain/entities/post_entity.dart';

class UsersState extends Equatable {
  final List<UserEntity> users;
  final List<UserEntity> requests;
  final List<ContactEntity> contacts;
  final List<UserEntity> blockedUsers;
  final List<UserEntity> searchResults;
  final List<UserEntity> followers;
  final List<UserEntity> following;
  final List<PostEntity> explorePosts;
  
  final bool isLoadingUsers;
  final bool isLoadingRequests;
  final bool isLoadingContacts;
  final bool isLoadingBlocked;
  final bool isLoadingSearch;
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final bool isLoadingExplore;
  final String? errorMessage;

  const UsersState({
    this.users = const [],
    this.requests = const [],
    this.contacts = const [],
    this.blockedUsers = const [],
    this.searchResults = const [],
    this.followers = const [],
    this.following = const [],
    this.explorePosts = const [],
    this.isLoadingUsers = false,
    this.isLoadingRequests = false,
    this.isLoadingContacts = false,
    this.isLoadingBlocked = false,
    this.isLoadingSearch = false,
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.isLoadingExplore = false,
    this.errorMessage,
  });

  UsersState copyWith({
    List<UserEntity>? users,
    List<UserEntity>? requests,
    List<ContactEntity>? contacts,
    List<UserEntity>? blockedUsers,
    List<UserEntity>? searchResults,
    List<UserEntity>? followers,
    List<UserEntity>? following,
    List<PostEntity>? explorePosts,
    bool? isLoadingUsers,
    bool? isLoadingRequests,
    bool? isLoadingContacts,
    bool? isLoadingBlocked,
    bool? isLoadingSearch,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    bool? isLoadingExplore,
    String? errorMessage,
  }) {
    return UsersState(
      users: users ?? this.users,
      requests: requests ?? this.requests,
      contacts: contacts ?? this.contacts,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      searchResults: searchResults ?? this.searchResults,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      explorePosts: explorePosts ?? this.explorePosts,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
      isLoadingBlocked: isLoadingBlocked ?? this.isLoadingBlocked,
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      isLoadingExplore: isLoadingExplore ?? this.isLoadingExplore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        users,
        requests,
        contacts,
        blockedUsers,
        searchResults,
        followers,
        following,
        explorePosts,
        isLoadingUsers,
        isLoadingRequests,
        isLoadingContacts,
        isLoadingBlocked,
        isLoadingSearch,
        isLoadingFollowers,
        isLoadingFollowing,
        isLoadingExplore,
        errorMessage,
      ];
}
