import 'dart:convert';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_user_model.dart';
import '../../presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepositoryImpl({ApiClient? apiClient, SecureStorageService? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<AuthUser> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data['data'];
      final user = AuthUserModel.fromJson(data['user']);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 && e.response?.data['data']?['needsVerification'] == true) {
        throw VerificationRequiredException(
          e.response?.data['data']?['email'] ?? email,
          e.response?.data['message'] ?? 'Verification required',
        );
      }
      final message = e.response?.data['message'] ?? 'Login failed';
      throw Exception(message);
    }
  }

  @override
  Future<AuthUser> register(String name, String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'fullName': name,
        'email': email,
        'password': password,
      });

      final data = response.data['data'];
      // Registration only returns basic info before OTP verification in this flow
      return AuthUserModel(id: data['userId'], name: name, email: email);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Registration failed';
      throw Exception(message);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send reset code');
    }
  }

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _apiClient.dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to reset password');
    }
  }

  // Added verifyEmail to match professional flow requirement
  @override
  Future<AuthUser> verifyOTP(String email, String otp) async {
    try {
      final response = await _apiClient.dio.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });

      final data = response.data['data'];
      final user = AuthUserModel.fromJson(data['user']);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Verification failed');
    }
  }

  @override
  Future<void> requestLoginOTP(String email) async {
    try {
      await _apiClient.dio.post('/auth/request-login-otp', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send login code');
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      // In google_sign_in 7.0.0+, initialization is mandatory
      await gsis.GoogleSignIn.instance.initialize();
      
      // The constructor is now private; use the singleton instance
      // signIn() has been renamed to authenticate()
      final gsis.GoogleSignInAccount googleUser = await gsis.GoogleSignIn.instance.authenticate();
      
      // googleUser.authentication is now a synchronous getter, not a Future
      final gsis.GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // accessToken is now separated from identity. Request it via authorizationClient.
      final gsis.GoogleSignInClientAuthorization clientAuth = 
          await gsis.GoogleSignIn.instance.authorizationClient.authorizeScopes(['email', 'profile']);
      
      // Send token to backend
      final response = await _apiClient.dio.post('/auth/google', data: {
        'idToken': googleAuth.idToken,
        'accessToken': clientAuth.accessToken,
      });

      final data = response.data['data'];
      final user = AuthUserModel.fromJson(data['user']);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));

      return user;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  @override
  Future<AuthUser> loginViaOTP(String email, String otp) async {
    try {
      final response = await _apiClient.dio.post('/auth/login-otp', data: {
        'email': email,
        'otp': otp,
      });

      final data = response.data['data'];
      final user = AuthUserModel.fromJson(data['user']);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  @override
  Future<AuthUser?> getAuthenticatedUser() async {
    try {
      final userJson = await _storage.getUser();
      if (userJson != null) {
        return AuthUserModel.fromJson(jsonDecode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _storage.deleteTokens();
    await _storage.deleteUser();
  }
}

