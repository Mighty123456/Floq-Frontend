import 'dart:convert';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_user_model.dart';
import '../../presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();

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
}

