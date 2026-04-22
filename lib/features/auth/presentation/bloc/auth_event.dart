import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}
class AuthGoogleSignInRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterRequested(this.name, this.email, this.password);

  @override
  List<Object> get props => [name, email, password];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String otp;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, otp, newPassword];
}

class AuthVerifyOTPRequested extends AuthEvent {
  final String email;
  final String otp;

  const AuthVerifyOTPRequested(this.email, this.otp);

  @override
  List<Object> get props => [email, otp];
}

class AuthLoginOTPRequested extends AuthEvent {
  final String email;

  const AuthLoginOTPRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthVerifyLoginOTPRequested extends AuthEvent {
  final String email;
  final String otp;

  const AuthVerifyLoginOTPRequested(this.email, this.otp);

  @override
  List<Object> get props => [email, otp];
}
