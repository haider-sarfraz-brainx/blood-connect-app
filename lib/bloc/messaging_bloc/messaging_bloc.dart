import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/remote/messaging/messaging_repository.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import 'messaging_events.dart';
import 'messaging_states.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository _messagingRepository;
  final String _currentUserId;

  StreamSubscription<List<ConversationModel>>? _conversationsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  MessagingBloc({
    required MessagingRepository messagingRepository,
    required String currentUserId,
  })  : _messagingRepository = messagingRepository,
        _currentUserId = currentUserId,
        super(MessagingInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<CreateConversationEvent>(_onCreateConversation);
    on<AcceptConversationEvent>(_onAcceptConversation);
    on<AcceptHelpEvent>(_onAcceptHelp);
    on<SendMessageEvent>(_onSendMessage);
    on<StreamConversationsEvent>(_onStreamConversations);
    on<StreamMessagesEvent>(_onStreamMessages);
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    try {
      final conversations = await _messagingRepository.getConversations();
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    try {
      final conversation = await _messagingRepository.createConversation(
        recipientId: event.recipientId,
        requestId: event.requestId,
        initialMessage: event.initialMessage,
      );
      emit(ConversationCreated(conversation));
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> _onAcceptHelp(
    AcceptHelpEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.updateConversationStatusByRequestId(
        event.requestId,
        ConversationStatus.accepted,
      );
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> _onAcceptConversation(
    AcceptConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.updateConversationStatus(
        event.conversationId,
        ConversationStatus.accepted,
      );
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      final message = MessageModel(
        id: '',
        conversationId: event.conversationId,
        senderId: _currentUserId,
        content: event.content,
        createdAt: DateTime.now(),
      );
      await _messagingRepository.sendMessage(message);
    } catch (e) {
      emit(MessagingError(e.toString()));
    }
  }

  void _onStreamConversations(
    StreamConversationsEvent event,
    Emitter<MessagingState> emit,
  ) {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _messagingRepository.getConversationsStream().listen(
      (conversations) => add(_UpdateConversations(conversations)),
      onError: (e) => emit(MessagingError(e.toString())),
    );
    
    on<_UpdateConversations>((event, emit) => emit(ConversationsLoaded(event.conversations)));
  }

  void _onStreamMessages(
    StreamMessagesEvent event,
    Emitter<MessagingState> emit,
  ) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _messagingRepository.getMessagesStream(event.conversationId).listen(
      (messages) => add(_UpdateMessages(messages)),
      onError: (e) => emit(MessagingError(e.toString())),
    );

    on<_UpdateMessages>((event, emit) => emit(MessagesLoaded(event.messages)));
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}

class _UpdateConversations extends MessagingEvent {
  final List<ConversationModel> conversations;
  const _UpdateConversations(this.conversations);
}

class _UpdateMessages extends MessagingEvent {
  final List<MessageModel> messages;
  const _UpdateMessages(this.messages);
}
