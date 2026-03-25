import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'app_enums.dart';

class SafetyAlert {
  const SafetyAlert({
    required this.id,
    required this.userId,
    required this.guardianIds,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.locationLat,
    required this.locationLng,
    required this.batteryLevel,
    required this.audioUrl,
    required this.acknowledgedBy,
    required this.acknowledgedAt,
    required this.canceledByUser,
    required this.resolvedAt,
  });

  final String id;
  final String userId;
  final List<String> guardianIds;
  final AlertType type;
  final AlertStatus status;
  final String title;
  final String description;
  final DateTime timestamp;
  final double? locationLat;
  final double? locationLng;
  final int? batteryLevel;
  final String? audioUrl;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final bool canceledByUser;
  final DateTime? resolvedAt;

  factory SafetyAlert.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final AlertType? type = alertTypeFromValue(
      map[FirestoreFields.type] as String?,
    );
    final AlertStatus? status = alertStatusFromValue(
      map[FirestoreFields.status] as String?,
    );

    if (type == null || status == null) {
      throw const FormatException('Alert type or status is invalid.');
    }

    return SafetyAlert(
      id: (map[FirestoreFields.id] as String?) ?? documentId,
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      guardianIds:
          (map[FirestoreFields.guardianIds] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
      type: type,
      status: status,
      title: (map[FirestoreFields.title] as String?)?.trim() ?? '',
      description: (map[FirestoreFields.description] as String?)?.trim() ?? '',
      timestamp:
          (map[FirestoreFields.timestamp] as Timestamp?)?.toDate() ??
          DateTime.now(),
      locationLat: (map[FirestoreFields.locationLat] as num?)?.toDouble(),
      locationLng: (map[FirestoreFields.locationLng] as num?)?.toDouble(),
      batteryLevel: (map[FirestoreFields.batteryLevel] as num?)?.toInt(),
      audioUrl: map[FirestoreFields.audioUrl] as String?,
      acknowledgedBy: map[FirestoreFields.acknowledgedBy] as String?,
      acknowledgedAt: (map[FirestoreFields.acknowledgedAt] as Timestamp?)
          ?.toDate(),
      canceledByUser: map[FirestoreFields.canceledByUser] as bool? ?? false,
      resolvedAt: (map[FirestoreFields.resolvedAt] as Timestamp?)?.toDate(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.id: id,
      FirestoreFields.userId: userId,
      FirestoreFields.guardianIds: guardianIds,
      FirestoreFields.type: type.value,
      FirestoreFields.status: status.value,
      FirestoreFields.title: title,
      FirestoreFields.description: description,
      FirestoreFields.timestamp: Timestamp.fromDate(timestamp),
      FirestoreFields.locationLat: locationLat,
      FirestoreFields.locationLng: locationLng,
      FirestoreFields.batteryLevel: batteryLevel,
      FirestoreFields.audioUrl: audioUrl,
      FirestoreFields.acknowledgedBy: acknowledgedBy,
      FirestoreFields.acknowledgedAt: acknowledgedAt == null
          ? null
          : Timestamp.fromDate(acknowledgedAt!),
      FirestoreFields.canceledByUser: canceledByUser,
      FirestoreFields.resolvedAt: resolvedAt == null
          ? null
          : Timestamp.fromDate(resolvedAt!),
    };
  }

  SafetyAlert copyWith({
    List<String>? guardianIds,
    AlertType? type,
    AlertStatus? status,
    String? title,
    String? description,
    DateTime? timestamp,
    double? locationLat,
    double? locationLng,
    int? batteryLevel,
    String? audioUrl,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    bool? canceledByUser,
    DateTime? resolvedAt,
  }) {
    return SafetyAlert(
      id: id,
      userId: userId,
      guardianIds: guardianIds ?? this.guardianIds,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      audioUrl: audioUrl ?? this.audioUrl,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      canceledByUser: canceledByUser ?? this.canceledByUser,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
