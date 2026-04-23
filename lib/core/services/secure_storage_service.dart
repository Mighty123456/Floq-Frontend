import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';
  static const _rememberMeKey = 'remember_me';
  static const _savedEmailKey = 'saved_email';
  static const _accountsKey = 'multi_accounts'; // Stores list of {id, email, name, avatar, accessToken, refreshToken}

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
    final email = await getSavedEmail();
    final remember = await getRememberMe();
    // Preserve accounts list before wiping storage
    final accountsJson = await _storage.read(key: _accountsKey);
    await _storage.deleteAll();
    if (remember && email != null) {
      await saveEmail(email);
      await saveRememberMe(true);
    }
    // Restore accounts list so switcher still works
    if (accountsJson != null) {
      await _storage.write(key: _accountsKey, value: accountsJson);
    }
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }

  // --- Multi-Account Support ---

  Future<void> saveAccount({
    required String id,
    required String email,
    required String name,
    String? avatar,
    required String accessToken,
    required String refreshToken,
  }) async {
    final accountsJson = await _storage.read(key: _accountsKey);
    List<dynamic> accounts = [];
    if (accountsJson != null) {
      accounts = jsonDecode(accountsJson);
    }

    final newAccount = {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'lastUsed': DateTime.now().toIso8601String(),
    };

    // Replace if exists, else add
    final index = accounts.indexWhere((a) => a['id'] == id || a['email'] == email);
    if (index != -1) {
      accounts[index] = newAccount;
    } else {
      accounts.add(newAccount);
    }

    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(accountsJson));
  }

  Future<void> removeAccount(String id) async {
    final accountsJson = await _storage.read(key: _accountsKey);
    if (accountsJson != null) {
      List<dynamic> accounts = jsonDecode(accountsJson);
      accounts.removeWhere((a) => a['id'] == id);
      await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
    }
  }
}

