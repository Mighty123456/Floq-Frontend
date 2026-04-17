import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile_entity.dart';

class SettingsState extends Equatable {
  final UserProfileEntity? profile;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    UserProfileEntity? profile,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [profile, isLoading, error];
}
