import '../models/medical_profile.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class MedicalProfileSetupViewModel extends BaseViewModel {
  MedicalProfileSetupViewModel({
    required ProfileRepository profileRepository,
    required UserProfile userProfile,
  }) : _profileRepository = profileRepository,
       _userProfile = userProfile;

  final ProfileRepository _profileRepository;
  final UserProfile _userProfile;

  Future<bool> saveMedicalProfile({
    required String fullName,
    required String bloodGroup,
    required String allergies,
    required String medicalConditions,
    required String emergencyNotes,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    final bool? result = await guard<bool>(() async {
      await _profileRepository.saveMedicalProfile(
        MedicalProfile(
          userId: _userProfile.id,
          fullName: fullName.trim(),
          bloodGroup: bloodGroup.trim(),
          allergies: allergies.trim(),
          medicalConditions: medicalConditions.trim(),
          emergencyNotes: emergencyNotes.trim(),
          emergencyContactName: emergencyContactName.trim(),
          emergencyContactPhone: emergencyContactPhone.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      await _profileRepository.saveUserProfile(
        _userProfile.copyWith(
          emergencyContactName: emergencyContactName.trim(),
          emergencyContactPhone: emergencyContactPhone.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      return true;
    });
    return result ?? false;
  }
}
