import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/retry_helper.dart';
import '../models/geofence_zone.dart';
import '../models/medical_profile.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchUserProfile(String uid);

  Stream<List<UserProfile>> watchLinkedGuardians(String uid);

  Stream<List<UserProfile>> watchLinkedSafemates(String uid);

  Future<void> saveUserProfile(UserProfile profile);

  Future<void> ensureAccountScaffold({
    required String uid,
    required String name,
    required String email,
  });

  Future<void> setRole({
    required String uid,
    required String name,
    required String email,
    required String roleValue,
  });

  Future<void> updateFcmToken(String uid, String? token);

  Future<void> updateBatteryLevel({
    required String uid,
    required int batteryLevel,
  });

  Future<void> updateLastSeen(String uid);

  Future<void> updateLastLocationSync(String uid, DateTime timestamp);

  Future<void> setEmergencyState({
    required String uid,
    required bool isEmergencyActive,
  });

  Future<void> linkGuardian({
    required String safemateId,
    required String guardianId,
  });

  Future<void> unlinkGuardian({
    required String safemateId,
    required String guardianId,
  });

  Stream<MedicalProfile?> watchMedicalProfile(String uid);

  Future<void> saveMedicalProfile(MedicalProfile profile);

  Stream<UserSettings?> watchSettings(String uid);

  Future<void> saveSettings(UserSettings settings);

  Stream<GeofenceConfig?> watchGeofences(String uid);

  Future<void> saveGeofenceConfig(GeofenceConfig config);
}

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestoreService.users.doc(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      try {
        return UserProfile.fromMap(data, documentId: snapshot.id);
      } on FormatException {
        AppLogger.warning(
          'User profile $uid is present but role setup is incomplete.',
        );
        return null;
      }
    });
  }

  @override
  Stream<List<UserProfile>> watchLinkedGuardians(String uid) {
    return _firestoreService.users
        .where(FirestoreFields.safemateIds, arrayContains: uid)
        .snapshots()
        .map(_mapUserProfiles);
  }

  @override
  Stream<List<UserProfile>> watchLinkedSafemates(String uid) {
    return _firestoreService.users
        .where(FirestoreFields.guardianIds, arrayContains: uid)
        .snapshots()
        .map(_mapUserProfiles);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return RetryHelper.run<void>(
      label: 'save user profile',
      operation: () {
        return _firestoreService.users
            .doc(profile.id)
            .set(profile.toMap(), SetOptions(merge: true));
      },
      attempts: AppConstants.maxCriticalWriteAttempts,
    );
  }

  @override
  Future<void> ensureAccountScaffold({
    required String uid,
    required String name,
    required String email,
  }) {
    final DateTime now = DateTime.now();
    final UserSettings defaultSettings = UserSettings.defaults(uid);
    final MedicalProfile emptyProfile = MedicalProfile.empty(uid);

    return RetryHelper.run<void>(
      label: 'ensure account scaffold',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () async {
        await _firestoreService.runTransaction((Transaction transaction) async {
          final DocumentReference<Map<String, dynamic>> userRef =
              _firestoreService.users.doc(uid);
          final DocumentReference<Map<String, dynamic>> settingsRef =
              _firestoreService.settings.doc(uid);
          final DocumentReference<Map<String, dynamic>> medicalRef =
              _firestoreService.medicalProfiles.doc(uid);

          final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
              await transaction.get(userRef);
          final DocumentSnapshot<Map<String, dynamic>> settingsSnapshot =
              await transaction.get(settingsRef);
          final DocumentSnapshot<Map<String, dynamic>> medicalSnapshot =
              await transaction.get(medicalRef);
          final Map<String, dynamic> existingUser =
              userSnapshot.data() ?? const <String, dynamic>{};

          final String existingName =
              (existingUser[FirestoreFields.name] as String?)?.trim() ?? '';
          final String existingEmail =
              (existingUser[FirestoreFields.email] as String?)?.trim() ?? '';

          transaction.set(userRef, <String, Object?>{
            FirestoreFields.id: uid,
            FirestoreFields.name: existingName.isNotEmpty
                ? existingName
                : name.trim(),
            FirestoreFields.email: existingEmail.isNotEmpty
                ? existingEmail
                : email.trim(),
            FirestoreFields.guardianIds:
                existingUser[FirestoreFields.guardianIds] as List<dynamic>? ??
                const <String>[],
            FirestoreFields.safemateIds:
                existingUser[FirestoreFields.safemateIds] as List<dynamic>? ??
                const <String>[],
            FirestoreFields.createdAt:
                existingUser[FirestoreFields.createdAt] ??
                Timestamp.fromDate(now),
            FirestoreFields.updatedAt: Timestamp.fromDate(now),
            FirestoreFields.lastSeenAt:
                existingUser[FirestoreFields.lastSeenAt] ??
                Timestamp.fromDate(now),
            FirestoreFields.lastLocationSyncAt:
                existingUser[FirestoreFields.lastLocationSyncAt],
            FirestoreFields.isEmergencyActive:
                existingUser[FirestoreFields.isEmergencyActive] as bool? ??
                false,
            FirestoreFields.batteryLevel:
                existingUser[FirestoreFields.batteryLevel] as num?,
            FirestoreFields.fcmToken:
                existingUser[FirestoreFields.fcmToken] as String?,
            FirestoreFields.emergencyContactName:
                (existingUser[FirestoreFields.emergencyContactName] as String?)
                    ?.trim() ??
                '',
            FirestoreFields.emergencyContactPhone:
                (existingUser[FirestoreFields.emergencyContactPhone] as String?)
                    ?.trim() ??
                '',
          }, SetOptions(merge: true));

          if (!settingsSnapshot.exists) {
            transaction.set(settingsRef, defaultSettings.toMap());
          }

          if (!medicalSnapshot.exists) {
            transaction.set(medicalRef, emptyProfile.toMap());
          }
        });
      },
    );
  }

  @override
  Future<void> setRole({
    required String uid,
    required String name,
    required String email,
    required String roleValue,
  }) {
    final DateTime now = DateTime.now();
    return RetryHelper.run<void>(
      label: 'set role',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () async {
        await _firestoreService.runTransaction((Transaction transaction) async {
          final DocumentReference<Map<String, dynamic>> userRef =
              _firestoreService.users.doc(uid);
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(userRef);
          final Map<String, dynamic> existing =
              snapshot.data() ?? const <String, dynamic>{};

          transaction.set(userRef, <String, Object?>{
            FirestoreFields.id: uid,
            FirestoreFields.name: name.trim(),
            FirestoreFields.email: email.trim(),
            FirestoreFields.role: roleValue,
            FirestoreFields.guardianIds:
                existing[FirestoreFields.guardianIds] as List<dynamic>? ??
                const <String>[],
            FirestoreFields.safemateIds:
                existing[FirestoreFields.safemateIds] as List<dynamic>? ??
                const <String>[],
            FirestoreFields.createdAt:
                existing[FirestoreFields.createdAt] ?? Timestamp.fromDate(now),
            FirestoreFields.updatedAt: Timestamp.fromDate(now),
            FirestoreFields.lastSeenAt: Timestamp.fromDate(now),
            FirestoreFields.lastLocationSyncAt:
                existing[FirestoreFields.lastLocationSyncAt],
            FirestoreFields.isEmergencyActive:
                existing[FirestoreFields.isEmergencyActive] as bool? ?? false,
            FirestoreFields.batteryLevel:
                existing[FirestoreFields.batteryLevel] as num?,
            FirestoreFields.fcmToken:
                existing[FirestoreFields.fcmToken] as String?,
            FirestoreFields.emergencyContactName:
                (existing[FirestoreFields.emergencyContactName] as String?)
                    ?.trim() ??
                '',
            FirestoreFields.emergencyContactPhone:
                (existing[FirestoreFields.emergencyContactPhone] as String?)
                    ?.trim() ??
                '',
          }, SetOptions(merge: true));
        });
      },
    );
  }

  @override
  Future<void> updateFcmToken(String uid, String? token) {
    return RetryHelper.run<void>(
      label: 'update FCM token',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.users.doc(uid).set(<String, Object?>{
          FirestoreFields.fcmToken: token,
          FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  Future<void> updateBatteryLevel({
    required String uid,
    required int batteryLevel,
  }) {
    return RetryHelper.run<void>(
      label: 'update battery level',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.users.doc(uid).set(<String, Object?>{
          FirestoreFields.batteryLevel: batteryLevel,
          FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  Future<void> updateLastSeen(String uid) {
    return RetryHelper.run<void>(
      label: 'update last seen',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.users.doc(uid).set(<String, Object?>{
          FirestoreFields.lastSeenAt: Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  Future<void> updateLastLocationSync(String uid, DateTime timestamp) {
    return RetryHelper.run<void>(
      label: 'update last location sync',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.users.doc(uid).set(<String, Object?>{
          FirestoreFields.lastLocationSyncAt: Timestamp.fromDate(timestamp),
          FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  Future<void> setEmergencyState({
    required String uid,
    required bool isEmergencyActive,
  }) {
    return RetryHelper.run<void>(
      label: 'set emergency state',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.users.doc(uid).set(<String, Object?>{
          FirestoreFields.isEmergencyActive: isEmergencyActive,
          FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      },
    );
  }

  @override
  Future<void> linkGuardian({
    required String safemateId,
    required String guardianId,
  }) {
    if (safemateId == guardianId) {
      throw StateError('A Safemate cannot link themselves as a guardian.');
    }

    return RetryHelper.run<void>(
      label: 'link guardian',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () async {
        await _firestoreService.runTransaction((Transaction transaction) async {
          final DocumentReference<Map<String, dynamic>> safemateRef =
              _firestoreService.users.doc(safemateId);
          final DocumentReference<Map<String, dynamic>> guardianRef =
              _firestoreService.users.doc(guardianId);

          final DocumentSnapshot<Map<String, dynamic>> safemateSnapshot =
              await transaction.get(safemateRef);
          final DocumentSnapshot<Map<String, dynamic>> guardianSnapshot =
              await transaction.get(guardianRef);

          if (!safemateSnapshot.exists) {
            throw StateError('Your Safemate profile is not ready yet.');
          }
          if (!guardianSnapshot.exists) {
            throw StateError('Guardian ID was not found.');
          }
          if ((guardianSnapshot.data()?[FirestoreFields.role] as String?) !=
              'guardian') {
            throw StateError('That account is not registered as a guardian.');
          }

          final Timestamp now = Timestamp.fromDate(DateTime.now());
          transaction.update(safemateRef, <String, Object?>{
            FirestoreFields.guardianIds: FieldValue.arrayUnion(<String>[
              guardianId,
            ]),
            FirestoreFields.updatedAt: now,
          });
          transaction.update(guardianRef, <String, Object?>{
            FirestoreFields.safemateIds: FieldValue.arrayUnion(<String>[
              safemateId,
            ]),
            FirestoreFields.updatedAt: now,
          });
        });
      },
    );
  }

  @override
  Future<void> unlinkGuardian({
    required String safemateId,
    required String guardianId,
  }) {
    return RetryHelper.run<void>(
      label: 'unlink guardian',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () async {
        await _firestoreService.runTransaction((Transaction transaction) async {
          final DocumentReference<Map<String, dynamic>> safemateRef =
              _firestoreService.users.doc(safemateId);
          final DocumentReference<Map<String, dynamic>> guardianRef =
              _firestoreService.users.doc(guardianId);
          final Timestamp now = Timestamp.fromDate(DateTime.now());

          transaction.set(safemateRef, <String, Object?>{
            FirestoreFields.guardianIds: FieldValue.arrayRemove(<String>[
              guardianId,
            ]),
            FirestoreFields.updatedAt: now,
          }, SetOptions(merge: true));
          transaction.set(guardianRef, <String, Object?>{
            FirestoreFields.safemateIds: FieldValue.arrayRemove(<String>[
              safemateId,
            ]),
            FirestoreFields.updatedAt: now,
          }, SetOptions(merge: true));
        });
      },
    );
  }

  @override
  Stream<MedicalProfile?> watchMedicalProfile(String uid) {
    return _firestoreService.medicalProfiles.doc(uid).snapshots().map((
      snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return MedicalProfile.fromMap(data);
    });
  }

  @override
  Future<void> saveMedicalProfile(MedicalProfile profile) {
    return RetryHelper.run<void>(
      label: 'save medical profile',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.medicalProfiles
            .doc(profile.userId)
            .set(profile.toMap(), SetOptions(merge: true));
      },
    );
  }

  @override
  Stream<UserSettings?> watchSettings(String uid) {
    return _firestoreService.settings.doc(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return UserSettings.fromMap(data);
    });
  }

  @override
  Future<void> saveSettings(UserSettings settings) {
    return RetryHelper.run<void>(
      label: 'save settings',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.settings
            .doc(settings.userId)
            .set(settings.toMap(), SetOptions(merge: true));
      },
    );
  }

  @override
  Stream<GeofenceConfig?> watchGeofences(String uid) {
    return _firestoreService.geofences.doc(uid).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return GeofenceConfig.fromMap(data);
    });
  }

  @override
  Future<void> saveGeofenceConfig(GeofenceConfig config) {
    return RetryHelper.run<void>(
      label: 'save geofence config',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () {
        return _firestoreService.geofences
            .doc(config.userId)
            .set(config.toMap(), SetOptions(merge: true));
      },
    );
  }

  List<UserProfile> _mapUserProfiles(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<UserProfile> items = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return UserProfile.fromMap(doc.data(), documentId: doc.id);
        })
        .toList(growable: false);
    items.sort((UserProfile a, UserProfile b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }
}
