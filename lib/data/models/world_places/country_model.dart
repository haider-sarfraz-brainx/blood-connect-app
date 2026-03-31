import 'package:equatable/equatable.dart';
import 'city_model.dart';

class CountryModel extends Equatable {
  final int id;
  final String name;
  final String iso2;
  final String iso3;
  final String native;
  final String region;
  final List<String> timezones;
  final List<CityModel> cities;

  const CountryModel({
    required this.id,
    required this.name,
    required this.iso2,
    required this.iso3,
    required this.native,
    required this.region,
    required this.timezones,
    required this.cities,
  });

  factory CountryModel.fromMap(Map<String, dynamic> map) {
    
    final List<CityModel> allCities = [];
    if (map['states'] != null) {
      for (var state in map['states']) {
        if (state['cities'] != null) {
          allCities.addAll((state['cities'] as List)
              .map((city) => CityModel.fromMap(city as Map<String, dynamic>)));
        }
      }
    }

    final timezoneList = (map['timezones'] as List<dynamic>?)
            ?.map((tz) => tz['zoneName'] as String)
            .toList() ??
        [];

    return CountryModel(
      id: map['id'] as int,
      name: map['name'] as String,
      iso2: map['iso2'] as String,
      iso3: map['iso3'] as String,
      native: map['native'] as String,
      region: map['region'] as String,
      timezones: timezoneList,
      cities: allCities,
    );
  }

  @override
  List<Object?> get props => [id, name, iso2, iso3, native, region, timezones, cities];
}
