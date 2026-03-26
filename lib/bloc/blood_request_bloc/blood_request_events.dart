import 'package:equatable/equatable.dart';
import '../../data/models/blood_request_model.dart';

abstract class BloodRequestEvent extends Equatable {
  const BloodRequestEvent();

  @override
  List<Object?> get props => [];
}

class CreateBloodRequestEvent extends BloodRequestEvent {
  final String patientName;
  final String bloodGroup;
  final int unitsRequired;
  final String hospitalName;
  final String? hospitalAddress;
  final String contactNumber;
  final String? notes;
  final bool isEmergency;

  const CreateBloodRequestEvent({
    required this.patientName,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.hospitalName,
    this.hospitalAddress,
    required this.contactNumber,
    this.notes,
    this.isEmergency = false,
  });

  @override
  List<Object?> get props => [
        patientName,
        bloodGroup,
        unitsRequired,
        hospitalName,
        hospitalAddress,
        contactNumber,
        notes,
        isEmergency,
      ];
}

class GetBloodRequestsEvent extends BloodRequestEvent {
  final String? userId;

  const GetBloodRequestsEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetActiveBloodRequestsEvent extends BloodRequestEvent {
  final String? bloodGroup;

  const GetActiveBloodRequestsEvent({this.bloodGroup});

  @override
  List<Object?> get props => [bloodGroup];
}

class GetAllBloodRequestsEvent extends BloodRequestEvent {
  const GetAllBloodRequestsEvent();
}

class UpdateBloodRequestStatusEvent extends BloodRequestEvent {
  final String requestId;
  final BloodRequestStatus status;

  const UpdateBloodRequestStatusEvent({
    required this.requestId,
    required this.status,
  });

  @override
  List<Object?> get props => [requestId, status];
}

class DeleteBloodRequestEvent extends BloodRequestEvent {
  final String requestId;

  const DeleteBloodRequestEvent({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class AcceptBloodRequestEvent extends BloodRequestEvent {
  final String requestId;

  const AcceptBloodRequestEvent({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class GetBloodRequestsForHomeEvent extends BloodRequestEvent {
  final String? bloodGroup;
  final String? excludeUserId;

  const GetBloodRequestsForHomeEvent({
    this.bloodGroup,
    this.excludeUserId,
  });

  @override
  List<Object?> get props => [bloodGroup, excludeUserId];
}
