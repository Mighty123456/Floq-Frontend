import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadMessages extends ChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);
  @override
  List<Object> get props => [chatId];
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object> get props => [messages];
}

class SendTextMessage extends ChatEvent {
  final String text;
  final String receiverId;
  const SendTextMessage(this.text, this.receiverId);
  @override
  List<Object> get props => [text, receiverId];
}

class SendImageMessage extends ChatEvent {
  final String imagePath;
  final String receiverId;
  const SendImageMessage(this.imagePath, this.receiverId);
  @override
  List<Object> get props => [imagePath, receiverId];
}

class SendDocumentMessage extends ChatEvent {
  final String fileName;
  final String receiverId;
  const SendDocumentMessage(this.fileName, this.receiverId);
  @override
  List<Object> get props => [fileName, receiverId];
}

class SendLocationMessage extends ChatEvent {
  final double lat;
  final double lng;
  final String receiverId;
  const SendLocationMessage(this.lat, this.lng, this.receiverId);
  @override
  List<Object> get props => [lat, lng, receiverId];
}

class SendContactMessage extends ChatEvent {
  final String contactName;
  final String receiverId;
  const SendContactMessage(this.contactName, this.receiverId);
  @override
  List<Object> get props => [contactName, receiverId];
}

class SendAudioMessage extends ChatEvent {
  final String receiverId;
  const SendAudioMessage(this.receiverId);
}
class SendPollMessage extends ChatEvent {
  final String receiverId;
  const SendPollMessage(this.receiverId);
}
class SendEventMessage extends ChatEvent {
  final String receiverId;
  const SendEventMessage(this.receiverId);
}
class SendAIImageMessage extends ChatEvent {
  final String receiverId;
  const SendAIImageMessage(this.receiverId);
}

class UpdateTypingStatus extends ChatEvent {
  final String receiverId;
  final bool isTyping;
  const UpdateTypingStatus(this.receiverId, this.isTyping);
}

class TypingStatusChanged extends ChatEvent {
  final bool isTyping;
  const TypingStatusChanged(this.isTyping);
}

class MarkMessagesRead extends ChatEvent {
  final String senderId;
  const MarkMessagesRead(this.senderId);
}

class DeleteMessage extends ChatEvent {
  final String messageId;
  final String? receiverId;
  final String? groupId;
  const DeleteMessage(this.messageId, {this.receiverId, this.groupId});
  @override
  List<Object> get props => [messageId, receiverId ?? '', groupId ?? ''];
}


class MarkAsSpam extends ChatEvent {
  final String userId;
  const MarkAsSpam(this.userId);
  @override
  List<Object> get props => [userId];
}

class UnmarkAsSpam extends ChatEvent {
  final String userId;
  const UnmarkAsSpam(this.userId);
  @override
  List<Object> get props => [userId];
}

class ToggleSaveMessage extends ChatEvent {
  final String messageId;
  final bool isSaved;
  const ToggleSaveMessage(this.messageId, this.isSaved);
  @override
  List<Object> get props => [messageId, isSaved];
}

class LoadSavedMessages extends ChatEvent {
  const LoadSavedMessages();
}

class LoadSpamUsers extends ChatEvent {
  const LoadSpamUsers();
}

