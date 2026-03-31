import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../models/world_places/country_model.dart';

class WorldPlacesManager {
  static final WorldPlacesManager _instance = WorldPlacesManager._internal();
  factory WorldPlacesManager() => _instance;
  WorldPlacesManager._internal();

  List<CountryModel> _countries = [];
  bool _isLoading = false;

  List<CountryModel> get countries => _countries;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_countries.isNotEmpty || _isLoading) return;
    _isLoading = true;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/jsons/world_places_data.json');
      _countries = await compute(_parseCountries, jsonString);
    } catch (e) {
      debugPrint('Error loading world places data: $e');
    } finally {
      _isLoading = false;
    }
  }

  static List<CountryModel> _parseCountries(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((map) => CountryModel.fromMap(map as Map<String, dynamic>)).toList();
  }

  Future<CountryModel?> findCountryByTimezone() async {
    if (_countries.isEmpty) await load();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String currentTimezone = timezoneInfo.identifier;
      return _countries.firstWhere(
        (country) => country.timezones.contains(currentTimezone),
        orElse: () => _countries.firstWhere((c) => c.iso2 == 'PK'), 
      );
    } catch (e) {
      return null;
    }
  }

  List<CountryModel> searchCountries(String query) {
    return _countries
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
