import 'dart:async';

import '../models/medical_profile.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class MedicalInformationViewModel extends BaseViewModel {
  MedicalInformationViewModel({
    required ProfileRepository profileRepository,
    required String userId,
  }) {
    _subscription = profileRepository.watchMedicalProfile(userId).listen((
      MedicalProfile? medicalProfile,
    ) {
      _medicalProfile = medicalProfile;
      notifyListeners();
    });
  }

  late final StreamSubscription<MedicalProfile?> _subscription;
  MedicalProfile? _medicalProfile;

  MedicalProfile? get medicalProfile => _medicalProfile;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
