import 'dart:convert';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/api_client.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final _storage = SecureStorageService();
  final _apiClient = ApiClient();
  
  UserProfileEntity? _cachedProfile;

  @override
  Future<UserProfileEntity> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      final map = response.data['data'];
      
      final profile = UserProfileEntity(
        id: map['_id'] ?? 'u1',
        name: (map['fullName'] != null && map['fullName'].toString().isNotEmpty && map['fullName'] != 'Unknown') 
            ? map['fullName'] 
            : (map['username'] ?? (map['email'] != null ? map['email'].split('@')[0] : 'Floq User')),
        email: map['email'] ?? 'No email',
        profileImagePath: (map['avatar'] is Map) ? (map['avatar']['url'] ?? '') : (map['avatar'] ?? ''),
        followersCount: map['followersCount'] ?? 0,
        followingCount: map['followingCount'] ?? 0,
        postsCount: map['postsCount'] ?? 0,
        isDarkTheme: map['settings']?['isDarkTheme'] ?? true,
        isNotificationsEnabled: map['settings']?['isNotificationsEnabled'] ?? true,
        showOnlineStatus: map['settings']?['showOnlineStatus'] ?? true,
        allowFriendRequests: map['settings']?['allowFriendRequests'] ?? true,
      );
      
      _cachedProfile = profile;
      await _storage.saveUser(jsonEncode(map));
      return profile;
    } catch (e) {
      // Fallback to local storage if offline
      final userStr = await _storage.getUser();
      if (userStr != null) {
        final map = jsonDecode(userStr);
        return UserProfileEntity(
          id: map['_id'] ?? 'u1',
          name: (map['fullName'] != null && map['fullName'].toString().isNotEmpty && map['fullName'] != 'Unknown') 
              ? map['fullName'] 
              : (map['username'] ?? (map['email'] != null ? map['email'].split('@')[0] : 'Floq User')),
          email: map['email'] ?? 'No email',
          profileImagePath: (map['avatar'] is Map) ? (map['avatar']['url'] ?? '') : (map['avatar'] ?? ''),
          followersCount: map['followersCount'] ?? 0,
          followingCount: map['followingCount'] ?? 0,
          postsCount: map['postsCount'] ?? 0,
          isDarkTheme: map['settings']?['isDarkTheme'] ?? true,
          isNotificationsEnabled: map['settings']?['isNotificationsEnabled'] ?? true,
          showOnlineStatus: map['settings']?['showOnlineStatus'] ?? true,
          allowFriendRequests: map['settings']?['allowFriendRequests'] ?? true,
        );
      }
      throw Exception('Failed to load profile');
    }
  }

  @override
  Future<void> updateProfile({required String name, required String email, String? imagePath}) async {
    await _apiClient.dio.patch('/users/me', data: {
      'fullName': name,
      'email': email,
    });
    // If imagePath is local, we might need a separate upload step, 
    // but for now we assume the URL is handled or updated via other means.
    await getUserProfile(); // Refresh cache
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await _apiClient.dio.post('/auth/change-password', data: {
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> toggleTheme(bool isDark) async {
    await _apiClient.dio.patch('/users/me', data: {
      'settings': {
        ..._getCurrentSettingsMap(),
        'isDarkTheme': isDark,
      }
    });
    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(isDarkTheme: isDark);
    }
  }

  @override
  Future<void> toggleNotifications(bool isEnabled) async {
    await _apiClient.dio.patch('/users/me', data: {
      'settings': {
        ..._getCurrentSettingsMap(),
        'isNotificationsEnabled': isEnabled,
      }
    });
    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(isNotificationsEnabled: isEnabled);
    }
  }

  @override
  Future<void> updatePrivacy(bool showOnlineStatus, bool allowFriendRequests) async {
    await _apiClient.dio.patch('/users/me', data: {
      'settings': {
        ..._getCurrentSettingsMap(),
        'showOnlineStatus': showOnlineStatus,
        'allowFriendRequests': allowFriendRequests,
      }
    });
    if (_cachedProfile != null) {
      _cachedProfile = _cachedProfile!.copyWith(
        showOnlineStatus: showOnlineStatus,
        allowFriendRequests: allowFriendRequests,
      );
    }
  }

  Map<String, dynamic> _getCurrentSettingsMap() {
    if (_cachedProfile == null) return {};
    return {
      'isDarkTheme': _cachedProfile!.isDarkTheme,
      'isNotificationsEnabled': _cachedProfile!.isNotificationsEnabled,
      'showOnlineStatus': _cachedProfile!.showOnlineStatus,
      'allowFriendRequests': _cachedProfile!.allowFriendRequests,
    };
  }
}
