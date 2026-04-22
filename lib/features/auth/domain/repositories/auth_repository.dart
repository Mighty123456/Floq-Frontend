import '../entities/auth_user_entity.dart';

abstract class AuthRepository {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> register(String name, String email, String password);
  Future<AuthUser> verifyOTP(String email, String otp);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otp, String newPassword);
  Future<void> requestLoginOTP(String email);
  Future<AuthUser> loginViaOTP(String email, String otp);
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser?> getAuthenticatedUser();
  Future<void> logout();
}

