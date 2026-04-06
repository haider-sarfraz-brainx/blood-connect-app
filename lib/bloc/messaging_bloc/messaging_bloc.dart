import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/remote/messaging/messaging_repository.dart';
import '../../data/models/message_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/managers/local/session_manager.dart';
import '../../data/repositories/remote/notifications/notification_repository.dart';

import 'messaging_events.dart';
import 'messaging_states.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository _messagingRepository;
  final SessionManager _sessionManager;
  final NotificationRepository _notificationRepository;

  String get _currentUserId => _sessionManager.getUser()?.id ?? '';
  String get _currentUserName => _sessionManager.getUser()?.name ?? 'Someone';

  StreamSubscription<List<ConversationModel>>? _conversationsSubscription;
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  MessagingBloc({
    required MessagingRepository messagingRepository,
    required SessionManager sessionManager,
    required NotificationRepository notificationRepository,
  })  : _messagingRepository = messagingRepository,
        _sessionManager = sessionManager,
        _notificationRepository = notificationRepository,
        super(const MessagingState()) {

    on<LoadConversationsEvent>(_onLoadConversations);
    on<CreateConversationEvent>(_onCreateConversation);
    on<AcceptConversationEvent>(_onAcceptConversation);
    on<AcceptHelpEvent>(_onAcceptHelp);
    on<SendMessageEvent>(_onSendMessage);
    on<StreamConversationsEvent>(_onStreamConversations);
    on<StreamMessagesEvent>(_onStreamMessages);
    on<DeclineConversationEvent>(_onDeclineConversation);
    on<BlockConversationEvent>(_onBlockConversation);
    on<UnblockConversationEvent>(_onUnblockConversation);
    on<ReportConversationEvent>(_onReportConversation);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<_UpdateConversations>((event, emit) {
      final sorted = List<ConversationModel>.from(event.conversations)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      emit(state.copyWith(conversations: sorted));
    });
    on<_UpdateMessages>((event, emit) {
      final sorted = List<MessageModel>.from(event.messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      emit(state.copyWith(messages: sorted, isLoading: false));
    });
    on<_MessagingErrorEvent>((event, emit) => emit(state.copyWith(error: event.message, isLoading: false)));
    on<ResetCreatedConversationEvent>((event, emit) => emit(state.copyWith(clearCreatedConversation: true)));
    on<StopStreamMessagesEvent>((event, emit) {
      _messagesSubscription?.cancel();
      _messagesSubscription = null;
      emit(state.copyWith(messages: []));
    });
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final conversations = await _messagingRepository.getConversations();
      emit(state.copyWith(conversations: conversations, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final conversation = await _messagingRepository.createConversation(
        recipientId: event.recipientId,
        requestId: event.requestId,
        initialMessage: event.initialMessage,
      );
      emit(state.copyWith(createdConversation: conversation, isLoading: false));

      // Send Notification to recipient
      _notificationRepository.sendMessageRequestNotification(
        recipientId: event.recipientId,
        senderName: _currentUserName,
        requestId: event.requestId,
      );

    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onAcceptHelp(
    AcceptHelpEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isActionLoading: true));
    try {
      await _messagingRepository.updateConversationStatusByRequestId(
        event.requestId,
        ConversationStatus.accepted,
      );
      emit(state.copyWith(isActionLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isActionLoading: false));
    }
  }

  Future<void> _onAcceptConversation(
    AcceptConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isActionLoading: true));
    try {
      final updated = await _messagingRepository.updateConversationStatus(
        event.conversationId,
        ConversationStatus.accepted,
      );

      // Send Notification to recipient (the one who initiated the request)
      _notificationRepository.sendMessageApprovedNotification(
        recipientId: updated.initiatorId,
        senderName: _currentUserName,
      );

      
      // Update local state immediately for better UX
      final updatedConversations = state.conversations.map((c) {
        return c.id == event.conversationId ? updated : c;
      }).toList();
      
      emit(state.copyWith(
        conversations: updatedConversations,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isActionLoading: false));
    }
  }

  Future<void> _onDeclineConversation(
    DeclineConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isActionLoading: true));
    try {
      final updated = await _messagingRepository.updateConversationStatus(
        event.conversationId,
        ConversationStatus.rejected,
      );

      // Update local state immediately
      final updatedConversations = state.conversations.map((c) {
        return c.id == event.conversationId ? updated : c;
      }).toList();

      emit(state.copyWith(
        conversations: updatedConversations,
        isActionLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isActionLoading: false));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final message = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: event.conversationId,
      senderId: _currentUserId,
      content: event.content,
      createdAt: DateTime.now(),
    );

    // Optimistic UI update
    final newMessages = List<MessageModel>.from(state.messages)..add(message);
    emit(state.copyWith(messages: newMessages));

    try {
      await _messagingRepository.sendMessage(message);
    } catch (e) {
      // Revert optimism if error or just show error
      emit(state.copyWith(error: e.toString()));
      // We don't necessarily need to remove the temp message if the stream will eventually handle it
    }
  }

  Future<void> _onStreamConversations(
    StreamConversationsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    _conversationsSubscription?.cancel();
    
    // Initial fetch to get names (stream doesn't support joins)
    try {
      final initial = await _messagingRepository.getConversations();
      add(_UpdateConversations(initial));
    } catch (_) {}

    _conversationsSubscription = _messagingRepository.getConversationsStream().listen(
      (conversations) {
        // Preserving names from existing state if not in stream
        final enriched = conversations.map((newConv) {
          final existing = state.conversations.firstWhere(
            (c) => c.id == newConv.id,
            orElse: () => newConv,
          );
          if (newConv.initiatorName == null && newConv.recipientName == null) {
            return newConv.copyWith(
              initiatorName: existing.initiatorName,
              recipientName: existing.recipientName,
            );
          }
          return newConv;
        }).toList();
        add(_UpdateConversations(enriched));
      },
      onError: (e) => add(_MessagingErrorEvent(e.toString())),
    );
  }

  Future<void> _onStreamMessages(
    StreamMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, messages: []));
    _messagesSubscription?.cancel();
    
    // Initial fetch
    try {
      final initial = await _messagingRepository.getMessages(event.conversationId);
      add(_UpdateMessages(initial));
    } catch (_) {}

    _messagesSubscription = _messagingRepository.getMessagesStream(event.conversationId).listen(
      (messages) => add(_UpdateMessages(messages)),
      onError: (e) => add(_MessagingErrorEvent(e.toString())),
    );
  }

  Future<void> _onBlockConversation(
    BlockConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.blockConversation(event.conversationId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUnblockConversation(
    UnblockConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.unblockConversation(event.conversationId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onReportConversation(
    ReportConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _messagingRepository.reportConversation(
        conversationId: event.conversationId,
        reason: event.reason,
        details: event.details,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversationEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final previousConversations = List<ConversationModel>.from(state.conversations);
    try {
      // Optimistic update
      final updated = List<ConversationModel>.from(state.conversations)
          ..removeWhere((c) => c.id == event.conversationId);
      emit(state.copyWith(conversations: updated));
      
      await _messagingRepository.deleteConversation(event.conversationId);
    } catch (e) {
      // Rollback on error
      emit(state.copyWith(
        conversations: previousConversations,
        error: e.toString(),
      ));
    }
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

class _MessagingErrorEvent extends MessagingEvent {
  final String message;
  const _MessagingErrorEvent(this.message);
}

class ResetCreatedConversationEvent extends MessagingEvent {}
