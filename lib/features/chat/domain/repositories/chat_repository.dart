import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<void> sendMessage(Message message);
  Stream<List<Message>> getMessages(String otherUserId);
  Future<void> deleteMessage(String messageId, {String? receiverId, String? groupId});
  Future<void> markAsSpam(String userId);
  Future<void> unmarkAsSpam(String userId);
  Future<String> uploadMedia(String filePath);
  Future<void> markAsRead(String senderId);
  Future<void> sendTypingStatus(String receiverId, bool isTyping);
  Stream<Map<String, bool>> get typingStream;
  Future<void> toggleSaveMessage(String messageId, bool isSaved);
  Future<List<Message>> getSavedMessages();
  Future<List<dynamic>> getSpamUsers(); // Returns partial user data
}

