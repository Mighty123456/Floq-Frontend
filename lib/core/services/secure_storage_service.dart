import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _rememberMeKey = 'remember_me';
  static const _savedEmailKey = 'saved_email';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async => await _storage.read(key: _userKey);

  Future<void> saveRememberMe(bool value) async {
    await _storage.write(key: _rememberMeKey, value: value.toString());
  }

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: _rememberMeKey);
    return val == 'true';
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _savedEmailKey, value: email);
  }

  Future<String?> getSavedEmail() async => await _storage.read(key: _savedEmailKey);

  Future<void> clearAll() async {
    // Keep saved email if remember me is true? 
    // Usually, clearAll is for logout. 
    // We should decide if we clear the email too.
    final email = await getSavedEmail();
    final remember = await getRememberMe();
    await _storage.deleteAll();
    if (remember && email != null) {
      await saveEmail(email);
      await saveRememberMe(true);
    }
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }
}

