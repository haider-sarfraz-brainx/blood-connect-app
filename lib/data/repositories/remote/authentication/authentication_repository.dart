import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../managers/remote/supabase_service.dart';
import '../../../models/user_model.dart';

class AuthenticationRepository {
  final SupabaseService _supabaseService;

  AuthenticationRepository(this._supabaseService);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user != null) {
        final userModel = UserModel(
          id: response.user!.id,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
          onboardingCompleted: false, 
        );
        
        await _supabaseService.insertUser(userModel);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        
        var userModel = await _supabaseService.getUserById(response.user!.id);
        if (userModel == null) {
          
          final userModelFromAuth = UserModel(
            id: response.user!.id,
            name: response.user!.userMetadata?['name'] ?? '',
            email: response.user!.email ?? email,
            phone: response.user!.userMetadata?['phone'] ?? '',
            createdAt: DateTime.parse(response.user!.createdAt),
            onboardingCompleted: false,
          );
          userModel = await _supabaseService.insertUser(userModelFromAuth);
        }
        
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _supabaseService.client.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges {
    return _supabaseService.client.auth.onAuthStateChange;
  }

  Future<UserModel?> getUserModel(String userId) async {
    return await _supabaseService.getUserById(userId);
  }

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      final currentUser = await _supabaseService.getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final updatedUser = currentUser.copyWith(
        name: name,
        phone: phone,
        updatedAt: DateTime.now(),
      );

      final userModel = await _supabaseService.updateUser(updatedUser);

      await _supabaseService.client.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'phone': phone,
          },
        ),
      );

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> completeOnboarding({
    required String userId,
    String? bloodGroup,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? lastDonationDate,
  }) async {
    try {
      final currentUser = await _supabaseService.getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final updatedUser = currentUser.copyWith(
        bloodGroup: bloodGroup,
        latitude: latitude,
        longitude: longitude,
        address: address,
        dateOfBirth: dateOfBirth,
        gender: gender,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        lastDonationDate: lastDonationDate,
        onboardingCompleted: true,
        updatedAt: DateTime.now(),
      );

      final userModel = await _supabaseService.updateUser(updatedUser);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }
}
