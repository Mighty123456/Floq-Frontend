import 'dart:async';
import 'package:dio/dio.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/api_client.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient _apiClient;
  final SocketService _socketService;
  
  ChatRepositoryImpl(this._apiClient, this._socketService);

  
  final _messageController = StreamController<List<Message>>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();
  
  List<Message> _currentMessages = [];
  final Map<String, bool> _typingStatus = {};

  @override
  Stream<Map<String, bool>> get typingStream => _typingController.stream;

  @override
  Stream<List<Message>> getMessages(String otherUserId) {
    // 1. Initial fetch from API
    _fetchHistory(otherUserId);

    // 2. Listen for real-time updates
    _socketService.on('newMessage', (data) {
      final newMessage = _parseMessage(data);
      // Only add if it belongs to this chat
      if (newMessage.senderId == otherUserId) {
        _currentMessages.insert(0, newMessage);
        _messageController.add(List.from(_currentMessages));
        // Auto-mark as read if we are in this chat
        markAsRead(otherUserId);
      }
    });

    _socketService.on('messageSent', (data) {
       final message = _parseMessage(data);
       // Remove pending message if any (optional complexity)
       _currentMessages.insert(0, message);
       _messageController.add(List.from(_currentMessages));
    });

    _socketService.on('userTyping', (data) {
       final String userId = data['userId'];
       final bool isTyping = data['isTyping'];
       _typingStatus[userId] = isTyping;
       _typingController.add(Map.from(_typingStatus));
    });

    _socketService.on('messagesRead', (data) {
       final String byUserId = data['byUserId'];
       // Update logic for locally sent messages to 'read' status
       if (byUserId == otherUserId) {
         for (var i = 0; i < _currentMessages.length; i++) {
           if (_currentMessages[i].senderId != otherUserId) {
             _currentMessages[i] = _currentMessages[i].copyWith(status: 'read');
           }
         }
         _messageController.add(List.from(_currentMessages));
       }
    });

    _socketService.on('messageDelivered', (data) {
       final String messageId = data['messageId'];
       // Update all messages from 'sent' to 'delivered' for this recipient? 
       // Or just this specific one. Usually, "delivered" is per message.
       for (var i = 0; i < _currentMessages.length; i++) {
         if (_currentMessages[i].id == messageId) {
           _currentMessages[i] = _currentMessages[i].copyWith(status: 'delivered');
           break;
         }
       }
       _messageController.add(List.from(_currentMessages));
    });

    _socketService.on('messageDeleted', (data) {
       final String messageId = data['messageId'];
       _currentMessages.removeWhere((m) => m.id == messageId);
       _messageController.add(List.from(_currentMessages));
    });

    return _messageController.stream;
  }

  Future<void> _fetchHistory(String otherUserId) async {
    try {
      final response = await _apiClient.dio.get('/chat/history/$otherUserId');
      if (response.data['success']) {
        final List histories = response.data['data'];
        _currentMessages = histories.map((m) => _parseMessage(m)).toList().reversed.toList();
        _messageController.add(_currentMessages);
      }
    } catch (e) {
      // Error fetching history
    }
  }

  @override
  Future<void> sendMessage(Message message) async {
    _socketService.emit('sendMessage', {
      'receiverId': message.id, // Recipient ID stored in 'id' during creation
      'content': message.content,
      'type': message.type.name,
      'media': message.mediaUrl != null ? {'url': message.mediaUrl} : null,
    });
  }

  @override
  Future<void> sendTypingStatus(String receiverId, bool isTyping) async {
    _socketService.emit('typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  @override
  Future<void> markAsRead(String senderId) async {
    _socketService.emit('markRead', {
      'senderId': senderId,
    });
  }

  @override
  Future<void> deleteMessage(String messageId, {String? receiverId, String? groupId}) async {
    _socketService.emit('deleteMessage', {
      'messageId': messageId,
      'receiverId': receiverId,
      'groupId': groupId,
    });
    // Optimistic delete
    _currentMessages.removeWhere((m) => m.id == messageId);
    _messageController.add(List.from(_currentMessages));
  }

  @override
  Future<void> markAsSpam(String userId) async {
    await _apiClient.dio.post('/chat/spam/$userId');
  }

  @override
  Future<void> unmarkAsSpam(String userId) async {
    await _apiClient.dio.post('/chat/unspam/$userId');
  }

  @override
  Future<String> uploadMedia(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _apiClient.dio.post('/chat/media', data: formData);
    return response.data['url'];
  }


  @override
  Future<void> toggleSaveMessage(String messageId, bool isSaved) async {
    await _apiClient.dio.post('/chat/save/$messageId', data: {'isSaved': isSaved});
  }

  @override
  Future<List<Message>> getSavedMessages() async {
    try {
      final response = await _apiClient.dio.get('/chat/saved');
      if (response.data['success']) {
        final List saved = response.data['data'];
        return saved.map((m) => _parseMessage(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<dynamic>> getSpamUsers() async {
    try {
      final response = await _apiClient.dio.get('/chat/spam-list');
      if (response.data['success']) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  Message _parseMessage(dynamic m) {
    return Message(
      id: m['_id'] ?? '',
      content: m['content'] ?? '',
      senderId: m['sender'] is Map ? m['sender']['_id'] : m['sender'].toString(),
      timestamp: DateTime.parse(m['createdAt']),
      type: _parseType(m['type']),
      status: m['isRead'] == true 
          ? 'read' 
          : (m['isDelivered'] == true ? 'delivered' : 'sent'),
      mediaUrl: m['media'] != null ? m['media']['url'] : null,
      isSaved: m['isSaved'] ?? false,
      metadata: m['metadata'],
    );
  }


  MessageType _parseType(String? type) {
    return MessageType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => MessageType.text,
    );
  }
}
