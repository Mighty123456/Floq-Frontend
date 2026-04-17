import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<void> sendMessage(Message message);
  Stream<List<Message>> getMessages(String chatId);
}
