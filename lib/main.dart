import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_shell.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_dependencies.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_intent_service.dart';
import 'core/services/permissions_service.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'repositories/alert_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/safety_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final AppDependencies dependencies = await AppDependencies.bootstrap();

  runApp(SafelyRoot(dependencies: dependencies));
}

class SafelyRoot extends StatelessWidget {
  const SafelyRoot({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: dependencies),
        Provider<PreferencesService>.value(
          value: dependencies.preferencesService,
        ),
        Provider<PermissionsService>.value(
          value: dependencies.permissionsService,
        ),
        Provider<ConnectivityService>.value(
          value: dependencies.connectivityService,
        ),
        ChangeNotifierProvider<NotificationIntentService>.value(
          value: dependencies.notificationIntentService,
        ),
        Provider<AuthRepository>.value(value: dependencies.authRepository),
        Provider<ProfileRepository>.value(
          value: dependencies.profileRepository,
        ),
        Provider<AlertRepository>.value(value: dependencies.alertRepository),
        Provider<LocationRepository>.value(
          value: dependencies.locationRepository,
        ),
        Provider<NotificationRepository>.value(
          value: dependencies.notificationRepository,
        ),
        Provider<SafetyRepository>.value(value: dependencies.safetyRepository),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}
