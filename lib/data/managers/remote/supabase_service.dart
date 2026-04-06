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

  /// Store FCM device token for server-triggered pushes (add `fcm_token text` on `users` if missing).
  Future<void> updateUserFcmToken(String userId, String? fcmToken) async {
    try {
      await client.from(DbConstants.users).update({
        'fcm_token': fcmToken,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
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
    String? country,
    String? city,
  }) async {
    try {
      
      var query = client
          .from(DbConstants.bloodRequests)
          .select();

      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        query = query.eq('blood_group', bloodGroup);
      }
      
      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }
      
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
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

  /// Home / donor flow: claim a pending request and open an [ConversationStatus.accepted] chat
  /// with the requester (no separate "send message request" step).
  Future<ConversationModel> acceptBloodRequestAndOpenChat({
    required String requestId,
    required String requestOwnerId,
    required String initialMessage,
  }) async {
    await acceptBloodRequest(requestId);

    final existing = await getConversationByParticipants(requestOwnerId, requestId);

    if (existing == null || existing.status == ConversationStatus.rejected) {
      final conv = await createConversation(
        recipientId: requestOwnerId,
        requestId: requestId,
        initialMessage: initialMessage,
      );
      if (conv.status != ConversationStatus.accepted) {
        return updateConversationStatus(conv.id, ConversationStatus.accepted);
      }
      return conv;
    }

    if (existing.status != ConversationStatus.accepted) {
      return updateConversationStatus(existing.id, ConversationStatus.accepted);
    }
    return existing;
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

  Future<List<UserModel>> getAllDonors({
    String? excludeUserId,
    String? country,
    String? city,
  }) async {
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
      
      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }
      
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
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
      if (existing != null) {
        if (existing.status == ConversationStatus.rejected) {
          // Reset to pending so recipient sees it as a new request
          final updated = await updateConversationStatus(existing.id, ConversationStatus.pending);
          
          // Add the new initial message to this existing conversation
          await insertMessage(MessageModel(
            id: '',
            conversationId: updated.id,
            senderId: currentUserId,
            content: initialMessage,
            createdAt: DateTime.now().toUtc(),
          ));
          
          return updated;
        }
        return existing;
      }

      // Fetch participants' names for denormalization
      final initiator = await getUserById(currentUserId);
      final recipient = await getUserById(recipientId);

      final now = DateTime.now().toUtc();
      final conversation = ConversationModel(
        id: '',
        initiatorId: currentUserId,
        recipientId: recipientId,
        requestId: requestId,
        status: ConversationStatus.pending,
        lastMessage: initialMessage,
        updatedAt: now,
        createdAt: now,
        initiatorName: initiator?.name,
        recipientName: recipient?.name,
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
        .update({'status': status.toDbString(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    
    final conv = ConversationModel.fromMap(response);

    // Sync with BloodRequest if applicable
    if (conv.requestId != null) {
      if (status == ConversationStatus.accepted) {
        await client.from(DbConstants.bloodRequests).update({
          'status': 'in-progress',
          'accepted_by_user_id': client.auth.currentUser?.id,
        }).eq('id', conv.requestId!);
      } else if (status == ConversationStatus.rejected || status == ConversationStatus.pending) {
        await client.from(DbConstants.bloodRequests).update({
          'status': 'pending',
          'accepted_by_user_id': null,
        }).eq('id', conv.requestId!);
      }
    }

    return conv;
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
        .update({'last_message': message.content, 'updated_at': DateTime.now().toUtc().toIso8601String()})
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

    // Note: stream() doesn't support joins natively to get names.
    // For real-time names, we either need a view or we trigger a re-fetch.
    return client
        .from(DbConstants.conversations)
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => data
            .where((e) => e['initiator_id'] == currentUserId || e['recipient_id'] == currentUserId)
            .map((e) => ConversationModel.fromMap(e))
            .toList());
  }

  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return client
        .from(DbConstants.messages)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['conversation_id'] == conversationId)
            .map((e) => MessageModel.fromMap(e))
            .toList());
  }

  Future<void> updateConversationStatusByRequestId(String requestId, ConversationStatus status) async {
    await client
        .from(DbConstants.conversations)
        .update({'status': status.toDbString(), 'updated_at': DateTime.now().toIso8601String()})
        .eq('request_id', requestId);

    // Sync with BloodRequest status
    if (status == ConversationStatus.accepted) {
      await client.from(DbConstants.bloodRequests).update({
        'status': 'in-progress',
        'accepted_by_user_id': client.auth.currentUser?.id,
      }).eq('id', requestId);
    } else if (status == ConversationStatus.rejected) {
      await client.from(DbConstants.bloodRequests).update({
        'status': 'pending',
        'accepted_by_user_id': null,
      }).eq('id', requestId);
    }
  }

  Future<void> blockConversation(String id) async {
    await client
        .from(DbConstants.conversations)
        .update({'status': ConversationStatus.blocked.toDbString(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<void> unblockConversation(String id) async {
    await client
        .from(DbConstants.conversations)
        .update({'status': ConversationStatus.accepted.toDbString(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Future<void> reportConversation({
    required String conversationId,
    required String reason,
    String? details,
  }) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;

    // Get conversation to identify reported user
    final convResp = await client
        .from(DbConstants.conversations)
        .select()
        .eq('id', conversationId)
        .single();
    
    final initiatorId = convResp['initiator_id'];
    final recipientId = convResp['recipient_id'];
    
    final reportedId = initiatorId == currentUserId ? recipientId : initiatorId;

    // Insert into reports table
    await client.from(DbConstants.reports).insert({
      'reporter_id': currentUserId,
      'reported_id': reportedId,
      'conversation_id': conversationId,
      'reason': reason,
      'details': details,
    });

    // Mark as reported in conversations table
    await client
        .from(DbConstants.conversations)
        .update({'status': ConversationStatus.reported.toDbString(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', conversationId);
  }

  Future<void> deleteConversation(String id) async {
    // 1. Delete associated reports first (FKey constraint)
    await client
        .from(DbConstants.reports)
        .delete()
        .eq('conversation_id', id);

    // 2. Delete associated messages
    await client
        .from(DbConstants.messages)
        .delete()
        .eq('conversation_id', id);
        
    // 3. Delete the conversation itself
    await client
        .from(DbConstants.conversations)
        .delete()
        .eq('id', id);
  }
}
