import 'package:equatable/equatable.dart';

abstract class DonorEvent extends Equatable {
  const DonorEvent();

  @override
  List<Object?> get props => [];
}

class GetDonorsEvent extends DonorEvent {
  const GetDonorsEvent();
}
