import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    await _ensureLocationReady();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: AppConstants.liveLocationDistanceFilterMeters,
      ),
    );
  }

  Future<Position?> getLastKnownPosition() {
    return Geolocator.getLastKnownPosition();
  }

  Stream<Position> livePositionStream() {
    return Stream<void>.fromFuture(_ensureLocationReady()).asyncExpand((_) {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: AppConstants.liveLocationDistanceFilterMeters,
        ),
      );
    });
  }

  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  Future<void> _ensureLocationReady() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Turn on location services to share your location.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. Open settings to enable it.',
      );
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError('Location permission is required for safety features.');
    }
  }
}
