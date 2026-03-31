class LocationResult {
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
  });

  String? get address {
    if (city == null && country == null) return null;
    if (city == null) return country;
    if (country == null) return city;
    return '$city, $country';
  }

  @override
  String toString() {
    return 'LocationResult(latitude: $latitude, longitude: $longitude, country: $country, city: $city, address: $address)';
  }
}
