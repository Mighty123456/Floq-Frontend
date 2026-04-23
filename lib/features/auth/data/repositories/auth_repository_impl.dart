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

      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;
      
      final userMap = data['user'] as Map<String, dynamic>;
      final user = AuthUserModel.fromJson(userMap);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));
      await _updateAccounts(user, data['accessToken'], data['refreshToken']);

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

      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;
      // Registration only returns basic info before OTP verification in this flow
      return AuthUserModel(id: data['userId'] ?? data['_id'], name: name, email: email);
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

      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;
          
      final userMap = data['user'] as Map<String, dynamic>;
      final user = AuthUserModel.fromJson(userMap);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));
      await _updateAccounts(user, data['accessToken'], data['refreshToken']);

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

      // authenticate() returns the signed-in Google account
      final gsis.GoogleSignInAccount googleUser =
          await gsis.GoogleSignIn.instance.authenticate();

      // authentication is a synchronous getter in v7.x
      final gsis.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Send only the idToken to backend — no need for authorizeScopes()
      // which triggers a second re-auth flow and causes Error 16 on Android
      final response = await _apiClient.dio.post('/auth/google', data: {
        'idToken': googleAuth.idToken,
      });

      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;

      if (data == null) throw Exception('No data received from server');
      
      final userMap = data['user'] as Map<String, dynamic>?;
      if (userMap == null) throw Exception('User data not found in response');
      
      final user = AuthUserModel.fromJson(userMap);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));
      await _updateAccounts(user, data['accessToken'], data['refreshToken']);

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

      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;
          
      final userMap = data['user'] as Map<String, dynamic>;
      final user = AuthUserModel.fromJson(userMap);
      
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUser(jsonEncode(user.toJson()));
      await _updateAccounts(user, data['accessToken'], data['refreshToken']);

      return user;
    } on DioException catch (e) {
      throw Exception(e.response?.statusCode == 401 ? 'Invalid OTP' : (e.response?.data['message'] ?? 'Login failed'));
    }
  }

  @override
  Future<AuthUser?> getAuthenticatedUser() async {
    try {
      final userJson = await _storage.getUser();
      final accessToken = await _storage.getAccessToken();
      
      if (userJson == null || accessToken == null) {
        return null;
      }

      // Verify session with server
      final response = await _apiClient.dio.get('/auth/me');
      final responseData = response.data;
      final data = (responseData is Map && responseData.containsKey('data')) 
          ? responseData['data'] 
          : responseData;

      if (data != null) {
        final user = AuthUserModel.fromJson(data);
        // Update local cache with fresh data
        await _storage.saveUser(jsonEncode(user.toJson()));
        return user;
      }
      
      return null;
    } catch (e) {
      // If server check fails (e.g. 401), clear everything
      await logout();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    // Only clear active session — preserve the saved accounts list for switcher
    await _storage.deleteTokens();
    await _storage.deleteUser();
    // _accountsKey is intentionally NOT deleted here
  }

  @override
  Future<AuthUser> switchAccount(Map<String, dynamic> account) async {
    // account is stored as a flat map: {id, email, name, avatar (string), accessToken, refreshToken}
    // AuthUserModel.fromJson expects avatar as {'url': ...}, so we reconstruct it
    final user = AuthUserModel(
      id: account['id'] ?? '',
      name: account['name'] ?? '',
      email: account['email'] ?? '',
      profileUrl: account['avatar'] ?? '',
    );

    await _storage.saveTokens(
      accessToken: account['accessToken'],
      refreshToken: account['refreshToken'],
    );
    await _storage.saveUser(jsonEncode(user.toJson()));

    return user;
  }

  Future<void> _updateAccounts(AuthUser user, String accessToken, String refreshToken) async {
    await _storage.saveAccount(
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.profileUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

