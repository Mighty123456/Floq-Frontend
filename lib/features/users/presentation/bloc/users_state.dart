import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../features/feed/domain/entities/post_entity.dart';
import '../../../chat/domain/entities/channel_entity.dart';

class UsersState extends Equatable {
  final List<UserEntity> users;
  final List<UserEntity> requests;
  final List<ContactEntity> contacts;
  final List<UserEntity> blockedUsers;
  final List<UserEntity> searchResults;
  final List<UserEntity> followers;
  final List<UserEntity> following;
  final List<PostEntity> explorePosts;
  final List<UserEntity> dontFollowBack;
  final List<UserEntity> newFollowers;
  final List<ChannelEntity> trendingChannels;
  
  final bool isLoadingUsers;
  final bool isLoadingRequests;
  final bool isLoadingContacts;
  final bool isLoadingBlocked;
  final bool isLoadingSearch;
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final bool isLoadingExplore;
  final bool isLoadingCategories;
  final bool isLoadingTrending;
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
    this.dontFollowBack = const [],
    this.newFollowers = const [],
    this.trendingChannels = const [],
    this.isLoadingUsers = false,
    this.isLoadingRequests = false,
    this.isLoadingContacts = false,
    this.isLoadingBlocked = false,
    this.isLoadingSearch = false,
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.isLoadingExplore = false,
    this.isLoadingCategories = false,
    this.isLoadingTrending = false,
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
    List<UserEntity>? dontFollowBack,
    List<UserEntity>? newFollowers,
    List<ChannelEntity>? trendingChannels,
    bool? isLoadingUsers,
    bool? isLoadingRequests,
    bool? isLoadingContacts,
    bool? isLoadingBlocked,
    bool? isLoadingSearch,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    bool? isLoadingExplore,
    bool? isLoadingCategories,
    bool? isLoadingTrending,
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
      dontFollowBack: dontFollowBack ?? this.dontFollowBack,
      newFollowers: newFollowers ?? this.newFollowers,
      trendingChannels: trendingChannels ?? this.trendingChannels,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingRequests: isLoadingRequests ?? this.isLoadingRequests,
      isLoadingContacts: isLoadingContacts ?? this.isLoadingContacts,
      isLoadingBlocked: isLoadingBlocked ?? this.isLoadingBlocked,
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      isLoadingExplore: isLoadingExplore ?? this.isLoadingExplore,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingTrending: isLoadingTrending ?? this.isLoadingTrending,
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
        dontFollowBack,
        newFollowers,
        trendingChannels,
        isLoadingUsers,
        isLoadingRequests,
        isLoadingContacts,
        isLoadingBlocked,
        isLoadingSearch,
        isLoadingFollowers,
        isLoadingFollowing,
        isLoadingExplore,
        isLoadingCategories,
        isLoadingTrending,
        errorMessage,
      ];
}
