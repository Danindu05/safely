import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import 'app_enums.dart';

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.message,
    required this.timestamp,
    required this.metadata,
  });

  final String id;
  final String userId;
  final LogEventType eventType;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  factory ActivityLog.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final LogEventType? eventType = logEventTypeFromValue(
      map[FirestoreFields.eventType] as String?,
    );
    if (eventType == null) {
      throw const FormatException('Log event type is invalid.');
    }

    return ActivityLog(
      id: (map[FirestoreFields.id] as String?) ?? documentId,
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      eventType: eventType,
      message: (map[FirestoreFields.message] as String?)?.trim() ?? '',
      timestamp:
          (map[FirestoreFields.timestamp] as Timestamp?)?.toDate() ??
          DateTime.now(),
      metadata:
          (map[FirestoreFields.metadata] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.id: id,
      FirestoreFields.userId: userId,
      FirestoreFields.eventType: eventType.value,
      FirestoreFields.message: message,
      FirestoreFields.timestamp: Timestamp.fromDate(timestamp),
      FirestoreFields.metadata: metadata,
    };
  }
}
