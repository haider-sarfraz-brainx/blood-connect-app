import 'package:equatable/equatable.dart';

abstract class DonorEvent extends Equatable {
  const DonorEvent();

  @override
  List<Object?> get props => [];
}

class GetDonorsEvent extends DonorEvent {
  final String? country;
  final String? city;

  const GetDonorsEvent({this.country, this.city});

  @override
  List<Object?> get props => [country, city];
}
