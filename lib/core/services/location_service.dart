import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import '../../data/models/location_result.dart';
import '../utils/location_error_handler.dart';

class LocationService {
  
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<bool> isPermissionGranted() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<LocationResult> getCurrentLocation() async {
    try {
      
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(
          'Location services are disabled. Please enable location services in your device settings.',
          LocationErrorType.locationDisabled,
        );
      }

      LocationPermission permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException(
            'Location permissions are denied. Please grant location permission to use this feature.',
            LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
          'Location permissions are permanently denied. Please enable them in app settings.',
          LocationErrorType.permissionPermanentlyDenied,
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

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

  Future<bool> openSettings() async {
    return await permission_handler.openAppSettings();
  }
}
