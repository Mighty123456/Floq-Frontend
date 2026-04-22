import 'package:flutter_bloc/flutter_bloc.dart';
import 'users_event.dart';
import 'users_state.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../features/feed/domain/repositories/feed_repository.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository repository;
  final FeedRepository feedRepository;

  UsersBloc({required this.repository, required this.feedRepository}) : super(const UsersState()) {
    on<LoadUsersRequested>(_onLoadUsers);
    on<LoadExploreFeedRequested>(_onLoadExploreFeed);
    on<LoadContactsRequested>(_onLoadContacts);
    on<LoadRequestsRequested>(_onLoadRequests);
    on<SendRequest>(_onSendRequest);
    on<AcceptRequest>(_onAcceptRequest);
    on<DeclineRequest>(_onDeclineRequest);
    on<SearchUsersRequested>(_onSearchUsers);
    on<BlockUserRequested>(_onBlockUser);
    on<UnblockUserRequested>(_onUnblockUser);
    on<LoadBlockedUsersRequested>(_onLoadBlockedUsers);
    on<UploadAvatarRequested>(_onUploadAvatar);
    on<ReportUserRequested>(_onReportUser);
    on<LoadFollowersRequested>(_onLoadFollowers);
    on<LoadFollowingRequested>(_onLoadFollowing);
  }

  Future<void> _onLoadExploreFeed(LoadExploreFeedRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingExplore: true, errorMessage: null));
    try {
      final posts = await feedRepository.getFeed(page: 1);
      emit(state.copyWith(explorePosts: posts, isLoadingExplore: false));
    } catch (e) {
      emit(state.copyWith(isLoadingExplore: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadUsers(LoadUsersRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingUsers: true, errorMessage: null));
    try {
      final users = await repository.getUsers();
      emit(state.copyWith(users: users, isLoadingUsers: false));
    } catch (e) {
      emit(state.copyWith(isLoadingUsers: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadContacts(LoadContactsRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingContacts: true, errorMessage: null));
    try {
      final contacts = await repository.getContacts();
      emit(state.copyWith(contacts: contacts, isLoadingContacts: false));
    } catch (e) {
      emit(state.copyWith(isLoadingContacts: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadRequests(LoadRequestsRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingRequests: true, errorMessage: null));
    try {
      final requests = await repository.getPendingRequests();
      emit(state.copyWith(requests: requests, isLoadingRequests: false));
    } catch (e) {
      emit(state.copyWith(isLoadingRequests: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadFollowers(LoadFollowersRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingFollowers: true, errorMessage: null));
    try {
      final followers = await repository.getFollowers(event.userId);
      emit(state.copyWith(followers: followers, isLoadingFollowers: false));
    } catch (e) {
      emit(state.copyWith(isLoadingFollowers: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadFollowing(LoadFollowingRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingFollowing: true, errorMessage: null));
    try {
      final following = await repository.getFollowing(event.userId);
      emit(state.copyWith(following: following, isLoadingFollowing: false));
    } catch (e) {
      emit(state.copyWith(isLoadingFollowing: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendRequest(SendRequest event, Emitter<UsersState> emit) async {
    try {
      await repository.sendRequest(event.userId);
      final updatedUsers = state.users.map((u) {
        if (u.id == event.userId) {
          return u.copyWith(relation: UserRelation.pending);
        }
        return u;
      }).toList();
      emit(state.copyWith(users: updatedUsers));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onAcceptRequest(AcceptRequest event, Emitter<UsersState> emit) async {
    try {
      await repository.acceptRequest(event.userId);
      final updatedRequests = state.requests.where((u) => u.id != event.userId).toList();
      emit(state.copyWith(requests: updatedRequests));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDeclineRequest(DeclineRequest event, Emitter<UsersState> emit) async {
    try {
      await repository.declineRequest(event.userId);
      final updatedRequests = state.requests.where((u) => u.id != event.userId).toList();
      emit(state.copyWith(requests: updatedRequests));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSearchUsers(SearchUsersRequested event, Emitter<UsersState> emit) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: [], isLoadingSearch: false));
      return;
    }
    emit(state.copyWith(isLoadingSearch: true, errorMessage: null));
    try {
      final results = await repository.searchUsers(event.query);
      emit(state.copyWith(searchResults: results, isLoadingSearch: false));
    } catch (e) {
      emit(state.copyWith(isLoadingSearch: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onBlockUser(BlockUserRequested event, Emitter<UsersState> emit) async {
    try {
      await repository.blockUser(event.userId);
      add(LoadUsersRequested());
      add(LoadBlockedUsersRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onUnblockUser(UnblockUserRequested event, Emitter<UsersState> emit) async {
    try {
      await repository.unblockUser(event.userId);
      add(LoadBlockedUsersRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadBlockedUsers(LoadBlockedUsersRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingBlocked: true, errorMessage: null));
    try {
      final blocked = await repository.getBlockedUsers();
      emit(state.copyWith(blockedUsers: blocked, isLoadingBlocked: false));
    } catch (e) {
      emit(state.copyWith(isLoadingBlocked: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUploadAvatar(UploadAvatarRequested event, Emitter<UsersState> emit) async {
    try {
      await repository.uploadAvatar(event.imagePath);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onReportUser(ReportUserRequested event, Emitter<UsersState> emit) async {
    try {
      await repository.reportUser(event.userId, event.reason);
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}


