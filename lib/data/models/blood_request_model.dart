import 'dart:convert';
import 'package:equatable/equatable.dart';

enum BloodRequestStatus {
  pending,
  offered,
  inProgress,
  fulfilled,
  cancelled;

  static BloodRequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BloodRequestStatus.pending;
      case 'offered':
        return BloodRequestStatus.offered;
      case 'in-progress':
        return BloodRequestStatus.inProgress;
      case 'fulfilled':
        return BloodRequestStatus.fulfilled;
      case 'cancelled':
        return BloodRequestStatus.cancelled;
      default:
        return BloodRequestStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case BloodRequestStatus.pending:
        return 'pending';
      case BloodRequestStatus.offered:
        return 'offered';
      case BloodRequestStatus.inProgress:
        return 'in-progress';
      case BloodRequestStatus.fulfilled:
        return 'fulfilled';
      case BloodRequestStatus.cancelled:
        return 'cancelled';
    }
  }
}

class BloodRequestModel extends Equatable {
  final String id;
  final String userId;
  final String patientName;
  final String bloodGroup;
  final int unitsRequired;
  final String hospitalName;
  final String? hospitalAddress;
  final String contactNumber;
  final BloodRequestStatus status;
  final String? notes;
  final String? acceptedByUserId;
  final bool isEmergency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BloodRequestModel({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.hospitalName,
    this.hospitalAddress,
    required this.contactNumber,
    required this.status,
    this.notes,
    this.acceptedByUserId,
    this.isEmergency = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'patient_name': patientName,
      'blood_group': bloodGroup,
      'units_required': unitsRequired,
      'hospital_name': hospitalName,
      'hospital_address': hospitalAddress,
      'contact_number': contactNumber,
      'status': status.toDbString(),
      'notes': notes,
      'accepted_by_user_id': acceptedByUserId,
      'is_emergency': isEmergency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BloodRequestModel.fromMap(Map<String, dynamic> map) {
    return BloodRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      patientName: map['patient_name'] as String,
      bloodGroup: map['blood_group'] as String,
      unitsRequired: map['units_required'] as int,
      hospitalName: map['hospital_name'] as String,
      hospitalAddress: map['hospital_address'] as String?,
      contactNumber: map['contact_number'] as String,
      status: BloodRequestStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      acceptedByUserId: map['accepted_by_user_id'] as String?,
      isEmergency: map['is_emergency'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory BloodRequestModel.fromJson(String json) {
    return BloodRequestModel.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  BloodRequestModel copyWith({
    String? id,
    String? userId,
    String? patientName,
    String? bloodGroup,
    int? unitsRequired,
    String? hospitalName,
    String? hospitalAddress,
    String? contactNumber,
    BloodRequestStatus? status,
    String? notes,
    String? acceptedByUserId,
    bool? isEmergency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BloodRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      patientName: patientName ?? this.patientName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        patientName,
        bloodGroup,
        unitsRequired,
        hospitalName,
        hospitalAddress,
        contactNumber,
        status,
        notes,
        acceptedByUserId,
        isEmergency,
        createdAt,
        updatedAt,
      ];
}

