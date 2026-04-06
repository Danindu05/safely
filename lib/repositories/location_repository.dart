import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../core/services/location_service.dart';
import '../core/services/realtime_database_service.dart';
import '../core/utils/retry_helper.dart';
import '../models/live_location.dart';

abstract class LocationRepository {
  Future<Position> getCurrentPosition();

  Future<Position?> getLastKnownPosition();

  Stream<Position> watchLivePositions();

  Future<void> updateLiveLocation(LiveLocation location);

  Stream<LiveLocation?> watchLiveLocation(String userId);

  Future<void> clearLiveLocation(String userId);

  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });
}

class FirebaseLocationRepository implements LocationRepository {
  FirebaseLocationRepository({
    required LocationService locationService,
    required RealtimeDatabaseService realtimeDatabaseService,
  }) : _locationService = locationService,
       _realtimeDatabaseService = realtimeDatabaseService;

  final LocationService _locationService;
  final RealtimeDatabaseService _realtimeDatabaseService;

  @override
  Future<Position> getCurrentPosition() {
    return _locationService.getCurrentPosition();
  }

  @override
  Future<Position?> getLastKnownPosition() {
    return _locationService.getLastKnownPosition();
  }

  @override
  Stream<Position> watchLivePositions() {
    return _locationService.livePositionStream();
  }

  @override
  Future<void> updateLiveLocation(LiveLocation location) {
    return RetryHelper.run<void>(
      label: 'update live location',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _realtimeDatabaseService
            .liveLocationRef(location.userId)
            .set(location.toMap());
      },
    );
  }

  @override
  Stream<LiveLocation?> watchLiveLocation(String userId) {
    return _realtimeDatabaseService.liveLocationRef(userId).onValue.map((
      event,
    ) {
      final Object? value = event.snapshot.value;
      if (value is! Map<Object?, Object?>) {
        return null;
      }
      return LiveLocation.fromMap(value, userId: userId);
    });
  }

  @override
  Future<void> clearLiveLocation(String userId) {
    return RetryHelper.run<void>(
      label: 'clear live location',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () =>
          _realtimeDatabaseService.liveLocationRef(userId).remove(),
    );
  }

  @override
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return _locationService.distanceBetween(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }
}
