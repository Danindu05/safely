import 'package:flutter/services.dart';

import '../../models/app_enums.dart';
import '../../models/geofence_zone.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class GeofenceRegistrationService {
  GeofenceRegistrationService({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ??
          const MethodChannel(AppConstants.geofenceMethodChannel);

  final MethodChannel _methodChannel;

  Future<bool> registerGeofences(
    GeofenceConfig config, {
    bool geofenceNotificationsEnabled = true,
  }) async {
    try {
      final List<Map<String, Object?>> zones = config.zones
          .where((GeofenceZone zone) => zone.isEnabled)
          .map(
            (GeofenceZone zone) => <String, Object?>{
              'id': zone.id,
              'name': zone.name,
              'type': zone.type.value,
              'lat': zone.lat,
              'lng': zone.lng,
              'radiusMeters': zone.radiusMeters,
            },
          )
          .toList(growable: false);

      final bool? registered = await _methodChannel
          .invokeMethod<bool>('registerGeofences', <String, Object?>{
            'userId': config.userId,
            'geofenceNotificationsEnabled': geofenceNotificationsEnabled,
            'zones': zones,
          });
      return registered ?? false;
    } catch (error, stackTrace) {
      AppLogger.error(
        'OS geofence registration failed; app-side checks remain active',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> clearGeofences() async {
    try {
      await _methodChannel.invokeMethod<void>('clearGeofences');
    } catch (error, stackTrace) {
      AppLogger.error(
        'OS geofence clear failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
