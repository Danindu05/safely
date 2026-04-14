import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../firebase_options.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'local_notifications_service.dart';

class BackgroundMonitoringService {
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(safelyBackgroundCallbackDispatcher);
      await Workmanager().registerPeriodicTask(
        AppConstants.backgroundMonitorTaskUniqueName,
        AppConstants.backgroundMonitorTaskName,
        frequency: const Duration(
          minutes: AppConstants.backgroundMonitorIntervalMinimumMinutes,
        ),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
      AppLogger.info('Background safety monitoring registered.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Background safety monitoring registration failed; in-app timers remain active',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

@pragma('vm:entry-point')
void safelyBackgroundCallbackDispatcher() {
  Workmanager().executeTask((String taskName, Map<String, dynamic>? inputData) {
    return _runSafelyBackgroundTask(taskName);
  });
}

Future<bool> _runSafelyBackgroundTask(String taskName) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') {
      rethrow;
    }
  }

  try {
    final User? authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return true;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await firestore
        .collection(FirestoreCollections.users)
        .doc(authUser.uid)
        .get();
    final Map<String, dynamic>? user = userSnapshot.data();
    if (user == null || user[FirestoreFields.role] != 'safemate') {
      return true;
    }

    final DocumentSnapshot<Map<String, dynamic>> settingsSnapshot =
        await firestore
            .collection(FirestoreCollections.settings)
            .doc(authUser.uid)
            .get();
    final Map<String, dynamic> settings =
        settingsSnapshot.data() ?? <String, dynamic>{};

    final int batteryLevel = await Battery().batteryLevel;
    await _updateUserHeartbeat(
      firestore: firestore,
      uid: authUser.uid,
      batteryLevel: batteryLevel,
    );

    await _processPendingGeofenceEvent(
      firestore: firestore,
      preferences: preferences,
      user: user,
      settings: settings,
      batteryLevel: batteryLevel,
    );

    await _evaluateBackgroundBattery(
      firestore: firestore,
      preferences: preferences,
      user: user,
      settings: settings,
      batteryLevel: batteryLevel,
    );
    await _evaluateBackgroundCheckIn(
      firestore: firestore,
      preferences: preferences,
      user: user,
      settings: settings,
      batteryLevel: batteryLevel,
    );
    await _evaluateBackgroundGeofences(
      firestore: firestore,
      preferences: preferences,
      user: user,
      settings: settings,
      batteryLevel: batteryLevel,
    );
    return true;
  } catch (error, stackTrace) {
    AppLogger.error(
      'Background safety task failed',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  }
}

Future<void> _updateUserHeartbeat({
  required FirebaseFirestore firestore,
  required String uid,
  required int batteryLevel,
}) async {
  final Timestamp now = Timestamp.fromDate(DateTime.now());
  await firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .set(<String, Object?>{
        FirestoreFields.batteryLevel: batteryLevel,
        FirestoreFields.lastSeenAt: now,
        FirestoreFields.updatedAt: now,
      }, SetOptions(merge: true));
}

Future<void> _evaluateBackgroundBattery({
  required FirebaseFirestore firestore,
  required SharedPreferences preferences,
  required Map<String, dynamic> user,
  required Map<String, dynamic> settings,
  required int batteryLevel,
}) async {
  final int warningThreshold =
      (settings[FirestoreFields.lowBatteryWarningPercent] as num?)?.toInt() ??
      AppConstants.lowBatteryWarningFallback;
  final int criticalThreshold =
      (settings[FirestoreFields.lowBatteryCriticalPercent] as num?)?.toInt() ??
      AppConstants.lowBatteryCriticalFallback;

  final int? threshold = batteryLevel <= criticalThreshold
      ? criticalThreshold
      : batteryLevel <= warningThreshold
      ? warningThreshold
      : null;
  final int? previousThreshold = preferences.getInt(
    AppConstants.lastBatteryAlertLevelKey,
  );

  if (threshold == null) {
    if (batteryLevel > warningThreshold) {
      await preferences.remove(AppConstants.lastBatteryAlertLevelKey);
    }
    return;
  }
  if (previousThreshold == threshold) {
    return;
  }

  final Position? position = await _bestEffortPosition();
  final String? alertId = await _createAlert(
    firestore: firestore,
    user: user,
    type: 'low_battery',
    title: batteryLevel <= criticalThreshold
        ? 'Critical battery level'
        : 'Battery running low',
    description: batteryLevel <= criticalThreshold
        ? 'Battery critical — last location shared'
        : '${_userName(user)} is at $batteryLevel% battery.',
    batteryLevel: batteryLevel,
    position: position,
  );

  if (batteryLevel <= criticalThreshold &&
      user[FirestoreFields.isEmergencyActive] != true) {
    await _activateCriticalBatteryEmergency(
      firestore: firestore,
      user: user,
      alertId: alertId,
      position: position,
    );
  }

  await preferences.setInt(AppConstants.lastBatteryAlertLevelKey, threshold);
  if (_notificationEnabled(settings, 'low_battery')) {
    await _showBackgroundNotification(
      title: batteryLevel <= criticalThreshold
          ? 'Critical battery level'
          : 'Battery running low',
      body: 'Guardians can see this battery warning.',
    );
  }
}

Future<void> _evaluateBackgroundCheckIn({
  required FirebaseFirestore firestore,
  required SharedPreferences preferences,
  required Map<String, dynamic> user,
  required Map<String, dynamic> settings,
  required int batteryLevel,
}) async {
  final bool checkInEnabled =
      settings[FirestoreFields.checkInEnabled] as bool? ?? true;
  if (!checkInEnabled) {
    await preferences.remove(AppConstants.backgroundCheckInPromptStartedAtKey);
    return;
  }

  final int intervalMinutes =
      (settings[FirestoreFields.checkInIntervalMinutes] as num?)?.toInt() ?? 60;
  final DateTime now = DateTime.now();
  final String userId = user[FirestoreFields.id] as String? ?? '';
  if (userId.isEmpty) {
    return;
  }

  final QuerySnapshot<Map<String, dynamic>> checkIns = await firestore
      .collection(FirestoreCollections.checkins)
      .where(FirestoreFields.userId, isEqualTo: userId)
      .orderBy(FirestoreFields.timestamp, descending: true)
      .limit(1)
      .get();
  final Timestamp? latestCheckIn = checkIns.docs.isEmpty
      ? null
      : checkIns.docs.first.data()[FirestoreFields.timestamp] as Timestamp?;
  final Timestamp? lastSeen = user[FirestoreFields.lastSeenAt] as Timestamp?;
  final Timestamp? updatedAt = user[FirestoreFields.updatedAt] as Timestamp?;
  final DateTime referenceTime =
      latestCheckIn?.toDate() ??
      lastSeen?.toDate() ??
      updatedAt?.toDate() ??
      now;

  final String? promptStartedRaw = preferences.getString(
    AppConstants.backgroundCheckInPromptStartedAtKey,
  );
  final DateTime? promptStartedAt = DateTime.tryParse(promptStartedRaw ?? '');
  if (promptStartedAt != null) {
    final DateTime? latestCheckInAt = latestCheckIn?.toDate();
    if (latestCheckInAt != null &&
        latestCheckInAt.isAfter(
          promptStartedAt.subtract(const Duration(seconds: 1)),
        )) {
      await preferences.remove(
        AppConstants.backgroundCheckInPromptStartedAtKey,
      );
      return;
    }

    if (now.difference(promptStartedAt).inSeconds <
        AppConstants.checkInPromptTimeoutSeconds) {
      return;
    }

    final Position? position = await _bestEffortPosition();
    await _createCheckIn(
      firestore: firestore,
      userId: userId,
      type: 'missed',
      status: 'missed',
      batteryLevel: batteryLevel,
      position: position,
    );
    await _createAlert(
      firestore: firestore,
      user: user,
      type: 'missed_checkin',
      title: 'Missed safety check-in',
      description: 'User did not respond to check-in.',
      batteryLevel: batteryLevel,
      position: position,
    );
    await preferences.remove(AppConstants.backgroundCheckInPromptStartedAtKey);
    return;
  }

  if (now.difference(referenceTime).inMinutes >= intervalMinutes) {
    await preferences.setString(
      AppConstants.backgroundCheckInPromptStartedAtKey,
      now.toIso8601String(),
    );
    if (_notificationEnabled(settings, 'missed_checkin')) {
      await _showBackgroundNotification(
        title: 'Are you safe?',
        body: 'Open Safely and tap "I\'m Safe" to check in.',
      );
    }
  }
}

Future<void> _evaluateBackgroundGeofences({
  required FirebaseFirestore firestore,
  required SharedPreferences preferences,
  required Map<String, dynamic> user,
  required Map<String, dynamic> settings,
  required int batteryLevel,
}) async {
  final bool geofencingEnabled =
      settings[FirestoreFields.geofencingEnabled] as bool? ?? false;
  if (!geofencingEnabled) {
    await preferences.remove(AppConstants.activeGeofenceZoneIdKey);
    return;
  }

  final String userId = user[FirestoreFields.id] as String? ?? '';
  if (userId.isEmpty) {
    return;
  }
  final DocumentSnapshot<Map<String, dynamic>> snapshot = await firestore
      .collection(FirestoreCollections.geofences)
      .doc(userId)
      .get();
  final List<dynamic> zones =
      snapshot.data()?[FirestoreFields.zones] as List<dynamic>? ??
      const <dynamic>[];
  if (zones.isEmpty) {
    await preferences.remove(AppConstants.activeGeofenceZoneIdKey);
    return;
  }

  final Position? position = await _bestEffortPosition();
  if (position == null) {
    return;
  }

  Map<String, dynamic>? unsafeZone;
  for (final Object? zoneValue in zones) {
    if (zoneValue is! Map) {
      continue;
    }
    final Map<String, dynamic> zone = zoneValue.cast<String, dynamic>();
    if (zone[FirestoreFields.type] != 'unsafe' || zone['isEnabled'] == false) {
      continue;
    }

    final double lat =
        (zone[FirestoreFields.locationLat] as num?)?.toDouble() ?? 0;
    final double lng =
        (zone[FirestoreFields.locationLng] as num?)?.toDouble() ?? 0;
    final double radius = (zone['radiusMeters'] as num?)?.toDouble() ?? 100;
    final double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lng,
    );
    if (distance <= radius) {
      unsafeZone = zone;
      break;
    }
  }

