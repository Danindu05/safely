import 'dart:async';

import '../models/app_enums.dart';
import '../models/medical_profile.dart';
import '../models/safety_alert.dart';
import '../models/user_profile.dart';
import '../repositories/alert_repository.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class AlertDetailViewModel extends BaseViewModel {
  AlertDetailViewModel({
    required AlertRepository alertRepository,
    required ProfileRepository profileRepository,
    required String alertId,
    required String guardianId,
  }) : _alertRepository = alertRepository,
       _profileRepository = profileRepository,
       _guardianId = guardianId {
    _alertSubscription = _alertRepository.watchAlert(alertId).listen((
      SafetyAlert? alert,
    ) {
      _alert = alert;
      _bindProfile(alert?.userId);
      notifyListeners();
    });
  }

  final AlertRepository _alertRepository;
  final ProfileRepository _profileRepository;
  final String _guardianId;
  StreamSubscription<SafetyAlert?>? _alertSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<MedicalProfile?>? _medicalSubscription;

  SafetyAlert? _alert;
  UserProfile? _profile;
  MedicalProfile? _medicalProfile;

  SafetyAlert? get alert => _alert;
  UserProfile? get profile => _profile;
  MedicalProfile? get medicalProfile => _medicalProfile;

  void _bindProfile(String? userId) {
    if (userId == null) {
      _profile = null;
      _medicalProfile = null;
      notifyListeners();
      return;
    }
    _profileSubscription?.cancel();
    _medicalSubscription?.cancel();
    _profileSubscription = _profileRepository.watchUserProfile(userId).listen((
      UserProfile? profile,
    ) {
      _profile = profile;
      notifyListeners();
    });
    _medicalSubscription = _profileRepository
        .watchMedicalProfile(userId)
        .listen((MedicalProfile? medicalProfile) {
          _medicalProfile = medicalProfile;
          notifyListeners();
        });
  }

  Future<void> acknowledgeHandling() async {
    if (_alert == null) {
      return;
    }

    await guard<void>(
      () => _alertRepository.updateAlert(
        _alert!.copyWith(
          status: AlertStatus.acknowledged,
          acknowledgedBy: _guardianId,
          acknowledgedAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _profileSubscription?.cancel();
    _medicalSubscription?.cancel();
    super.dispose();
  }
}
