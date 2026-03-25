import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'app_enums.dart';

class SafetyCheckIn {
  const SafetyCheckIn({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.batteryLevel,
    required this.locationLat,
    required this.locationLng,
    required this.status,
  });

  final String id;
  final String userId;
  final CheckInType type;
  final DateTime timestamp;
  final int? batteryLevel;
  final double? locationLat;
  final double? locationLng;
  final CheckInStatus status;

  factory SafetyCheckIn.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final CheckInType? type = checkInTypeFromValue(
      map[FirestoreFields.type] as String?,
    );
    final CheckInStatus? status = checkInStatusFromValue(
      map[FirestoreFields.status] as String?,
    );

    if (type == null || status == null) {
      throw const FormatException('Check-in type or status is invalid.');
    }

    return SafetyCheckIn(
      id: (map[FirestoreFields.id] as String?) ?? documentId,
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      type: type,
      timestamp:
          (map[FirestoreFields.timestamp] as Timestamp?)?.toDate() ??
          DateTime.now(),
      batteryLevel: (map[FirestoreFields.batteryLevel] as num?)?.toInt(),
      locationLat: (map[FirestoreFields.locationLat] as num?)?.toDouble(),
      locationLng: (map[FirestoreFields.locationLng] as num?)?.toDouble(),
      status: status,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.id: id,
      FirestoreFields.userId: userId,
      FirestoreFields.type: type.value,
      FirestoreFields.timestamp: Timestamp.fromDate(timestamp),
      FirestoreFields.batteryLevel: batteryLevel,
      FirestoreFields.locationLat: locationLat,
      FirestoreFields.locationLng: locationLng,
      FirestoreFields.status: status.value,
    };
  }
}
