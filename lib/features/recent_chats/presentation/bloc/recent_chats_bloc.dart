import 'package:flutter_bloc/flutter_bloc.dart';
import 'recent_chats_event.dart';
import 'recent_chats_state.dart';
import '../../domain/repositories/recent_chats_repository.dart';

class RecentChatsBloc extends Bloc<RecentChatsEvent, RecentChatsState> {
  final RecentChatsRepository repository;

  RecentChatsBloc({required this.repository}) : super(const RecentChatsState()) {
    on<LoadRecentChatsRequested>(_onLoadRecentChats);
    on<CreateGroupRequested>(_onCreateGroup);
    on<UpdateGroupMembersRequested>(_onUpdateGroupMembers);
  }

  Future<void> _onLoadRecentChats(LoadRecentChatsRequested event, Emitter<RecentChatsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final users = await repository.getRecentUsers();
      final groups = await repository.getRecentGroups();
      emit(state.copyWith(users: users, groups: groups, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onCreateGroup(CreateGroupRequested event, Emitter<RecentChatsState> emit) async {
    try {
      await repository.createGroup(event.groupName, event.members);
      // Reload groups silently
      final groups = await repository.getRecentGroups();
      emit(state.copyWith(groups: groups));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateGroupMembers(UpdateGroupMembersRequested event, Emitter<RecentChatsState> emit) async {
    try {
      await repository.updateGroupMembers(event.groupId, event.updatedMembers);
      // Reload groups silently
      final groups = await repository.getRecentGroups();
      emit(state.copyWith(groups: groups));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
