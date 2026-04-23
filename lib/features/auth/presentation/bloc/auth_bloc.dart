import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/api_client.dart';
import 'dart:async';

class VerificationRequiredException implements Exception {
  final String email;
  final String message;
  VerificationRequiredException(this.email, this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  StreamSubscription? _logoutSubscription;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    _logoutSubscription = ApiClient.logoutStream.listen((_) {
      add(AuthLogoutRequested());
    });
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthVerifyOTPRequested>(_onVerifyOTPRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthLoginOTPRequested>(_onLoginOTPRequested);
    on<AuthVerifyLoginOTPRequested>(_onVerifyLoginOTPRequested);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSwitchAccountRequested>(_onSwitchAccountRequested);
  }

  Future<void> _onSwitchAccountRequested(
    AuthSwitchAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.switchAccount(event.account);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on VerificationRequiredException catch (e) {
      emit(AuthNeedsVerification(e.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.register(event.name, event.email, event.password);
      emit(AuthNeedsVerification(event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOTPRequested(
    AuthVerifyOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.verifyOTP(event.email, event.otp);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.forgotPassword(event.email);
      emit(AuthForgotPasswordSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.resetPassword(event.email, event.otp, event.newPassword);
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginOTPRequested(
    AuthLoginOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.requestLoginOTP(event.email);
      emit(AuthLoginOTPSent(event.email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyLoginOTPRequested(
    AuthVerifyLoginOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.loginViaOTP(event.email, event.otp);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await repository.getAuthenticatedUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  @override
  Future<void> close() {
    _logoutSubscription?.cancel();
    return super.close();
  }
}

