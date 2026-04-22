import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/api_client.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient _apiClient;
  final SocketService _socketService;
  io.Socket? _nspSocket;
  final _notificationController = StreamController<NotificationEntity>.broadcast();

  NotificationsRepositoryImpl(this._apiClient, this._socketService) {
    _initSocket();
  }

  Future<void> _initSocket() async {
    _nspSocket = await _socketService.createNamespacedSocket('notifications');
    _nspSocket?.on('newNotification', (data) {
      _notificationController.add(_parseNotification(data));
    });
  }

  @override
  Stream<NotificationEntity> get onNotification => _notificationController.stream;

  @override
  Future<List<NotificationEntity>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      final List data = response.data['data'];
      return data.map((n) => _parseNotification(n)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    await _apiClient.dio.patch('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _apiClient.dio.patch('/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
     await _apiClient.dio.delete('/notifications/$id');
  }

  NotificationEntity _parseNotification(dynamic json) {
    final sender = json['sender'];
    return NotificationEntity(
      id: json['_id'],
      senderId: sender['_id'],
      senderName: sender['fullName'] ?? sender['username'] ?? 'Unknown',
      senderAvatar: sender['avatar']?['url'] ?? '',
      type: _parseType(json['type']),
      postId: json['post']?['_id'] ?? json['post'], // Could be populated or ID
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  AppNotificationType _parseType(String type) {
    switch (type) {
      case 'like': return AppNotificationType.like;
      case 'comment': return AppNotificationType.comment;
      case 'follow': return AppNotificationType.follow;
      case 'mention': return AppNotificationType.mention;
      case 'repost': return AppNotificationType.repost;
      default: return AppNotificationType.system;
    }
  }
}
