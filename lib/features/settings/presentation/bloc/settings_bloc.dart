import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;

  SettingsBloc({required this.repository}) : super(const SettingsState()) {
    on<LoadProfileRequested>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<ChangePasswordRequested>(_onChangePassword);
    on<ToggleThemeRequested>(_onToggleTheme);
    on<ToggleNotificationsRequested>(_onToggleNotifications);
    on<UpdatePrivacyRequested>(_onUpdatePrivacy);
  }

  Future<void> _onLoadProfile(LoadProfileRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final profile = await repository.getUserProfile();
      emit(state.copyWith(profile: profile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileRequested event, Emitter<SettingsState> emit) async {
    try {
      await repository.updateProfile(name: event.name, email: event.email, imagePath: event.profileImagePath);
      final profile = await repository.getUserProfile();
      emit(state.copyWith(profile: profile));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onChangePassword(ChangePasswordRequested event, Emitter<SettingsState> emit) async {
    try {
      await repository.changePassword(event.newPassword);
      // Not changing state, as password change doesn't modify local profile view
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onToggleTheme(ToggleThemeRequested event, Emitter<SettingsState> emit) async {
    try {
      await repository.toggleTheme(event.isDark);
      final profile = await repository.getUserProfile();
      emit(state.copyWith(profile: profile));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onToggleNotifications(ToggleNotificationsRequested event, Emitter<SettingsState> emit) async {
    try {
      await repository.toggleNotifications(event.isEnabled);
      final profile = await repository.getUserProfile();
      emit(state.copyWith(profile: profile));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdatePrivacy(UpdatePrivacyRequested event, Emitter<SettingsState> emit) async {
    try {
      await repository.updatePrivacy(event.showOnlineStatus, event.allowFriendRequests);
      final profile = await repository.getUserProfile();
      emit(state.copyWith(profile: profile));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
