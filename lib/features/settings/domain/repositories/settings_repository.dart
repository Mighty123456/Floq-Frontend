import '../entities/user_profile_entity.dart';

abstract class SettingsRepository {
  Future<UserProfileEntity> getUserProfile();
  Future<void> updateProfile({required String name, required String email, String? imagePath});
  Future<void> changePassword(String newPassword);
  Future<void> toggleTheme(bool isDark);
  Future<void> toggleNotifications(bool isEnabled);
  Future<void> updatePrivacy(bool showOnlineStatus, bool allowFriendRequests);
}
