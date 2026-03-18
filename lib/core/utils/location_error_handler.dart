enum LocationErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  locationDisabled,
  timeout,
  unknown,
}

class LocationException implements Exception {
  final String message;
  final LocationErrorType type;

  LocationException(this.message, this.type);

  @override
  String toString() => message;
}

String getLocationErrorMessage(LocationException exception) {
  switch (exception.type) {
    case LocationErrorType.permissionDenied:
      return 'Location permission is required to get your current location. Please grant permission when prompted.';
    case LocationErrorType.permissionPermanentlyDenied:
      return 'Location permission is permanently denied. Please enable it in app settings.';
    case LocationErrorType.locationDisabled:
      return 'Location services are disabled. Please enable location services in your device settings.';
    case LocationErrorType.timeout:
      return 'Location request timed out. Please try again.';
    case LocationErrorType.unknown:
      return 'Failed to get location. Please try again.';
  }
}
