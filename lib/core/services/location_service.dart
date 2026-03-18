import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import '../../data/models/location_result.dart';
import '../utils/location_error_handler.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Check if permission is granted
  Future<bool> isPermissionGranted() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location with address
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Step 1: Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(
          'Location services are disabled. Please enable location services in your device settings.',
          LocationErrorType.locationDisabled,
        );
      }

      // Step 2: Check permission status
      LocationPermission permission = await checkLocationPermission();

      // Step 3: Request permission if not granted
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException(
            'Location permissions are denied. Please grant location permission to use this feature.',
            LocationErrorType.permissionDenied,
          );
        }
      }

      // Step 4: Handle permanently denied permission
      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
          'Location permissions are permanently denied. Please enable them in app settings.',
          LocationErrorType.permissionPermanentlyDenied,
        );
      }

      // Step 5: Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Step 6: Get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = _formatAddress(place);
        }
      } catch (e) {
        // If geocoding fails, we still return the location with coordinates
        // Address will be null
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException(
        'Failed to get current location: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  /// Format address from Placemark
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  /// Open app settings
  Future<bool> openSettings() async {
    return await permission_handler.openAppSettings();
  }
}
