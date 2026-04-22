import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message_entity.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<LoadMessages>(_onLoadMessages);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SendTextMessage>(_onSendText);
    on<SendImageMessage>(_onSendImage);
    on<SendDocumentMessage>(_onSendDocument);
    on<SendLocationMessage>(_onSendLocation);
    on<SendContactMessage>(_onSendContact);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<TypingStatusChanged>(_onTypingStatusChanged);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkAsSpam>(_onMarkAsSpam);
    on<UnmarkAsSpam>(_onUnmarkAsSpam);
    on<ToggleSaveMessage>(_onToggleSaveMessage);
    on<LoadSavedMessages>(_onLoadSavedMessages);
    on<LoadSpamUsers>(_onLoadSpamUsers);
    on<SendAudioMessage>(_onSendAudio);
    on<SendPollMessage>(_onSendPoll);
    on<SendEventMessage>(_onSendEvent);
    on<SendAIImageMessage>(_onSendAIImage);
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    await _messageSubscription?.cancel();
    _messageSubscription = repository.getMessages(event.chatId).listen((messages) {
      add(MessagesUpdated(messages));
    });

    await _typingSubscription?.cancel();
    _typingSubscription = repository.typingStream.listen((status) {
      final isTyping = status[event.chatId] ?? false;
      add(TypingStatusChanged(isTyping));
    });
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(messages: event.messages, isLoading: false));
  }

  void _onTypingStatusChanged(TypingStatusChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(isTyping: event.isTyping));
  }

  Future<void> _onUpdateTypingStatus(UpdateTypingStatus event, Emitter<ChatState> emit) async {
    await repository.sendTypingStatus(event.receiverId, event.isTyping);
  }

  Future<void> _onMarkMessagesRead(MarkMessagesRead event, Emitter<ChatState> emit) async {
    await repository.markAsRead(event.senderId);
  }

  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    await repository.deleteMessage(event.messageId, receiverId: event.receiverId, groupId: event.groupId);
  }


  Future<void> _onMarkAsSpam(MarkAsSpam event, Emitter<ChatState> emit) async {
    await repository.markAsSpam(event.userId);
  }

  Future<void> _onUnmarkAsSpam(UnmarkAsSpam event, Emitter<ChatState> emit) async {
    await repository.unmarkAsSpam(event.userId);
  }

  Future<void> _onSendText(SendTextMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: event.text,
      type: MessageType.text,
      senderId: 'me',
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(message);
    add(UpdateTypingStatus(event.receiverId, false)); // Reset typing on send
  }

  Future<void> _onSendImage(SendImageMessage event, Emitter<ChatState> emit) async {
    try {
      final mediaUrl = await repository.uploadMedia(event.imagePath);
      final message = Message(
        id: event.receiverId,
        content: "[Image]",
        type: MessageType.image,
        senderId: 'me',
        timestamp: DateTime.now(),
        mediaUrl: mediaUrl,
      );
      await repository.sendMessage(message);
    } catch (e) {
      // Handle upload error
    }
  }


  Future<void> _onSendDocument(SendDocumentMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: event.fileName,
      type: MessageType.document,
      senderId: 'me',
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(message);
  }

  Future<void> _onSendLocation(SendLocationMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: "${event.lat},${event.lng}",
      type: MessageType.location,
      senderId: 'me',
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(message);
  }

  Future<void> _onSendContact(SendContactMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: event.contactName,
      type: MessageType.contact,
      senderId: 'me',
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(message);
  }

  Future<void> _onToggleSaveMessage(ToggleSaveMessage event, Emitter<ChatState> emit) async {
    await repository.toggleSaveMessage(event.messageId, event.isSaved);
    // Locally update messages list if the message is present
    final updatedMessages = state.messages.map((m) {
      if (m.id == event.messageId) return m.copyWith(isSaved: event.isSaved);
      return m;
    }).toList();
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onLoadSavedMessages(LoadSavedMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    final saved = await repository.getSavedMessages();
    emit(state.copyWith(savedMessages: saved, isLoading: false));
  }

  Future<void> _onLoadSpamUsers(LoadSpamUsers event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    final spam = await repository.getSpamUsers();
    emit(state.copyWith(spamUsers: spam, isLoading: false));
  }

  Future<void> _onSendAudio(SendAudioMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: "[Audio Message]",
      type: MessageType.audio,
      senderId: 'me',
      timestamp: DateTime.now(),
    );
    await repository.sendMessage(message);
  }

  Future<void> _onSendPoll(SendPollMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: "Poll: Which vibe today?",
      type: MessageType.poll,
      senderId: 'me',
      timestamp: DateTime.now(),
      metadata: {'options': ['Relaxing', 'Energetic', 'Creative'], 'totalVotes': 0},
    );
    await repository.sendMessage(message);
  }

  Future<void> _onSendEvent(SendEventMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: "Floq Meetup! 🚀",
      type: MessageType.event,
      senderId: 'me',
      timestamp: DateTime.now(),
      metadata: {'date': '2026-05-15', 'time': '18:00', 'location': 'Central Hub'},
    );
    await repository.sendMessage(message);
  }

  Future<void> _onSendAIImage(SendAIImageMessage event, Emitter<ChatState> emit) async {
    final message = Message(
      id: event.receiverId,
      content: "AI Generated Masterpiece 🎨",
      type: MessageType.ai,
      senderId: 'me',
      timestamp: DateTime.now(),
      mediaUrl: "https://picsum.photos/seed/ai_gen/800/800",
    );
    await repository.sendMessage(message);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    return super.close();
  }
}
