import 'package:equatable/equatable.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

class MessagingState extends Equatable {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isActionLoading;
  final String? error;
  final ConversationModel? createdConversation;

  const MessagingState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.createdConversation,
  });

  MessagingState copyWith({
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    ConversationModel? createdConversation,
    bool clearCreatedConversation = false,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      createdConversation: clearCreatedConversation ? null : (createdConversation ?? this.createdConversation),
    );
  }

  @override
  List<Object?> get props => [conversations, messages, isLoading, isActionLoading, error, createdConversation];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial() : super();
}
