class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  String toString() {
    return 'LocationResult(latitude: $latitude, longitude: $longitude, address: $address)';
  }
}
