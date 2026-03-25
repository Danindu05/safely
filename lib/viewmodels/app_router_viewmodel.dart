import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_enums.dart';
import '../models/auth_account.dart';
import '../models/medical_profile.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/profile_repository.dart';
import '../core/services/preferences_service.dart';

enum AppRouteState {
  splash,
  onboarding,
  login,
  roleSelection,
  permissionSetup,
  medicalSetup,
  emergencyActive,
  safemateShell,
  guardianShell,
}

class AppRouterViewModel extends ChangeNotifier {
  AppRouterViewModel({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required NotificationRepository notificationRepository,
    required PreferencesService preferencesService,
  }) : _authRepository = authRepository,
       _profileRepository = profileRepository,
       _notificationRepository = notificationRepository,
       _preferencesService = preferencesService {
    _initialize();
  }

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final NotificationRepository _notificationRepository;
  final PreferencesService _preferencesService;

  StreamSubscription<AuthAccount?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<MedicalProfile?>? _medicalSubscription;

  bool _isLoading = true;
  AuthAccount? _currentAccount;
  UserProfile? _currentUser;
  MedicalProfile? _medicalProfile;

  bool get onboardingSeen => _preferencesService.onboardingSeen;
  bool get permissionSetupCompleted =>
      _preferencesService.permissionSetupCompleted;
  bool get isLoading => _isLoading;
  AuthAccount? get currentAccount => _currentAccount;
  UserProfile? get currentUser => _currentUser;
  MedicalProfile? get medicalProfile => _medicalProfile;

  AppRouteState get routeState {
    if (_isLoading) {
      return AppRouteState.splash;
    }
    if (!onboardingSeen) {
      return AppRouteState.onboarding;
    }
    if (_currentAccount == null) {
      return AppRouteState.login;
    }
    if (_currentUser == null) {
      return AppRouteState.roleSelection;
    }
    if (!permissionSetupCompleted) {
      return AppRouteState.permissionSetup;
    }
    if (_currentUser!.role == UserRole.safemate) {
      if (_currentUser!.isEmergencyActive) {
        return AppRouteState.emergencyActive;
      }
      if (_medicalProfile == null || _medicalProfile!.fullName.trim().isEmpty) {
        return AppRouteState.medicalSetup;
      }
      return AppRouteState.safemateShell;
    }
    return AppRouteState.guardianShell;
  }

  Future<void> markOnboardingSeen() async {
    await _preferencesService.setOnboardingSeen(true);
    notifyListeners();
  }

  Future<void> markPermissionSetupCompleted() async {
    await _preferencesService.setPermissionSetupCompleted(true);
    notifyListeners();
  }

  Future<void> resetPermissionSetup() async {
    await _preferencesService.setPermissionSetupCompleted(false);
    notifyListeners();
  }

  void _initialize() {
    _authSubscription = _authRepository.authStateChanges().listen(
      _handleAuthChange,
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );

    _handleAuthChange(_authRepository.currentUser);
  }

  Future<void> _handleAuthChange(AuthAccount? account) async {
    _currentAccount = account;
    _currentUser = null;
    _medicalProfile = null;

    await _profileSubscription?.cancel();
    await _medicalSubscription?.cancel();
    _profileSubscription = null;
    _medicalSubscription = null;

    if (account == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await _notificationRepository.syncCurrentToken(account.id);

    _profileSubscription = _profileRepository
        .watchUserProfile(account.id)
        .listen(
          (UserProfile? profile) async {
            _currentUser = profile;

            await _medicalSubscription?.cancel();
            _medicalSubscription = null;

            if (profile?.role == UserRole.safemate) {
              _medicalSubscription = _profileRepository
                  .watchMedicalProfile(profile!.id)
                  .listen((MedicalProfile? medicalProfile) {
                    _medicalProfile = medicalProfile;
                    _isLoading = false;
                    notifyListeners();
                  });
            } else {
              _medicalProfile = null;
              _isLoading = false;
              notifyListeners();
            }

            if (profile == null) {
              _isLoading = false;
              notifyListeners();
            }
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _medicalSubscription?.cancel();
    super.dispose();
  }
}
