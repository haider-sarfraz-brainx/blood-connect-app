import 'package:equatable/equatable.dart';

class CityModel extends Equatable {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? timezone;

  const CityModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.timezone,
  });

  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'] as int,
      name: map['name'] as String,
      latitude: double.parse(map['latitude'].toString()),
      longitude: double.parse(map['longitude'].toString()),
      timezone: map['timezone'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, timezone];
}
