import 'dart:async';

import '../models/geofence_zone.dart';
import '../models/live_location.dart';
import '../models/user_profile.dart';
import '../repositories/location_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class GuardianLiveMapViewModel extends BaseViewModel {
  GuardianLiveMapViewModel({
    required ProfileRepository profileRepository,
    required LocationRepository locationRepository,
    required String guardianId,
  }) : _profileRepository = profileRepository,
       _locationRepository = locationRepository,
       _guardianId = guardianId {
    _safemateSubscription = _profileRepository
        .watchLinkedSafemates(_guardianId)
        .listen((List<UserProfile> safemates) {
          _safemates = safemates;
          if (_selectedSafemateId == null && safemates.isNotEmpty) {
            selectSafemate(safemates.first.id);
          }
          notifyListeners();
        });
  }

  final ProfileRepository _profileRepository;
  final LocationRepository _locationRepository;
  final String _guardianId;

  StreamSubscription<List<UserProfile>>? _safemateSubscription;
  StreamSubscription<LiveLocation?>? _liveLocationSubscription;
  StreamSubscription<GeofenceConfig?>? _geofenceSubscription;

  List<UserProfile> _safemates = const <UserProfile>[];
  String? _selectedSafemateId;
  LiveLocation? _liveLocation;
  List<GeofenceZone> _geofenceZones = const <GeofenceZone>[];

  List<UserProfile> get safemates => _safemates;
  String? get selectedSafemateId => _selectedSafemateId;
  LiveLocation? get liveLocation => _liveLocation;
  List<GeofenceZone> get geofenceZones => _geofenceZones;

  void selectSafemate(String userId) {
    _selectedSafemateId = userId;
    _liveLocationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    _liveLocationSubscription = _locationRepository
        .watchLiveLocation(userId)
        .listen((LiveLocation? location) {
          _liveLocation = location;
          notifyListeners();
        });
    _geofenceSubscription = _profileRepository.watchGeofences(userId).listen((
      GeofenceConfig? config,
    ) {
      _geofenceZones =
          config?.zones
              .where((GeofenceZone zone) => zone.isEnabled)
              .toList(growable: false) ??
          const <GeofenceZone>[];
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _safemateSubscription?.cancel();
    _liveLocationSubscription?.cancel();
    _geofenceSubscription?.cancel();
    super.dispose();
  }
}
