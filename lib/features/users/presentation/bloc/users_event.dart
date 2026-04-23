import 'package:equatable/equatable.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class LoadUsersRequested extends UsersEvent {}

class LoadExploreFeedRequested extends UsersEvent {}

class LoadContactsRequested extends UsersEvent {}

class LoadRequestsRequested extends UsersEvent {}

class SendRequest extends UsersEvent {
  final String userId;
  const SendRequest(this.userId);
  @override
  List<Object> get props => [userId];
}

class AcceptRequest extends UsersEvent {
  final String userId;
  const AcceptRequest(this.userId);
  @override
  List<Object> get props => [userId];
}

class DeclineRequest extends UsersEvent {
  final String userId;
  const DeclineRequest(this.userId);
  @override
  List<Object> get props => [userId];
}

class SearchUsersRequested extends UsersEvent {
  final String query;
  const SearchUsersRequested(this.query);
  @override
  List<Object> get props => [query];
}

class BlockUserRequested extends UsersEvent {
  final String userId;
  const BlockUserRequested(this.userId);
  @override
  List<Object> get props => [userId];
}

class UnblockUserRequested extends UsersEvent {
  final String userId;
  const UnblockUserRequested(this.userId);
  @override
  List<Object> get props => [userId];
}

class ReportUserRequested extends UsersEvent {
  final String userId;
  final String reason;
  const ReportUserRequested(this.userId, this.reason);
  @override
  List<Object> get props => [userId, reason];
}


class LoadBlockedUsersRequested extends UsersEvent {}

class UploadAvatarRequested extends UsersEvent {
  final String imagePath;
  const UploadAvatarRequested(this.imagePath);
  @override
  List<Object> get props => [imagePath];
}

class LoadFollowersRequested extends UsersEvent {
  final String userId;
  const LoadFollowersRequested(this.userId);
  @override
  List<Object> get props => [userId];
}

class LoadFollowingRequested extends UsersEvent {
  final String userId;
  const LoadFollowingRequested(this.userId);
  @override
  List<Object> get props => [userId];
}

class LoadConnectionCategoriesRequested extends UsersEvent {}

class LoadTrendingChannelsRequested extends UsersEvent {}

