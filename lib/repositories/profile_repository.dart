import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../models/geofence_zone.dart';
import '../models/medical_profile.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchUserProfile(String uid);

  Stream<List<UserProfile>> watchLinkedGuardians(String uid);

  Stream<List<UserProfile>> watchLinkedSafemates(String uid);

  Future<void> saveUserProfile(UserProfile profile);

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
      return UserProfile.fromMap(data, documentId: snapshot.id);
    });
  }

  @override
  Stream<List<UserProfile>> watchLinkedGuardians(String uid) {
    return watchUserProfile(uid).asyncExpand((UserProfile? profile) {
      if (profile == null || profile.guardianIds.isEmpty) {
        return Stream<List<UserProfile>>.value(const <UserProfile>[]);
      }

      return _firestoreService.users
          .where(
            FieldPath.documentId,
            whereIn: profile.guardianIds.take(10).toList(),
          )
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => UserProfile.fromMap(doc.data(), documentId: doc.id),
                )
                .toList(growable: false);
          });
    });
  }

  @override
  Stream<List<UserProfile>> watchLinkedSafemates(String uid) {
    return watchUserProfile(uid).asyncExpand((UserProfile? profile) {
      if (profile == null || profile.safemateIds.isEmpty) {
        return Stream<List<UserProfile>>.value(const <UserProfile>[]);
      }

      return _firestoreService.users
          .where(
            FieldPath.documentId,
            whereIn: profile.safemateIds.take(10).toList(),
          )
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => UserProfile.fromMap(doc.data(), documentId: doc.id),
                )
                .toList(growable: false);
          });
    });
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _firestoreService.users
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> setRole({
    required String uid,
    required String name,
    required String email,
    required String roleValue,
  }) {
    final DateTime now = DateTime.now();
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.id: uid,
      FirestoreFields.name: name.trim(),
      FirestoreFields.email: email.trim(),
      FirestoreFields.role: roleValue,
      FirestoreFields.guardianIds: const <String>[],
      FirestoreFields.safemateIds: const <String>[],
      FirestoreFields.createdAt: Timestamp.fromDate(now),
      FirestoreFields.updatedAt: Timestamp.fromDate(now),
      FirestoreFields.lastSeenAt: Timestamp.fromDate(now),
      FirestoreFields.lastLocationSyncAt: null,
      FirestoreFields.isEmergencyActive: false,
      FirestoreFields.batteryLevel: null,
      FirestoreFields.fcmToken: null,
      FirestoreFields.emergencyContactName: '',
      FirestoreFields.emergencyContactPhone: '',
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateFcmToken(String uid, String? token) {
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.fcmToken: token,
      FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateBatteryLevel({
    required String uid,
    required int batteryLevel,
  }) {
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.batteryLevel: batteryLevel,
      FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateLastSeen(String uid) {
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.lastSeenAt: Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateLastLocationSync(String uid, DateTime timestamp) {
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.lastLocationSyncAt: Timestamp.fromDate(timestamp),
      FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setEmergencyState({
    required String uid,
    required bool isEmergencyActive,
  }) {
    return _firestoreService.users.doc(uid).set(<String, Object?>{
      FirestoreFields.isEmergencyActive: isEmergencyActive,
      FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> linkGuardian({
    required String safemateId,
    required String guardianId,
  }) {
    if (safemateId == guardianId) {
      throw StateError('A Safemate cannot link themselves as a guardian.');
    }

    return _firestoreService.runTransaction((Transaction transaction) async {
      final DocumentReference<Map<String, dynamic>> safemateRef =
          _firestoreService.users.doc(safemateId);
      final DocumentReference<Map<String, dynamic>> guardianRef =
          _firestoreService.users.doc(guardianId);

      final DocumentSnapshot<Map<String, dynamic>> safemateSnapshot =
          await transaction.get(safemateRef);
      final DocumentSnapshot<Map<String, dynamic>> guardianSnapshot =
          await transaction.get(guardianRef);

      if (!guardianSnapshot.exists) {
        throw StateError('Guardian ID was not found.');
      }
      if ((guardianSnapshot.data()?[FirestoreFields.role] as String?) !=
          'guardian') {
        throw StateError('That account is not registered as a guardian.');
      }

      final List<String> guardianIds =
          (safemateSnapshot.data()?[FirestoreFields.guardianIds]
                      as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toSet()
              .toList();
      final List<String> safemateIds =
          (guardianSnapshot.data()?[FirestoreFields.safemateIds]
                      as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toSet()
              .toList();

      guardianIds.add(guardianId);
      safemateIds.add(safemateId);

      transaction.set(safemateRef, <String, Object?>{
        FirestoreFields.guardianIds: guardianIds,
        FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      transaction.set(guardianRef, <String, Object?>{
        FirestoreFields.safemateIds: safemateIds,
        FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> unlinkGuardian({
    required String safemateId,
    required String guardianId,
  }) {
    return _firestoreService.runTransaction((Transaction transaction) async {
      final DocumentReference<Map<String, dynamic>> safemateRef =
          _firestoreService.users.doc(safemateId);
      final DocumentReference<Map<String, dynamic>> guardianRef =
          _firestoreService.users.doc(guardianId);

      final DocumentSnapshot<Map<String, dynamic>> safemateSnapshot =
          await transaction.get(safemateRef);
      final DocumentSnapshot<Map<String, dynamic>> guardianSnapshot =
          await transaction.get(guardianRef);

      final List<String> guardianIds =
          (safemateSnapshot.data()?[FirestoreFields.guardianIds]
                      as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList();
      final List<String> safemateIds =
          (guardianSnapshot.data()?[FirestoreFields.safemateIds]
                      as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList();

      guardianIds.remove(guardianId);
      safemateIds.remove(safemateId);

      transaction.set(safemateRef, <String, Object?>{
        FirestoreFields.guardianIds: guardianIds,
        FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      transaction.set(guardianRef, <String, Object?>{
        FirestoreFields.safemateIds: safemateIds,
        FirestoreFields.updatedAt: Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
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
    return _firestoreService.medicalProfiles
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
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
    return _firestoreService.settings
        .doc(settings.userId)
        .set(settings.toMap(), SetOptions(merge: true));
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
    return _firestoreService.geofences
        .doc(config.userId)
        .set(config.toMap(), SetOptions(merge: true));
  }
}
