import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_session_entity.dart';

class RecentChatsState extends Equatable {
  final List<ChatSessionEntity> users;
  final List<ChatSessionEntity> groups;
  final bool isLoading;
  final String? error;

  const RecentChatsState({
    this.users = const [],
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  RecentChatsState copyWith({
    List<ChatSessionEntity>? users,
    List<ChatSessionEntity>? groups,
    bool? isLoading,
    String? error,
  }) {
    return RecentChatsState(
      users: users ?? this.users,
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error if not provided
    );
  }

  @override
  List<Object?> get props => [users, groups, isLoading, error];
}
