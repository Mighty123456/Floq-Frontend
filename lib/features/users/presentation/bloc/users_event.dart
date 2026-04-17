import 'package:equatable/equatable.dart';

abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class LoadUsersRequested extends UsersEvent {}

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
