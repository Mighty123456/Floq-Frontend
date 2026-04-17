import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message_entity.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<SendTextMessage>(_onSendText);
    on<SendImageMessage>(_onSendImage);
    on<SendDocumentMessage>(_onSendDocument);
    on<SendLocationMessage>(_onSendLocation);
    on<SendContactMessage>(_onSendContact);
    on<SendAudioMessage>(_onSendAudio);
    on<SendPollMessage>(_onSendPoll);
    on<SendEventMessage>(_onSendEvent);
    on<SendAIImageMessage>(_onSendAIImage);
  }

  void _addMessageToState(Emitter<ChatState> emit, Message message) {
    emit(state.copyWith(messages: [message, ...state.messages]));
    // repository.sendMessage(message);
  }

  void _onSendText(SendTextMessage event, Emitter<ChatState> emit) {
    if (event.text.trim().isEmpty) return;
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: event.text,
      type: MessageType.text,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendImage(SendImageMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: event.imagePath,
      type: MessageType.image,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendDocument(SendDocumentMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: event.fileName,
      type: MessageType.document,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendLocation(SendLocationMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: '${event.lat}, ${event.lng}',
      type: MessageType.location,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendContact(SendContactMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: event.contactName,
      type: MessageType.contact,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendAudio(SendAudioMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: 'Audio message',
      type: MessageType.audio,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendPoll(SendPollMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: 'Which feature do you like most?',
      type: MessageType.poll,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendEvent(SendEventMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: 'Meeting Tomorrow at 10 AM',
      type: MessageType.event,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }

  void _onSendAIImage(SendAIImageMessage event, Emitter<ChatState> emit) {
    _addMessageToState(emit, Message(
      id: DateTime.now().toString(),
      content: 'AI Generated Image',
      type: MessageType.ai,
      senderId: 'me',
      timestamp: DateTime.now(),
    ));
  }
}
