import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsState extends Equatable {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [notifications, isLoading, error];
}
