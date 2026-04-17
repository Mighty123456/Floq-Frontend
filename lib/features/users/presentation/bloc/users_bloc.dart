import 'package:flutter_bloc/flutter_bloc.dart';
import 'users_event.dart';
import 'users_state.dart';
import '../../domain/repositories/users_repository.dart';
import '../../domain/entities/user_entity.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository repository;

  UsersBloc({required this.repository}) : super(const UsersState()) {
    on<LoadUsersRequested>(_onLoadUsers);
    on<LoadContactsRequested>(_onLoadContacts);
    on<LoadRequestsRequested>(_onLoadRequests);
    on<SendRequest>(_onSendRequest);
    on<AcceptRequest>(_onAcceptRequest);
    on<DeclineRequest>(_onDeclineRequest);
  }

  Future<void> _onLoadUsers(LoadUsersRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingUsers: true));
    final users = await repository.getUsers();
    emit(state.copyWith(users: users, isLoadingUsers: false));
  }

  Future<void> _onLoadContacts(LoadContactsRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingContacts: true));
    final contacts = await repository.getContacts();
    emit(state.copyWith(contacts: contacts, isLoadingContacts: false));
  }

  Future<void> _onLoadRequests(LoadRequestsRequested event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isLoadingRequests: true));
    final requests = await repository.getPendingRequests();
    emit(state.copyWith(requests: requests, isLoadingRequests: false));
  }

  Future<void> _onSendRequest(SendRequest event, Emitter<UsersState> emit) async {
    await repository.sendRequest(event.userId);
    final updatedUsers = state.users.map((u) {
      if (u.id == event.userId) {
        return u.copyWith(relation: UserRelation.pending);
      }
      return u;
    }).toList();
    emit(state.copyWith(users: updatedUsers));
  }

  Future<void> _onAcceptRequest(AcceptRequest event, Emitter<UsersState> emit) async {
    await repository.acceptRequest(event.userId);
    final updatedRequests = state.requests.where((u) => u.id != event.userId).toList();
    emit(state.copyWith(requests: updatedRequests));
  }

  Future<void> _onDeclineRequest(DeclineRequest event, Emitter<UsersState> emit) async {
    await repository.declineRequest(event.userId);
    final updatedRequests = state.requests.where((u) => u.id != event.userId).toList();
    emit(state.copyWith(requests: updatedRequests));
  }
}
