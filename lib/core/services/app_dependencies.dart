import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/alert_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/notification_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/safety_repository.dart';
import 'audio_recording_service.dart';
import 'battery_service.dart';
import 'connectivity_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_messaging_service.dart';
import 'firebase_storage_service.dart';
import 'firestore_service.dart';
import 'local_notifications_service.dart';
import 'location_service.dart';
import 'notification_intent_service.dart';
import 'permissions_service.dart';
import 'preferences_service.dart';
import 'realtime_database_service.dart';

class AppDependencies {
  AppDependencies({
    required this.preferencesService,
    required this.permissionsService,
    required this.connectivityService,
    required this.notificationIntentService,
    required this.authRepository,
    required this.profileRepository,
    required this.alertRepository,
    required this.locationRepository,
    required this.notificationRepository,
    required this.safetyRepository,
  });

  final PreferencesService preferencesService;
  final PermissionsService permissionsService;
  final ConnectivityService connectivityService;
  final NotificationIntentService notificationIntentService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final AlertRepository alertRepository;
  final LocationRepository locationRepository;
  final NotificationRepository notificationRepository;
  final SafetyRepository safetyRepository;

  static Future<AppDependencies> bootstrap() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();

    final NotificationIntentService notificationIntentService =
        NotificationIntentService();
    final LocalNotificationsService localNotificationsService =
        LocalNotificationsService(notificationIntentService);
    await localNotificationsService.initialize();

    final FirebaseAuthService authService = FirebaseAuthService(
      FirebaseAuth.instance,
    );
    final FirestoreService firestoreService = FirestoreService(
      FirebaseFirestore.instance,
    );
    final RealtimeDatabaseService realtimeDatabaseService =
        RealtimeDatabaseService(FirebaseDatabase.instance);
    final FirebaseStorageService storageService = FirebaseStorageService(
      FirebaseStorage.instance,
    );
    final FirebaseMessagingService messagingService = FirebaseMessagingService(
      FirebaseMessaging.instance,
    );
    final LocationService locationService = LocationService();
    final BatteryService batteryService = BatteryService(Battery());
    final AudioRecordingService audioRecordingService = AudioRecordingService(
      AudioRecorder(),
    );

    final PreferencesService preferencesService = PreferencesService(
      sharedPreferences,
    );
    final PermissionsService permissionsService = PermissionsService();
    final ConnectivityService connectivityService = ConnectivityService(
      Connectivity(),
    );

    final AuthRepository authRepository = FirebaseAuthRepository(authService);
    final ProfileRepository profileRepository = FirebaseProfileRepository(
      firestoreService,
    );
    final AlertRepository alertRepository = FirebaseAlertRepository(
      firestoreService,
    );
    final LocationRepository locationRepository = FirebaseLocationRepository(
      locationService: locationService,
      realtimeDatabaseService: realtimeDatabaseService,
    );
    final NotificationRepository notificationRepository =
        FirebaseNotificationRepository(
          messagingService: messagingService,
          localNotificationsService: localNotificationsService,
          notificationIntentService: notificationIntentService,
          profileRepository: profileRepository,
        );
    final SafetyRepository safetyRepository = DefaultSafetyRepository(
      alertRepository: alertRepository,
      profileRepository: profileRepository,
      locationRepository: locationRepository,
      batteryService: batteryService,
      audioRecordingService: audioRecordingService,
      storageService: storageService,
      preferencesService: preferencesService,
      localNotificationsService: localNotificationsService,
    );

    await notificationRepository.initialize();

    return AppDependencies(
      preferencesService: preferencesService,
      permissionsService: permissionsService,
      connectivityService: connectivityService,
      notificationIntentService: notificationIntentService,
      authRepository: authRepository,
      profileRepository: profileRepository,
      alertRepository: alertRepository,
      locationRepository: locationRepository,
      notificationRepository: notificationRepository,
      safetyRepository: safetyRepository,
    );
  }
}
