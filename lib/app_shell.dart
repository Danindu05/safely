import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/common/onboarding_screen.dart';
import 'screens/common/permission_setup_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/guardian/guardian_shell_screen.dart';
import 'screens/safemate/emergency_active_screen.dart';
import 'screens/safemate/medical_profile_setup_screen.dart';
import 'screens/safemate/safemate_shell_screen.dart';
import 'viewmodels/app_router_viewmodel.dart';
import 'repositories/auth_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/profile_repository.dart';
import 'core/services/preferences_service.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppRouterViewModel>(
      create: (_) => AppRouterViewModel(
        authRepository: context.read<AuthRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        notificationRepository: context.read<NotificationRepository>(),
        preferencesService: context.read<PreferencesService>(),
      ),
      child: Consumer<AppRouterViewModel>(
        builder:
            (BuildContext context, AppRouterViewModel router, Widget? child) {
              switch (router.routeState) {
                case AppRouteState.splash:
                  return const SplashScreen();
                case AppRouteState.onboarding:
                  return OnboardingScreen(
                    onContinue: router.markOnboardingSeen,
                  );
                case AppRouteState.login:
                  return const LoginScreen();
                case AppRouteState.roleSelection:
                  return RoleSelectionScreen(
                    userId: router.currentAccount!.id,
                    email: router.currentAccount!.email,
                    initialName: router.currentAccount!.fallbackName,
                  );
                case AppRouteState.permissionSetup:
                  return PermissionSetupScreen(
                    onContinue: router.markPermissionSetupCompleted,
                  );
                case AppRouteState.medicalSetup:
                  return MedicalProfileSetupScreen(
                    userProfile: router.currentUser!,
                  );
                case AppRouteState.emergencyActive:
                  return EmergencyActiveScreen(
                    userProfile: router.currentUser!,
                  );
                case AppRouteState.safemateShell:
                  return SafemateShellScreen(userProfile: router.currentUser!);
                case AppRouteState.guardianShell:
                  return GuardianShellScreen(userProfile: router.currentUser!);
              }
            },
      ),
    );
  }
}
