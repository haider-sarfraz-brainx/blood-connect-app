import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

class SignUpEvent extends AuthenticationEvent {
  final String name;
  final String email;
  final String? phone;
  final String password;

  const SignUpEvent({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, phone, password];
}

class SignInEvent extends AuthenticationEvent {
  final String email;
  final String password;

  const SignInEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignOutEvent extends AuthenticationEvent {
  const SignOutEvent();
}

class DeleteAccountEvent extends AuthenticationEvent {
  const DeleteAccountEvent();
}

class CheckAuthenticationStatusEvent extends AuthenticationEvent {
  const CheckAuthenticationStatusEvent();
}

class UpdateProfileEvent extends AuthenticationEvent {
  final String name;
  final String? phone;
  final String? country;
  final String? city;
  final String? timezone;

  const UpdateProfileEvent({
    required this.name,
    this.phone,
    this.country,
    this.city,
    this.timezone,
  });

  @override
  List<Object?> get props => [name, phone, country, city, timezone];
}

class ChangePasswordEvent extends AuthenticationEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class CompleteOnboardingEvent extends AuthenticationEvent {
  final String? bloodGroup;
  final double? latitude;
  final double? longitude;
  final String? country;
  final String? city;
  final String? timezone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? lastDonationDate;

  const CompleteOnboardingEvent({
    this.bloodGroup,
    this.latitude,
    this.longitude,
    this.country,
    this.city,
    this.timezone,
    this.dateOfBirth,
    this.gender,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.lastDonationDate,
  });

  @override
  List<Object?> get props => [
        bloodGroup,
        latitude,
        longitude,
        country,
        city,
        timezone,
        dateOfBirth,
        gender,
        emergencyContactName,
        emergencyContactPhone,
        lastDonationDate,
      ];
}

class ForgotPasswordEvent extends AuthenticationEvent {
  final String email;

  const ForgotPasswordEvent({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

class UpdatePasswordFromRecoveryEvent extends AuthenticationEvent {
  final String newPassword;

  const UpdatePasswordFromRecoveryEvent({
    required this.newPassword,
  });

  @override
  List<Object?> get props => [newPassword];
}
