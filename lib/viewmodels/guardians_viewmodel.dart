import 'dart:async';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'base_viewmodel.dart';

class GuardiansViewModel extends BaseViewModel {
  GuardiansViewModel({
    required ProfileRepository profileRepository,
    required String safemateId,
  }) : _profileRepository = profileRepository,
       _safemateId = safemateId {
    _bind();
  }

  final ProfileRepository _profileRepository;
  final String _safemateId;

  StreamSubscription<List<UserProfile>>? _guardiansSubscription;
  List<UserProfile> _guardians = const <UserProfile>[];

  List<UserProfile> get guardians => _guardians;

  void _bind() {
    _guardiansSubscription = _profileRepository
        .watchLinkedGuardians(_safemateId)
        .listen((List<UserProfile> guardians) {
          _guardians = guardians;
          notifyListeners();
        });
  }

  Future<void> addGuardian(String guardianId) async {
    if (guardianId.trim().isEmpty) {
      setError(StateError('Enter a guardian ID to link.'));
      return;
    }

    await guard<void>(
      () => _profileRepository.linkGuardian(
        safemateId: _safemateId,
        guardianId: guardianId.trim(),
      ),
    );

    if (errorMessage == null) {
      setInfo('Guardian linked.');
    }
  }

  Future<void> removeGuardian(String guardianId) async {
    await guard<void>(
      () => _profileRepository.unlinkGuardian(
        safemateId: _safemateId,
        guardianId: guardianId,
      ),
    );

    if (errorMessage == null) {
      setInfo('Guardian removed.');
    }
  }

  @override
  void dispose() {
    _guardiansSubscription?.cancel();
    super.dispose();
  }
}
