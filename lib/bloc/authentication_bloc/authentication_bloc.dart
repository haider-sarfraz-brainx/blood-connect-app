import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'authentication_events.dart';
import 'authentication_states.dart';
import '../../data/repositories/remote/authentication/authentication_repository.dart';
import '../../data/managers/local/session_manager.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/authentication_error_handler.dart';
import '../../core/utils/connectivity_checker.dart';
import '../../injection_container.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository _authenticationRepository;
  final SessionManager _sessionManager = sl<SessionManager>();
  final AuthenticationErrorHandler _errorHandler = AuthenticationErrorHandler();
  final ConnectivityChecker _connectivityChecker = ConnectivityChecker();

  AuthenticationBloc(this._authenticationRepository)
      : super(const AuthenticationInitial()) {
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<CheckAuthenticationStatusEvent>(_onCheckAuthenticationStatus);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<CompleteOnboardingEvent>(_onCompleteOnboarding);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<UpdatePasswordFromRecoveryEvent>(_onUpdatePasswordFromRecovery);

    _authenticationRepository.authStateChanges.listen((authState) async {
      if (authState.event == AuthChangeEvent.signedIn) {
        if (authState.session?.user != null) {
          
          final userModel = await _authenticationRepository.getUserModel(authState.session!.user!.id);
          if (userModel != null) {
            await _sessionManager.saveUser(userModel);
          }
          emit(AuthenticationAuthenticated(authState.session!.user!, userModel: userModel));
        }
      } else if (authState.event == AuthChangeEvent.signedOut) {
        emit(const AuthenticationUnauthenticated());
      } else if (authState.event == AuthChangeEvent.passwordRecovery) {
        emit(const AuthenticationPasswordRecovery());
      }
    });
  }

  Future<void> _handleAuthenticationOperation<T>(
    Emitter<AuthenticationState> emit,
    Future<T> Function() operation,
    Future<void> Function(T) onSuccess,
  ) async {
    emit(const AuthenticationLoading());
    
    try {
      final hasConnection = await _connectivityChecker.hasInternetConnection();
      if (!hasConnection) {
        final errorMessage = await _errorHandler.handleError(
          Exception('No internet connection'),
        );
        emit(AuthenticationError(errorMessage));
        return;
      }

      final result = await operation();
      await onSuccess(result);
    } catch (e) {
      final errorMessage = await _errorHandler.handleError(e);
      emit(AuthenticationError(errorMessage));
    }
  }

  Future<void> _onSignUp(
    SignUpEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<AuthResponse>(
      emit,
      () => _authenticationRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
      ),
      (response) async {
        if (response.user != null) {
          
          UserModel? userModel = await _authenticationRepository.getUserModel(response.user!.id);
          if (userModel == null) {
            
            final userModelFromAuth = UserModel(
              id: response.user!.id,
              name: event.name,
              email: event.email,
              phone: event.phone,
              createdAt: DateTime.parse(response.user!.createdAt),
              onboardingCompleted: false,
            );
            userModel = userModelFromAuth;
          }
          
          await _sessionManager.saveUser(userModel);
          
          emit(AuthenticationAuthenticated(response.user!, userModel: userModel));
        } else {
          emit(const AuthenticationError('Sign up failed. Please try again.'));
        }
      },
    );
  }

  Future<void> _onSignIn(
    SignInEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<AuthResponse>(
      emit,
      () => _authenticationRepository.signIn(
        email: event.email,
        password: event.password,
      ),
      (response) async {
        if (response.user != null) {
          
          UserModel? userModel = await _authenticationRepository.getUserModel(response.user!.id);
          if (userModel == null) {
            
            final userModelFromAuth = UserModel(
              id: response.user!.id,
              name: response.user!.userMetadata?['name'] ?? '',
              email: response.user!.email ?? event.email,
              phone: response.user!.userMetadata?['phone'] ?? '',
              createdAt: DateTime.parse(response.user!.createdAt),
              onboardingCompleted: false,
            );
            userModel = userModelFromAuth;
          }
          
          await _sessionManager.saveUser(userModel);
          
          emit(AuthenticationAuthenticated(response.user!, userModel: userModel));
        } else {
          emit(const AuthenticationError('Sign in failed. Please try again.'));
        }
      },
    );
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<void>(
      emit,
      () => _authenticationRepository.signOut(),
      (_) async {
        await _sessionManager.clearSession();
        emit(const AuthenticationUnauthenticated());
      },
    );
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<void>(
      emit,
      () async {
        final currentUser = _authenticationRepository.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        await _authenticationRepository.deleteAccount(currentUser.id);
      },
      (_) async {
        await _sessionManager.clearSession();
        emit(const AuthenticationUnauthenticated());
      },
    );
  }

  Future<void> _onCheckAuthenticationStatus(
    CheckAuthenticationStatusEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (state is AuthenticationPasswordRecovery) return;

    final authUser = _authenticationRepository.getCurrentUser();
    
      if (authUser != null) {
        
        final userModel = await _authenticationRepository.getUserModel(authUser.id);
        if (userModel != null) {
          await _sessionManager.saveUser(userModel);
          emit(AuthenticationAuthenticated(authUser, userModel: userModel));
        } else {
          
          await _sessionManager.clearSession();
          emit(const AuthenticationUnauthenticated());
        }
      } else {
        
        if (_sessionManager.isLoggedIn()) {
          await _sessionManager.clearSession();
        }
        emit(const AuthenticationUnauthenticated());
      }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<UserModel>(
      emit,
      () {
        final currentUser = _authenticationRepository.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        return _authenticationRepository.updateProfile(
          userId: currentUser.id,
          name: event.name,
          phone: event.phone,
          country: event.country,
          city: event.city,
          timezone: event.timezone,
        );
      },
      (updatedUser) async {
        await _sessionManager.saveUser(updatedUser);
        final authUser = _authenticationRepository.getCurrentUser();
        if (authUser != null) {
          emit(AuthenticationAuthenticated(authUser, userModel: updatedUser));
        } else {
          emit(const AuthenticationError('Profile updated but user session not found.'));
        }
      },
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<void>(
      emit,
      () => _authenticationRepository.changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      ),
      (_) async {
        emit(const PasswordChangeSuccess());
      },
    );
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboardingEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<UserModel>(
      emit,
      () {
        final currentUser = _authenticationRepository.getCurrentUser();
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }
        return _authenticationRepository.completeOnboarding(
          userId: currentUser.id,
          bloodGroup: event.bloodGroup,
          latitude: event.latitude,
          longitude: event.longitude,
          country: event.country,
          city: event.city,
          timezone: event.timezone,
          dateOfBirth: event.dateOfBirth,
          gender: event.gender,
          emergencyContactName: event.emergencyContactName,
          emergencyContactPhone: event.emergencyContactPhone,
          lastDonationDate: event.lastDonationDate,
        );
      },
      (updatedUser) async {
        await _sessionManager.saveUser(updatedUser);
        final authUser = _authenticationRepository.getCurrentUser();
        if (authUser != null) {
          emit(AuthenticationAuthenticated(authUser, userModel: updatedUser));
        } else {
          emit(const AuthenticationError('Onboarding completed but user session not found.'));
        }
      },
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<void>(
      emit,
      () => _authenticationRepository.forgotPassword(event.email),
      (_) async {
        emit(const ForgotPasswordEmailSent());
      },
    );
  }

  Future<void> _onUpdatePasswordFromRecovery(
    UpdatePasswordFromRecoveryEvent event,
    Emitter<AuthenticationState> emit,
  ) async {
    await _handleAuthenticationOperation<void>(
      emit,
      () => _authenticationRepository.updateRecoveryPassword(event.newPassword),
      (_) async {
        emit(const UpdatePasswordSuccess());
      },
    );
  }
}
