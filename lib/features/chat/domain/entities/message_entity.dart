enum MessageType { text, image, document, location, contact, audio, poll, event, ai }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final String senderId;
  final DateTime timestamp;
  final String status;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.timestamp,
    this.status = 'sent',
  });
}
