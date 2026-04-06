import 'dart:convert';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
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
  final bool onboardingCompleted;
  final String? fcmToken;


  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.createdAt,
    this.updatedAt,
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
    this.onboardingCompleted = false,
    this.fcmToken,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'blood_group': bloodGroup,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'city': city,
      'timezone': timezone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'last_donation_date': lastDonationDate?.toIso8601String(),
      'onboarding_completed': onboardingCompleted,
      'fcm_token': fcmToken,
    };

  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      bloodGroup: map['blood_group'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      country: map['country'] as String?,
      city: map['city'] as String?,
      timezone: map['timezone'] as String?,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      gender: map['gender'] as String?,
      emergencyContactName: map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      lastDonationDate: map['last_donation_date'] != null
          ? DateTime.parse(map['last_donation_date'] as String)
          : null,
      onboardingCompleted: map['onboarding_completed'] as bool? ?? false,
      fcmToken: map['fcm_token'] as String?,
    );

  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String json) {
    return UserModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bloodGroup,
    double? latitude,
    double? longitude,
    String? country,
    String? city,
    String? timezone,
    DateTime? dateOfBirth,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? lastDonationDate,
    bool? onboardingCompleted,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      fcmToken: fcmToken ?? this.fcmToken,
    );

  }

  String? get address {
    if (city == null && country == null) return null;
    if (city == null) return country;
    if (country == null) return city;
    return '$city, $country';
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isOnboardingCompleted {
    
    if (onboardingCompleted) return true;

    
    if (bloodGroup != null && 
        bloodGroup!.isNotEmpty && 
        dateOfBirth != null && 
        gender != null && 
        gender!.isNotEmpty) {
      return true;
    }
    
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        createdAt,
        updatedAt,
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
        onboardingCompleted,
        fcmToken,
      ];

}

