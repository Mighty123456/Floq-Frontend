import 'package:equatable/equatable.dart';
import '../../domain/entities/message_entity.dart';

class ChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [messages, isLoading];
}
