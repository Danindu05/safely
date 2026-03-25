import 'dart:async';

import '../models/app_enums.dart';
import '../models/geofence_zone.dart';
import '../repositories/location_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class GeofenceSetupViewModel extends BaseViewModel {
  GeofenceSetupViewModel({
    required ProfileRepository profileRepository,
    required LocationRepository locationRepository,
    required String userId,
  }) : _profileRepository = profileRepository,
       _locationRepository = locationRepository,
       _userId = userId {
    _subscription = _profileRepository.watchGeofences(_userId).listen((
      GeofenceConfig? config,
    ) {
      _config = config ?? GeofenceConfig.empty(_userId);
      notifyListeners();
    });
  }

  final ProfileRepository _profileRepository;
  final LocationRepository _locationRepository;
  final String _userId;
  StreamSubscription<GeofenceConfig?>? _subscription;
  GeofenceConfig _config = const GeofenceConfig(
    userId: '',
    zones: <GeofenceZone>[],
  );

  GeofenceConfig get config => _config;

  Future<void> addZone({
    required String name,
    required GeofenceType type,
    required double lat,
    required double lng,
    required double radiusMeters,
  }) async {
    final List<GeofenceZone> zones = List<GeofenceZone>.from(_config.zones)
      ..add(
        GeofenceZone(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.trim(),
          type: type,
          lat: lat,
          lng: lng,
          radiusMeters: radiusMeters,
          isEnabled: true,
        ),
      );

    await guard<void>(
      () => _profileRepository.saveGeofenceConfig(
        GeofenceConfig(userId: _userId, zones: zones),
      ),
    );
  }

  Future<void> removeZone(String zoneId) async {
    final List<GeofenceZone> zones = _config.zones
        .where((GeofenceZone zone) => zone.id != zoneId)
        .toList(growable: false);
    await guard<void>(
      () => _profileRepository.saveGeofenceConfig(
        GeofenceConfig(userId: _userId, zones: zones),
      ),
    );
  }

  Future<void> toggleZone(GeofenceZone zone) async {
    final List<GeofenceZone> zones = _config.zones
        .map((GeofenceZone current) {
          if (current.id != zone.id) {
            return current;
          }
          return GeofenceZone(
            id: current.id,
            name: current.name,
            type: current.type,
            lat: current.lat,
            lng: current.lng,
            radiusMeters: current.radiusMeters,
            isEnabled: !current.isEnabled,
          );
        })
        .toList(growable: false);

    await guard<void>(
      () => _profileRepository.saveGeofenceConfig(
        GeofenceConfig(userId: _userId, zones: zones),
      ),
    );
  }

  Future<(double, double)> loadInitialPosition() async {
    final position = await _locationRepository.getCurrentPosition();
    return (position.latitude, position.longitude);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
