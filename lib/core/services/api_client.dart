import 'package:dio/dio.dart';
import 'secure_storage_service.dart';

class ApiClient {
  late Dio dio;
  final SecureStorageService _storage = SecureStorageService();

  static const String renderBaseUrl = "https://floq-backend.onrender.com";
  static const String vercelBaseUrl = "https://floq-backend-2uh3.vercel.app";

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: renderBaseUrl, // Default to Render
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
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
        if (e.response?.statusCode == 401 && e.requestOptions.path != '/auth/refresh-token') {
          // Attempting to refresh token
          final success = await _refreshToken();
          if (success) {
            // Retry the original request with new token
            final token = await _storage.getAccessToken();
            e.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(e.requestOptions);
            return handler.resolve(response);
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
      final response = await dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (e) {
      await _storage.clearAll();
    }
    return false;
  }
}
