import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

class AuthenticationInitial extends AuthenticationState {
  const AuthenticationInitial();
}

class AuthenticationLoading extends AuthenticationState {
  const AuthenticationLoading();
}

class AuthenticationAuthenticated extends AuthenticationState {
  final User user;
  final UserModel? userModel;

  const AuthenticationAuthenticated(this.user, {this.userModel});

  @override
  List<Object?> get props => [user, userModel];
}

class AuthenticationUnauthenticated extends AuthenticationState {
  const AuthenticationUnauthenticated();
}

class AuthenticationError extends AuthenticationState {
  final String message;

  const AuthenticationError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordChangeSuccess extends AuthenticationState {
  const PasswordChangeSuccess();
}

class ForgotPasswordEmailSent extends AuthenticationState {
  const ForgotPasswordEmailSent();
}

class AuthenticationPasswordRecovery extends AuthenticationState {
  const AuthenticationPasswordRecovery();
}

class UpdatePasswordSuccess extends AuthenticationState {
  const UpdatePasswordSuccess();
}
