import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthForgotPasswordSuccess extends AuthState {}

class AuthResetPasswordSuccess extends AuthState {}

class AuthNeedsVerification extends AuthState {
  final String email;

  const AuthNeedsVerification(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthLoginOTPSent extends AuthState {
  final String email;

  const AuthLoginOTPSent(this.email);

  @override
  List<Object?> get props => [email];
}

