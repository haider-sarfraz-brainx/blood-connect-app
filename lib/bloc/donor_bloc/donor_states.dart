import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class DonorState extends Equatable {
  const DonorState();

  @override
  List<Object?> get props => [];
}

class DonorInitial extends DonorState {
  const DonorInitial();
}

class DonorLoading extends DonorState {
  const DonorLoading();
}

class DonorsLoaded extends DonorState {
  final List<UserModel> donors;

  const DonorsLoaded(this.donors);

  @override
  List<Object?> get props => [donors];
}

class DonorError extends DonorState {
  final String message;

  const DonorError(this.message);

  @override
  List<Object?> get props => [message];
}
