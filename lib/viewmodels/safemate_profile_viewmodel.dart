import 'dart:async';

import '../models/medical_profile.dart';
import '../models/safety_alert.dart';
import '../models/user_profile.dart';
import '../repositories/alert_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class SafemateProfileViewModel extends BaseViewModel {
  SafemateProfileViewModel({
    required ProfileRepository profileRepository,
    required AlertRepository alertRepository,
    required String safemateId,
  }) : _profileRepository = profileRepository,
       _alertRepository = alertRepository,
       _safemateId = safemateId {
    _profileSubscription = _profileRepository
        .watchUserProfile(_safemateId)
        .listen((UserProfile? profile) {
          _profile = profile;
          notifyListeners();
        });
    _medicalSubscription = _profileRepository
        .watchMedicalProfile(_safemateId)
        .listen((MedicalProfile? medicalProfile) {
          _medicalProfile = medicalProfile;
          notifyListeners();
        });
    _alertsSubscription = _alertRepository
        .watchAlertsForUser(_safemateId)
        .listen((List<SafetyAlert> alerts) {
          _alerts = alerts.take(5).toList(growable: false);
          notifyListeners();
        });
  }

  final ProfileRepository _profileRepository;
  final AlertRepository _alertRepository;
  final String _safemateId;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<MedicalProfile?>? _medicalSubscription;
  StreamSubscription<List<SafetyAlert>>? _alertsSubscription;

  UserProfile? _profile;
  MedicalProfile? _medicalProfile;
  List<SafetyAlert> _alerts = const <SafetyAlert>[];

  UserProfile? get profile => _profile;
  MedicalProfile? get medicalProfile => _medicalProfile;
  List<SafetyAlert> get alerts => _alerts;

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _medicalSubscription?.cancel();
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
