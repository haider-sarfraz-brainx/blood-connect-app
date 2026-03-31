import '../../../managers/remote/supabase_service.dart';
import '../../../models/conversation_model.dart';
import '../../../models/message_model.dart';

class MessagingRepository {
  final SupabaseService _supabaseService;

  MessagingRepository(this._supabaseService);

  Future<ConversationModel> createConversation({
    required String recipientId,
    String? requestId,
    required String initialMessage,
  }) {
    return _supabaseService.createConversation(
      recipientId: recipientId,
      requestId: requestId,
      initialMessage: initialMessage,
    );
  }

  Future<List<ConversationModel>> getConversations() {
    return _supabaseService.getConversations();
  }

  Future<ConversationModel> updateConversationStatus(String id, ConversationStatus status) {
    return _supabaseService.updateConversationStatus(id, status);
  }

  Future<void> sendMessage(MessageModel message) {
    return _supabaseService.insertMessage(message);
  }

  Future<List<MessageModel>> getMessages(String conversationId) {
    return _supabaseService.getMessages(conversationId);
  }

  Stream<List<ConversationModel>> getConversationsStream() {
    return _supabaseService.getConversationsStream();
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _supabaseService.getMessagesStream(conversationId);
  }

  Future<void> updateConversationStatusByRequestId(String requestId, ConversationStatus status) {
    return _supabaseService.updateConversationStatusByRequestId(requestId, status);
  }

  Future<void> blockConversation(String id) {
    return _supabaseService.blockConversation(id);
  }

  Future<void> unblockConversation(String id) {
    return _supabaseService.unblockConversation(id);
  }

  Future<void> reportConversation({
    required String conversationId,
    required String reason,
    String? details,
  }) {
    return _supabaseService.reportConversation(
      conversationId: conversationId,
      reason: reason,
      details: details,
    );
  }

  Future<void> deleteConversation(String id) {
    return _supabaseService.deleteConversation(id);
  }
}