  if (unsafeZone == null) {
    await preferences.remove(AppConstants.activeGeofenceZoneIdKey);
    return;
  }

  final String zoneId = unsafeZone[FirestoreFields.id] as String? ?? '';
  if (zoneId.isNotEmpty &&
      preferences.getString(AppConstants.activeGeofenceZoneIdKey) == zoneId) {
    return;
  }

  await _createAlert(
    firestore: firestore,
    user: user,
    type: 'geofence',
    title: 'Entered unsafe zone',
    description:
        '${_userName(user)} entered ${unsafeZone[FirestoreFields.name] ?? 'an unsafe zone'}.',
    batteryLevel: batteryLevel,
    position: position,
  );
  await preferences.setString(AppConstants.activeGeofenceZoneIdKey, zoneId);
  if (_notificationEnabled(settings, 'geofence')) {
    await _showBackgroundNotification(
      title: 'Unsafe zone detected',
      body: 'Guardians can see this location warning.',
    );
  }
}

Future<void> _processPendingGeofenceEvent({
  required FirebaseFirestore firestore,
  required SharedPreferences preferences,
  required Map<String, dynamic> user,
  required Map<String, dynamic> settings,
  required int batteryLevel,
}) async {
  final String? rawEvent = preferences.getString(
    AppConstants.pendingGeofenceEventJsonKey,
  );
  if (rawEvent == null || rawEvent.isEmpty) {
    return;
  }

  final Object? decoded = jsonDecode(rawEvent);
  if (decoded is! Map) {
    await preferences.remove(AppConstants.pendingGeofenceEventJsonKey);
    return;
  }

  final Map<String, dynamic> event = decoded.cast<String, dynamic>();
  if (event['transition'] != 'enter' || event['type'] != 'unsafe') {
    await preferences.remove(AppConstants.pendingGeofenceEventJsonKey);
    return;
  }

  await _createAlert(
    firestore: firestore,
    user: user,
    type: 'geofence',
    title: 'Entered unsafe zone',
    description:
        '${_userName(user)} entered ${event['name'] ?? 'an unsafe zone'}.',
    batteryLevel: batteryLevel,
    position: null,
    locationLat: (event['lat'] as num?)?.toDouble(),
    locationLng: (event['lng'] as num?)?.toDouble(),
  );
  await preferences.remove(AppConstants.pendingGeofenceEventJsonKey);
  if (_notificationEnabled(settings, 'geofence')) {
    await _showBackgroundNotification(
      title: 'Unsafe zone detected',
      body: 'Guardians can see this location warning.',
    );
  }
}

