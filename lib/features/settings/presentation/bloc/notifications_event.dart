import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsRequested extends NotificationsEvent {}

class MarkNotificationAsRead extends NotificationsEvent {
  final String id;
  const MarkNotificationAsRead(this.id);
}

class MarkAllNotificationsAsRead extends NotificationsEvent {}

class DeleteNotificationRequested extends NotificationsEvent {
  final String id;
  const DeleteNotificationRequested(this.id);
}

class NewNotificationReceived extends NotificationsEvent {
  final NotificationEntity notification;
  const NewNotificationReceived(this.notification);
}
