import 'dart:async';
import 'package:dio/dio.dart';
import 'secure_storage_service.dart';
import 'socket_service.dart';

class ApiClient {
  late Dio dio;
  final SecureStorageService _storage = SecureStorageService();
  bool _isRefreshing = false;
  final List<void Function(String)> _refreshWaiters = [];

  static const String renderBaseUrl = "https://floq-backend.onrender.com";
  static const String vercelBaseUrl = "https://floq-backend-2uh3.vercel.app";
  
  static final _logoutController = StreamController<void>.broadcast();
  static Stream<void> get logoutStream => _logoutController.stream;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: renderBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Route Register and OTP related requests to Vercel
        final otpPaths = [
          '/auth/register',
          '/auth/verify-otp',
          '/auth/forgot-password',
          '/auth/reset-password',
          '/auth/resend-otp',
          '/auth/request-login-otp',
          '/auth/login-otp'
        ];

        if (otpPaths.any((path) => options.path.contains(path))) {
          options.baseUrl = vercelBaseUrl;
        } else {
          options.baseUrl = renderBaseUrl;
        }

        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && 
            e.requestOptions.path != '/auth/refresh-token' &&
            e.requestOptions.path != '/auth/login') {
          
          if (_isRefreshing) {
            // Queue this request
            _refreshWaiters.add((newToken) {
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              dio.fetch(e.requestOptions).then(
                (response) => handler.resolve(response),
                onError: (err) => handler.reject(err),
              );
            });
            return;
          }

          _isRefreshing = true;
          final success = await _refreshToken();
          
          if (success) {
            final newToken = await _storage.getAccessToken();
            _isRefreshing = false;
            
            // Resume all waiting requests
            for (var waiter in _refreshWaiters) {
              waiter(newToken!);
            }
            _refreshWaiters.clear();
            
            // Sync with socket
            SocketService().updateToken(newToken!);

            // Retry current request
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } else {
            _isRefreshing = false;
            _refreshWaiters.clear();
            await _storage.clearAll();
            _logoutController.add(null);
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final dioFresh = Dio(BaseOptions(baseUrl: renderBaseUrl));
      final response = await dioFresh.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final data = response.data['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      // Refresh token itself failed/expired
    }
    return false;
  }
}

