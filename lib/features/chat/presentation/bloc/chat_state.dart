import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;

  final bool isTyping;
  final bool isOnline;
  final List<Message> savedMessages;
  final List<dynamic> spamUsers;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.isOnline = true,
    this.savedMessages = const [],
    this.spamUsers = const [],
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isTyping,
    bool? isOnline,
    List<Message>? savedMessages,
    List<dynamic>? spamUsers,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
      savedMessages: savedMessages ?? this.savedMessages,
      spamUsers: spamUsers ?? this.spamUsers,
    );
  }

  @override
  List<Object> get props => [messages, isLoading, isTyping, isOnline, savedMessages, spamUsers];
}
