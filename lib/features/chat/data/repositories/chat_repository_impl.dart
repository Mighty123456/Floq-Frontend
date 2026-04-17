import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  @override
  Stream<List<Message>> getMessages(String chatId) {
    return Stream.value([
      Message(
        id: '1',
        senderId: 'other',
        content: 'Hey! How is the project going?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        type: MessageType.text,
      ),
      Message(
        id: '2',
        senderId: 'me',
        content: 'It\'s going great! Just finished the new UI updates.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        type: MessageType.text,
      ),
      Message(
        id: '3',
        senderId: 'other',
        content: 'Awesome! Can you send me a screenshot?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: MessageType.text,
      ),
      Message(
        id: '4',
        senderId: 'me',
        content: 'Sure, here it is!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        type: MessageType.text,
      ),
    ].reversed.toList());
  }

  @override
  Future<void> sendMessage(Message message) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

