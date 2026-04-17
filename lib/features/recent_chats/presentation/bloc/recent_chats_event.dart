import 'package:equatable/equatable.dart';

abstract class RecentChatsEvent extends Equatable {
  const RecentChatsEvent();

  @override
  List<Object> get props => [];
}

class LoadRecentChatsRequested extends RecentChatsEvent {}

class CreateGroupRequested extends RecentChatsEvent {
  final String groupName;
  final List<String> members;

  const CreateGroupRequested(this.groupName, this.members);

  @override
  List<Object> get props => [groupName, members];
}

class UpdateGroupMembersRequested extends RecentChatsEvent {
  final String groupId;
  final List<String> updatedMembers;

  const UpdateGroupMembersRequested(this.groupId, this.updatedMembers);

  @override
  List<Object> get props => [groupId, updatedMembers];
}
