enum MessageType { text, image, document, location, contact, audio, poll, event, ai }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final String senderId;
  final DateTime timestamp;
  final String status;
  final String? mediaUrl;
  final bool isSaved;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.timestamp,
    this.status = 'sent',
    this.mediaUrl,
    this.isSaved = false,
    this.metadata,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    String? senderId,
    DateTime? timestamp,
    String? status,
    String? mediaUrl,
    bool? isSaved,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isSaved: isSaved ?? this.isSaved,
      metadata: metadata ?? this.metadata,
    );
  }
}

