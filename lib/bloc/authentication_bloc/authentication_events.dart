import 'package:equatable/equatable.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

class SignUpEvent extends AuthenticationEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const SignUpEvent({
    required this.name,
    required this.email,
    required this.phone,
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

class CheckAuthenticationStatusEvent extends AuthenticationEvent {
  const CheckAuthenticationStatusEvent();
}

class UpdateProfileEvent extends AuthenticationEvent {
  final String name;
  final String phone;

  const UpdateProfileEvent({
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, phone];
}

class CompleteOnboardingEvent extends AuthenticationEvent {
  final String? bloodGroup;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? lastDonationDate;

  const CompleteOnboardingEvent({
    this.bloodGroup,
    this.latitude,
    this.longitude,
    this.address,
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
        address,
        dateOfBirth,
        gender,
        emergencyContactName,
        emergencyContactPhone,
        lastDonationDate,
      ];
}
