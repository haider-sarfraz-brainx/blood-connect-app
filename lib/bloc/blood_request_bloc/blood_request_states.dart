import 'package:equatable/equatable.dart';
import '../../data/models/blood_request_model.dart';

abstract class BloodRequestState extends Equatable {
  const BloodRequestState();

  @override
  List<Object?> get props => [];
}

class BloodRequestInitial extends BloodRequestState {
  const BloodRequestInitial();
}

class BloodRequestLoading extends BloodRequestState {
  const BloodRequestLoading();
}

class BloodRequestCreated extends BloodRequestState {
  final BloodRequestModel request;

  const BloodRequestCreated(this.request);

  @override
  List<Object?> get props => [request];
}

class BloodRequestsLoaded extends BloodRequestState {
  final List<BloodRequestModel> requests;

  const BloodRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class BloodRequestUpdated extends BloodRequestState {
  final BloodRequestModel request;

  const BloodRequestUpdated(this.request);

  @override
  List<Object?> get props => [request];
}

class BloodRequestDeleted extends BloodRequestState {
  final String requestId;

  const BloodRequestDeleted(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class BloodRequestError extends BloodRequestState {
  final String message;

  const BloodRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
