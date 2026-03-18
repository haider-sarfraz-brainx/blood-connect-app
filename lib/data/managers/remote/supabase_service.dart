import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/db_constants.dart';
import '../../models/user_model.dart';
import '../../models/blood_request_model.dart';

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

  // Blood Request Methods
  Future<BloodRequestModel> insertBloodRequest(BloodRequestModel request) async {
    try {
      final map = request.toMap();
      // Remove id field if it's empty to let database generate it
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
      // Get requests created by user OR accepted by user
      final response = await client
          .from(DbConstants.bloodRequests)
          .select()
          .or('user_id.eq.$userId,accepted_by_user_id.eq.$userId')
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
      // Always get current user ID as fallback
      final currentUserId = client.auth.currentUser?.id;
      final userIdToExclude = excludeUserId ?? currentUserId;
      
      var query = client
          .from(DbConstants.bloodRequests)
          .select();
      
      // Filter by blood group if provided
      if (bloodGroup != null && bloodGroup.isNotEmpty) {
        query = query.eq('blood_group', bloodGroup);
      }
      
      // Only show pending requests on home screen
      final response = await query
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      // Filter out current user's requests client-side
      List<BloodRequestModel> requests = (response as List)
          .map((item) => BloodRequestModel.fromMap(item as Map<String, dynamic>))
          .toList();
      
      // Always exclude current user's requests
      if (userIdToExclude != null && userIdToExclude.isNotEmpty) {
        requests = requests.where((request) => request.userId != userIdToExclude).toList();
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
      
      // Update status and set accepted_by_user_id
      final response = await client
          .from(DbConstants.bloodRequests)
          .update({
            'status': 'in-progress',
            'accepted_by_user_id': currentUserId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('status', 'pending') // Ensure it's still pending
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

  // Donor Methods
  Future<List<UserModel>> getAllDonors({String? excludeUserId}) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      final userIdToExclude = excludeUserId ?? currentUserId;

      // Fetch users who have completed onboarding (blood group is set)
      final response = await client
          .from(DbConstants.users)
          .select()
          .not('blood_group', 'is', null)
          .order('name', ascending: true);

      List<UserModel> donors = (response as List)
          .map((item) => UserModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Exclude the current logged-in user
      if (userIdToExclude != null && userIdToExclude.isNotEmpty) {
        donors =
            donors.where((user) => user.id != userIdToExclude).toList();
      }

      return donors;
    } catch (e) {
      rethrow;
    }
  }
}
