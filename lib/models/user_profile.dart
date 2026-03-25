import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'app_enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.guardianIds,
    required this.safemateIds,
    required this.createdAt,
    required this.updatedAt,
    required this.fcmToken,
    required this.batteryLevel,
    required this.lastSeenAt,
    required this.lastLocationSyncAt,
    required this.isEmergencyActive,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> guardianIds;
  final List<String> safemateIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  final int? batteryLevel;
  final DateTime? lastSeenAt;
  final DateTime? lastLocationSyncAt;
  final bool isEmergencyActive;
  final String emergencyContactName;
  final String emergencyContactPhone;

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final UserRole? role = userRoleFromValue(
      map[FirestoreFields.role] as String?,
    );

    if (role == null) {
      throw const FormatException('User role is missing or invalid.');
    }

    return UserProfile(
      id: (map[FirestoreFields.id] as String?) ?? documentId,
      name: (map[FirestoreFields.name] as String?)?.trim() ?? '',
      email: (map[FirestoreFields.email] as String?)?.trim() ?? '',
      role: role,
      guardianIds:
          (map[FirestoreFields.guardianIds] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      safemateIds:
          (map[FirestoreFields.safemateIds] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      createdAt:
          _timestampToDate(map[FirestoreFields.createdAt]) ?? DateTime.now(),
      updatedAt:
          _timestampToDate(map[FirestoreFields.updatedAt]) ?? DateTime.now(),
      fcmToken: map[FirestoreFields.fcmToken] as String?,
      batteryLevel: (map[FirestoreFields.batteryLevel] as num?)?.toInt(),
      lastSeenAt: _timestampToDate(map[FirestoreFields.lastSeenAt]),
      lastLocationSyncAt: _timestampToDate(
        map[FirestoreFields.lastLocationSyncAt],
      ),
      isEmergencyActive:
          map[FirestoreFields.isEmergencyActive] as bool? ?? false,
      emergencyContactName:
          (map[FirestoreFields.emergencyContactName] as String?)?.trim() ?? '',
      emergencyContactPhone:
          (map[FirestoreFields.emergencyContactPhone] as String?)?.trim() ?? '',
    );
  }

  factory UserProfile.create({
    required String id,
    required String name,
    required String email,
    required UserRole role,
  }) {
    final DateTime now = DateTime.now();
    return UserProfile(
      id: id,
      name: name.trim(),
      email: email.trim(),
      role: role,
      guardianIds: const <String>[],
      safemateIds: const <String>[],
      createdAt: now,
      updatedAt: now,
      fcmToken: null,
      batteryLevel: null,
      lastSeenAt: now,
      lastLocationSyncAt: null,
      isEmergencyActive: false,
      emergencyContactName: '',
      emergencyContactPhone: '',
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.id: id,
      FirestoreFields.name: name,
      FirestoreFields.email: email,
      FirestoreFields.role: role.value,
      FirestoreFields.guardianIds: guardianIds,
      FirestoreFields.safemateIds: safemateIds,
      FirestoreFields.createdAt: Timestamp.fromDate(createdAt),
      FirestoreFields.updatedAt: Timestamp.fromDate(updatedAt),
      FirestoreFields.fcmToken: fcmToken,
      FirestoreFields.batteryLevel: batteryLevel,
      FirestoreFields.lastSeenAt: lastSeenAt == null
          ? null
          : Timestamp.fromDate(lastSeenAt!),
      FirestoreFields.lastLocationSyncAt: lastLocationSyncAt == null
          ? null
          : Timestamp.fromDate(lastLocationSyncAt!),
      FirestoreFields.isEmergencyActive: isEmergencyActive,
      FirestoreFields.emergencyContactName: emergencyContactName,
      FirestoreFields.emergencyContactPhone: emergencyContactPhone,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    UserRole? role,
    List<String>? guardianIds,
    List<String>? safemateIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    int? batteryLevel,
    DateTime? lastSeenAt,
    DateTime? lastLocationSyncAt,
    bool? isEmergencyActive,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      guardianIds: guardianIds ?? this.guardianIds,
      safemateIds: safemateIds ?? this.safemateIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastLocationSyncAt: lastLocationSyncAt ?? this.lastLocationSyncAt,
      isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }

  static DateTime? _timestampToDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
