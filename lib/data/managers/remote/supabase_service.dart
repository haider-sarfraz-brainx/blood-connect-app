import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/db_constants.dart';
import '../../models/user_model.dart';
import '../../models/blood_request_model.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<UserModel> insertUser(UserModel user) async {
    try {
      final response = await client
          .from(DbConstants.users)
          .insert(user.toMap())
          .select()
          .single();
      return UserModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await client
          .from(DbConstants.users)
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? UserModel.fromMap(response) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await client
          .from(DbConstants.users)
          .select()
          .eq('email', email)
          .maybeSingle();
      return response != null ? UserModel.fromMap(response) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await client
          .from(DbConstants.users)
          .update(user.toMap())
          .eq('id', user.id)
          .select()
          .single();
      return UserModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<BloodRequestModel> insertBloodRequest(BloodRequestModel request) async {
    try {
      final map = request.toMap();
      
      if (map['id'] == null || map['id'] == '') {
        map.remove('id');
      }
      final response = await client
          .from(DbConstants.bloodRequests)
          .insert(map)
          .select()
          .single();
      return BloodRequestModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BloodRequestModel>> getBloodRequestsByUserId(String userId) async {
    try {
      
      final response = await client
          .from(DbConstants.bloodRequests)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => BloodRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BloodRequestModel>> getAllBloodRequests() async {
    try {
      final response = await client
          .from(DbConstants.bloodRequests)
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => BloodRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BloodRequestModel>> getBloodRequestsForHome({
    String? bloodGroup,
    String? excludeUserId,
  }) async {
    try {
      
      var query = client
          .from(DbConstants.bloodRequests)
          .select();

      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        query = query.eq('blood_group', bloodGroup);
      }

      final response = await query
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      List<BloodRequestModel> requests = (response as List)
          .map((item) => BloodRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();

      if (excludeUserId != null && excludeUserId.isNotEmpty) {
        requests = requests.where((request) => request.userId != excludeUserId).toList();
      }
      
      return requests;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BloodRequestModel>> getActiveBloodRequests({String? bloodGroup}) async {
    try {
      var query = client
          .from(DbConstants.bloodRequests)
          .select();
      
      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        query = query.eq('blood_group', bloodGroup);
      }
      
      final response = await query
          .inFilter('status', ['pending', 'in-progress'])
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((item) => BloodRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<BloodRequestModel?> getBloodRequestById(String requestId) async {
    try {
      final response = await client
          .from(DbConstants.bloodRequests)
          .select()
          .eq('id', requestId)
          .maybeSingle();
      return response != null ? BloodRequestModel.fromMap(response) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<BloodRequestModel> updateBloodRequest(BloodRequestModel request) async {
    try {
      final response = await client
          .from(DbConstants.bloodRequests)
          .update(request.toMap())
          .eq('id', request.id)
          .select()
          .single();
      return BloodRequestModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<BloodRequestModel> acceptBloodRequest(String requestId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from(DbConstants.bloodRequests)
          .update({
            'status': 'in-progress',
            'accepted_by_user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('status', 'pending') 
          .select()
          .single();
      return BloodRequestModel.fromMap(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBloodRequest(String requestId) async {
    try {
      await client
          .from(DbConstants.bloodRequests)
          .delete()
          .eq('id', requestId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserModel>> getAllDonors({String? excludeUserId}) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      final userIdToExclude = excludeUserId ?? currentUserId;
      
      var query = client
          .from(DbConstants.users)
          .select()
          .eq('onboarding_completed', true);
          
      if (userIdToExclude != null) {
        query = query.neq('id', userIdToExclude);
      }
      
      final response = await query;
      return (response as List)
          .map((item) => UserModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(String userId) async {
    try {
      await client.rpc('delete_user');
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<ConversationModel> createConversation({
    required String recipientId,
    String? requestId,
    required String initialMessage,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Not authenticated');

      final existing = await getConversationByParticipants(recipientId, requestId);
      if (existing != null) return existing;

      final now = DateTime.now();
      final conversation = ConversationModel(
        id: '',
        initiatorId: currentUserId,
        recipientId: recipientId,
        requestId: requestId,
        status: ConversationStatus.pending,
        lastMessage: initialMessage,
        updatedAt: now,
        createdAt: now,
      );

      final map = conversation.toMap()..remove('id');
      final response = await client
          .from(DbConstants.conversations)
          .insert(map)
          .select()
          .single();

      final created = ConversationModel.fromMap(response);

      await insertMessage(MessageModel(
        id: '',
        conversationId: created.id,
        senderId: currentUserId,
        content: initialMessage,
        createdAt: now,
      ));

      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<ConversationModel?> getConversationByParticipants(String otherId, String? requestId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final response = await client
        .from(DbConstants.conversations)
        .select()
        .or('and(initiator_id.eq.$currentUserId,recipient_id.eq.$otherId),and(initiator_id.eq.$otherId,recipient_id.eq.$currentUserId)')
        .maybeSingle();

    if (response == null) return null;
    return ConversationModel.fromMap(response);
  }

  Future<ConversationModel> updateConversationStatus(String id, ConversationStatus status) async {
    final response = await client
        .from(DbConstants.conversations)
        .update({'status': status.toDbString(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return ConversationModel.fromMap(response);
  }

  Future<List<ConversationModel>> getConversations() async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await client
        .from(DbConstants.conversations)
        .select()
        .or('initiator_id.eq.$currentUserId,recipient_id.eq.$currentUserId')
        .order('updated_at', ascending: false);

    return (response as List)
        .map((e) => ConversationModel.fromMap(e))
        .toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    final map = message.toMap()..remove('id');
    await client.from(DbConstants.messages).insert(map);
    
    await client
        .from(DbConstants.conversations)
        .update({'last_message': message.content, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', message.conversationId);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await client
        .from(DbConstants.messages)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => MessageModel.fromMap(e))
        .toList();
  }

  Stream<List<ConversationModel>> getConversationsStream() {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value([]);

    return client
        .from(DbConstants.conversations)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['initiator_id'] == currentUserId || e['recipient_id'] == currentUserId)
            .map((e) => ConversationModel.fromMap(e))
            .toList());
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return client
        .from(DbConstants.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => MessageModel.fromMap(e)).toList());
  }

  Future<void> updateConversationStatusByRequestId(String requestId, ConversationStatus status) async {
    await client
        .from(DbConstants.conversations)
        .update({'status': status.toDbString()})
        .eq('request_id', requestId);
  }
}