Future<String?> _createAlert({
  required FirebaseFirestore firestore,
  required Map<String, dynamic> user,
  required String type,
  required String title,
  required String description,
  required int batteryLevel,
  required Position? position,
  double? locationLat,
  double? locationLng,
}) async {
  final String userId = user[FirestoreFields.id] as String? ?? '';
  if (userId.isEmpty) {
    return null;
  }

  final DateTime now = DateTime.now();
  final String alertId = '${type}_${now.microsecondsSinceEpoch}';
  await firestore
      .collection(FirestoreCollections.alerts)
      .doc(alertId)
      .set(<String, Object?>{
        FirestoreFields.id: alertId,
        FirestoreFields.userId: userId,
        FirestoreFields.guardianIds:
            user[FirestoreFields.guardianIds] as List<dynamic>? ??
            const <String>[],
        FirestoreFields.type: type,
        FirestoreFields.status: 'active',
        FirestoreFields.title: title,
        FirestoreFields.description: description,
        FirestoreFields.timestamp: Timestamp.fromDate(now),
        FirestoreFields.locationLat: locationLat ?? position?.latitude,
        FirestoreFields.locationLng: locationLng ?? position?.longitude,
        FirestoreFields.batteryLevel: batteryLevel,
        FirestoreFields.audioUrl: null,
        FirestoreFields.acknowledgedBy: null,
        FirestoreFields.acknowledgedAt: null,
        FirestoreFields.canceledByUser: false,
        FirestoreFields.resolvedAt: null,
      });
  return alertId;
}

