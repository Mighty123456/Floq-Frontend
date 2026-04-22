import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository repository;
  StreamSubscription? _subscription;

  NotificationsBloc({required this.repository}) : super(const NotificationsState()) {
    on<LoadNotificationsRequested>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotificationRequested>(_onDeleteNotification);
    on<NewNotificationReceived>(_onNewNotification);

    _subscription = repository.onNotification.listen((notification) {
      add(NewNotificationReceived(notification));
    });
  }

  Future<void> _onLoadNotifications(LoadNotificationsRequested event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final notifications = await repository.getNotifications();
      emit(state.copyWith(notifications: notifications, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onMarkAsRead(MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    try {
      await repository.markAsRead(event.id);
      final updated = state.notifications.map((n) {
        return n.id == event.id ? n.copyWith(isRead: true) : n;
      }).toList();
      emit(state.copyWith(notifications: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(MarkAllNotificationsAsRead event, Emitter<NotificationsState> emit) async {
    try {
      await repository.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(state.copyWith(notifications: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteNotification(DeleteNotificationRequested event, Emitter<NotificationsState> emit) async {
    try {
      await repository.deleteNotification(event.id);
      final updated = state.notifications.where((n) => n.id != event.id).toList();
      emit(state.copyWith(notifications: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onNewNotification(NewNotificationReceived event, Emitter<NotificationsState> emit) {
    final updated = [event.notification, ...state.notifications];
    emit(state.copyWith(notifications: updated));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
