import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileRequested extends SettingsEvent {}

class UpdateProfileRequested extends SettingsEvent {
  final String name;
  final String email;
  final String? profileImagePath;

  const UpdateProfileRequested({required this.name, required this.email, this.profileImagePath});

  @override
  List<Object?> get props => [name, email, profileImagePath];
}

class ChangePasswordRequested extends SettingsEvent {
  final String newPassword;
  const ChangePasswordRequested(this.newPassword);
  
  @override
  List<Object?> get props => [newPassword];
}

class ToggleThemeRequested extends SettingsEvent {
  final bool isDark;
  const ToggleThemeRequested(this.isDark);
  
  @override
  List<Object?> get props => [isDark];
}

class ToggleNotificationsRequested extends SettingsEvent {
  final bool isEnabled;
  const ToggleNotificationsRequested(this.isEnabled);
  
  @override
  List<Object?> get props => [isEnabled];
}

class UpdatePrivacyRequested extends SettingsEvent {
  final bool showOnlineStatus;
  final bool allowFriendRequests;
  const UpdatePrivacyRequested(this.showOnlineStatus, this.allowFriendRequests);
  
  @override
  List<Object?> get props => [showOnlineStatus, allowFriendRequests];
}
