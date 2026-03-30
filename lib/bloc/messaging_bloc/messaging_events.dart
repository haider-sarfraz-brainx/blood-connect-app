import 'package:equatable/equatable.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends MessagingEvent {}

class CreateConversationEvent extends MessagingEvent {
  final String recipientId;
  final String? requestId;
  final String initialMessage;

  const CreateConversationEvent({
    required this.recipientId,
    this.requestId,
    required this.initialMessage,
  });

  @override
  List<Object?> get props => [recipientId, requestId, initialMessage];
}

class AcceptConversationEvent extends MessagingEvent {
  final String conversationId;

  const AcceptConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class AcceptHelpEvent extends MessagingEvent {
  final String requestId;

  const AcceptHelpEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class DeclineConversationEvent extends MessagingEvent {
  final String conversationId;

  const DeclineConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessageEvent extends MessagingEvent {
  final String conversationId;
  final String content;

  const SendMessageEvent({
    required this.conversationId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, content];
}

class StreamConversationsEvent extends MessagingEvent {}

class StreamMessagesEvent extends MessagingEvent {
  final String conversationId;

  const StreamMessagesEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class BlockConversationEvent extends MessagingEvent {
  final String conversationId;

  const BlockConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ReportConversationEvent extends MessagingEvent {
  final String conversationId;
  final String reason;
  final String? details;

  const ReportConversationEvent({
    required this.conversationId,
    required this.reason,
    this.details,
  });

  @override
  List<Object?> get props => [conversationId, reason, details];
}

class DeleteConversationEvent extends MessagingEvent {
  final String conversationId;

  const DeleteConversationEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class StopStreamMessagesEvent extends MessagingEvent {}