Future<void> _activateCriticalBatteryEmergency({
  required FirebaseFirestore firestore,
  required Map<String, dynamic> user,
  required String? alertId,
  required Position? position,
}) async {
  final String userId = user[FirestoreFields.id] as String? ?? '';
  if (userId.isEmpty) {
    return;
  }

  final DateTime now = DateTime.now();
  await firestore
      .collection(FirestoreCollections.users)
      .doc(userId)
      .set(<String, Object?>{
        FirestoreFields.isEmergencyActive: true,
        FirestoreFields.updatedAt: Timestamp.fromDate(now),
        if (position != null)
          FirestoreFields.lastLocationSyncAt: Timestamp.fromDate(now),
      }, SetOptions(merge: true));

  if (alertId != null && alertId.isNotEmpty) {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(AppConstants.activeAlertIdKey, alertId);
  }

  if (position == null) {
    return;
  }

  final List<dynamic> guardianIds =
      user[FirestoreFields.guardianIds] as List<dynamic>? ?? const <dynamic>[];
  final Map<String, bool> guardianAccess = <String, bool>{
    for (final Object? value in guardianIds)
      if (value is String && value.trim().isNotEmpty) value.trim(): true,
  };

  await FirebaseDatabase.instance
      .ref('live_locations/$userId')
      .set(<String, Object?>{
        'guardianIds': guardianAccess.keys.toList(growable: false),
        'guardianAccess': guardianAccess,
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'updatedAt': now.toIso8601String(),
        'isEmergencyActive': true,
        'source': 'low_battery',
      });
}

Future<void> _createCheckIn({
  required FirebaseFirestore firestore,
  required String userId,
  required String type,
  required String status,
  required int batteryLevel,
  required Position? position,
}) async {
  final DateTime now = DateTime.now();
  final String checkInId = '${type}_${now.microsecondsSinceEpoch}';
  await firestore
      .collection(FirestoreCollections.checkins)
      .doc(checkInId)
      .set(<String, Object?>{
        FirestoreFields.id: checkInId,
        FirestoreFields.userId: userId,
        FirestoreFields.type: type,
        FirestoreFields.timestamp: Timestamp.fromDate(now),
        FirestoreFields.batteryLevel: batteryLevel,
        FirestoreFields.locationLat: position?.latitude,
        FirestoreFields.locationLng: position?.longitude,
        FirestoreFields.status: status,
      });
}

Future<Position?> _bestEffortPosition() async {
  try {
    return await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: AppConstants.liveLocationDistanceFilterMeters,
          ),
        );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Background location lookup failed',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

Future<void> _showBackgroundNotification({
  required String title,
  required String body,
}) async {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidSettings,
  );
  await plugin.initialize(settings: initializationSettings);
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(LocalNotificationsService.alertsChannel);
  await plugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.alertsNotificationChannelId,
        AppConstants.alertsNotificationChannelName,
        channelDescription: AppConstants.alertsNotificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

bool _notificationEnabled(Map<String, dynamic> settings, String type) {
  switch (type) {
    case 'sos':
      return settings[FirestoreFields.sosNotificationsEnabled] as bool? ?? true;
    case 'low_battery':
      return settings[FirestoreFields.batteryNotificationsEnabled] as bool? ??
          true;
    case 'geofence':
    case 'route_deviation':
      return settings[FirestoreFields.geofenceNotificationsEnabled] as bool? ??
          true;
    case 'missed_checkin':
    case 'manual_checkin':
      return settings[FirestoreFields.checkInNotificationsEnabled] as bool? ??
          true;
    default:
      return true;
  }
}

String _userName(Map<String, dynamic> user) {
  final String name = (user[FirestoreFields.name] as String?)?.trim() ?? '';
  return name.isEmpty ? 'Safemate' : name;
}
