import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  UserProfileEntity _currentProfile = UserProfileEntity(
    id: 'u1',
    name: 'John Doe',
    email: 'johndoe@example.com',
  );

  @override
  Future<UserProfileEntity> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentProfile;
  }

  @override
  Future<void> updateProfile({required String name, required String email, String? imagePath}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentProfile = _currentProfile.copyWith(
      name: name,
      email: email,
      profileImagePath: imagePath,
    );
  }

  @override
  Future<void> changePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Implementation for changing password
  }

  @override
  Future<void> toggleTheme(bool isDark) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentProfile = _currentProfile.copyWith(isDarkTheme: isDark);
  }

  @override
  Future<void> toggleNotifications(bool isEnabled) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentProfile = _currentProfile.copyWith(isNotificationsEnabled: isEnabled);
  }

  @override
  Future<void> updatePrivacy(bool showOnlineStatus, bool allowFriendRequests) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentProfile = _currentProfile.copyWith(
      showOnlineStatus: showOnlineStatus,
      allowFriendRequests: allowFriendRequests,
    );
  }
}
