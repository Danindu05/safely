import 'dart:async';

import '../models/safety_alert.dart';
import '../models/user_profile.dart';
import '../repositories/alert_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class GuardianDashboardViewModel extends BaseViewModel {
  GuardianDashboardViewModel({
    required ProfileRepository profileRepository,
    required AlertRepository alertRepository,
    required String guardianId,
  }) : _profileRepository = profileRepository,
       _alertRepository = alertRepository,
       _guardianId = guardianId {
    _safemateSubscription = _profileRepository
        .watchLinkedSafemates(_guardianId)
        .listen((List<UserProfile> safemates) {
          _linkedSafemates = safemates;
          notifyListeners();
        });
    _alertsSubscription = _alertRepository
        .watchAlertsForGuardian(_guardianId)
        .listen((List<SafetyAlert> alerts) {
          _alerts = alerts;
          notifyListeners();
        });
  }

  final ProfileRepository _profileRepository;
  final AlertRepository _alertRepository;
  final String _guardianId;
  StreamSubscription<List<UserProfile>>? _safemateSubscription;
  StreamSubscription<List<SafetyAlert>>? _alertsSubscription;

  List<UserProfile> _linkedSafemates = const <UserProfile>[];
  List<SafetyAlert> _alerts = const <SafetyAlert>[];

  List<UserProfile> get linkedSafemates => _linkedSafemates;
  List<SafetyAlert> get alerts => _alerts;

  SafetyAlert? latestAlertFor(String userId) {
    for (final SafetyAlert alert in _alerts) {
      if (alert.userId == userId) {
        return alert;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _safemateSubscription?.cancel();
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
