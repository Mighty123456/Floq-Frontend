import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class SendTextMessage extends ChatEvent {
  final String text;
  const SendTextMessage(this.text);
  @override
  List<Object> get props => [text];
}

class SendImageMessage extends ChatEvent {
  final String imagePath;
  const SendImageMessage(this.imagePath);
  @override
  List<Object> get props => [imagePath];
}

class SendDocumentMessage extends ChatEvent {
  final String fileName;
  const SendDocumentMessage(this.fileName);
  @override
  List<Object> get props => [fileName];
}

class SendLocationMessage extends ChatEvent {
  final double lat;
  final double lng;
  const SendLocationMessage(this.lat, this.lng);
  @override
  List<Object> get props => [lat, lng];
}

class SendContactMessage extends ChatEvent {
  final String contactName;
  const SendContactMessage(this.contactName);
  @override
  List<Object> get props => [contactName];
}

class SendAudioMessage extends ChatEvent {}
class SendPollMessage extends ChatEvent {}
class SendEventMessage extends ChatEvent {}
class SendAIImageMessage extends ChatEvent {}
