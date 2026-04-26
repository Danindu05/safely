import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/app_dependencies.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/common/onboarding_screen.dart';
import 'screens/common/permission_setup_screen.dart';
import 'core/utils/app_logger.dart';
import 'screens/guardian/alert_detail_screen.dart';
import 'screens/guardian/guardian_shell_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/safemate/emergency_active_screen.dart';
import 'screens/safemate/medical_profile_setup_screen.dart';
import 'screens/safemate/safemate_shell_screen.dart';
import 'core/services/notification_intent_service.dart';
import 'viewmodels/app_router_viewmodel.dart';
import 'repositories/auth_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/profile_repository.dart';
import 'core/services/preferences_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _deferredInitializationStarted = false;
  bool _minimumSplashComplete = false;
  String? _scheduledPendingAlertId;
  Timer? _minimumSplashTimer;

  @override
  void initState() {
    super.initState();
    _minimumSplashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _minimumSplashComplete = true;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deferredInitializationStarted) {
      return;
    }

    _deferredInitializationStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AppDependencies>().initializeDeferredServices().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        AppLogger.error(
          'Deferred service initialization failed',
          error: error,
          stackTrace: stackTrace,
        );
      });
    });
  }

  void _handlePendingAlertNavigation(
    BuildContext context,
    AppRouteState effectiveRouteState,
    AppRouterViewModel router,
    NotificationIntentService notificationIntentService,
  ) {
    if (effectiveRouteState != AppRouteState.guardianShell) {
      _scheduledPendingAlertId = null;
      return;
    }

    final String? pendingAlertId = notificationIntentService.pendingAlertId;
    final String? guardianId = router.currentUser?.id;
    if (pendingAlertId == null || guardianId == null) {
      _scheduledPendingAlertId = null;
      return;
    }
    if (_scheduledPendingAlertId == pendingAlertId) {
      return;
    }
    _scheduledPendingAlertId = pendingAlertId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? alertId = notificationIntentService.takePendingAlertId();
      _scheduledPendingAlertId = null;
      if (alertId == null || !context.mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AlertDetailScreen(alertId: alertId, guardianId: guardianId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppRouterViewModel>(
      create: (_) => AppRouterViewModel(
        authRepository: context.read<AuthRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        notificationRepository: context.read<NotificationRepository>(),
        preferencesService: context.read<PreferencesService>(),
      ),
      child: Consumer2<AppRouterViewModel, NotificationIntentService>(
        builder:
            (
              BuildContext context,
              AppRouterViewModel router,
              NotificationIntentService notificationIntentService,
              Widget? child,
            ) {
              final AppRouteState effectiveRouteState = _minimumSplashComplete
                  ? router.routeState
                  : AppRouteState.splash;

              _handlePendingAlertNavigation(
                context,
                effectiveRouteState,
                router,
                notificationIntentService,
              );

              switch (effectiveRouteState) {
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

  @override
  void dispose() {
    _minimumSplashTimer?.cancel();
    super.dispose();
  }
}
