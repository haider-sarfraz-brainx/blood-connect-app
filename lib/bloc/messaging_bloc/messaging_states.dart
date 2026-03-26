import 'package:equatable/equatable.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class ConversationsLoaded extends MessagingState {
  final List<ConversationModel> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends MessagingState {
  final List<MessageModel> messages;

  const MessagesLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessagingError extends MessagingState {
  final String message;

  const MessagingError(this.message);

  @override
  List<Object?> get props => [message];
}

class ConversationCreated extends MessagingState {
  final ConversationModel conversation;

  const ConversationCreated(this.conversation);

  @override
  List<Object?> get props => [conversation];
}
