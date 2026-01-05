import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static io.Socket? _socket;
  static const String socketUrl = 'http://localhost:3000';

  static io.Socket? get socket => _socket;

  // Initialize socket connection
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('No authentication token found');
    }

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    // Authenticate socket
    _socket!.onConnect((_) {
      _socket!.emit('authenticate', token);
    });

    _socket!.on('authenticated', (data) {
      debugPrint('Socket authenticated: $data');
    });

    _socket!.on('auth_error', (data) {
      debugPrint('Socket auth error: $data');
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  // Join a chat room
  static void joinChat(String chatId) {
    _socket?.emit('join chat', chatId);
  }

  // Leave a chat room
  static void leaveChat(String chatId) {
    _socket?.emit('leave chat', chatId);
  }

  // Send typing indicator
  static void sendTyping(String chatId, String userId) {
    _socket?.emit('typing', {'chatId': chatId, 'userId': userId});
  }

  // Stop typing indicator
  static void stopTyping(String chatId, String userId) {
    _socket?.emit('stop typing', {'chatId': chatId, 'userId': userId});
  }

  // Listen for new messages
  static void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _socket?.on('message received', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen for typing indicators
  static void onTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('typing', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen for stop typing
  static void onStopTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('stop typing', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen for user online status
  static void onUserOnline(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_online', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen for user offline status
  static void onUserOffline(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_offline', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Listen for message read
  static void onMessageRead(Function(Map<String, dynamic>) callback) {
    _socket?.on('message read', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // Emit new message (called after sending via API)
  static void emitNewMessage(Map<String, dynamic> message) {
    _socket?.emit('new message', message);
  }

  // Mark message as read
  static void markMessageRead(String chatId, String messageId) {
    _socket?.emit('message read', {'chatId': chatId, 'messageId': messageId});
  }

  // Disconnect socket
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}

