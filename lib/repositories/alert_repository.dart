import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/firestore_service.dart';
import '../models/activity_log.dart';
import '../models/safety_alert.dart';
import '../models/safety_checkin.dart';

abstract class AlertRepository {
  Stream<List<SafetyAlert>> watchAlertsForUser(String userId);

  Stream<List<SafetyAlert>> watchAlertsForGuardian(String guardianId);

  Stream<SafetyAlert?> watchAlert(String alertId);

  Future<SafetyAlert> createAlert(SafetyAlert alert);

  Future<void> updateAlert(SafetyAlert alert);

  Stream<List<SafetyCheckIn>> watchCheckIns(String userId);

  Future<void> createCheckIn(SafetyCheckIn checkIn);

  Stream<List<ActivityLog>> watchLogs(String userId);

  Future<void> createLog(ActivityLog log);
}

class FirebaseAlertRepository implements AlertRepository {
  FirebaseAlertRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<List<SafetyAlert>> watchAlertsForUser(String userId) {
    return _firestoreService.alerts
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapAlerts);
  }

  @override
  Stream<List<SafetyAlert>> watchAlertsForGuardian(String guardianId) {
    return _firestoreService.alerts
        .where('guardianIds', arrayContains: guardianId)
        .snapshots()
        .map(_mapAlerts);
  }

  @override
  Stream<SafetyAlert?> watchAlert(String alertId) {
    return _firestoreService.alerts.doc(alertId).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return SafetyAlert.fromMap(data, documentId: snapshot.id);
    });
  }

  @override
  Future<SafetyAlert> createAlert(SafetyAlert alert) async {
    await _firestoreService.alerts.doc(alert.id).set(alert.toMap());
    return alert;
  }

  @override
  Future<void> updateAlert(SafetyAlert alert) {
    return _firestoreService.alerts
        .doc(alert.id)
        .set(alert.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<List<SafetyCheckIn>> watchCheckIns(String userId) {
    return _firestoreService.checkins
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final List<SafetyCheckIn> items = snapshot.docs
              .map(
                (doc) => SafetyCheckIn.fromMap(doc.data(), documentId: doc.id),
              )
              .toList(growable: false);
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  @override
  Future<void> createCheckIn(SafetyCheckIn checkIn) {
    return _firestoreService.checkins.doc(checkIn.id).set(checkIn.toMap());
  }

  @override
  Stream<List<ActivityLog>> watchLogs(String userId) {
    return _firestoreService.logs
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final List<ActivityLog> items = snapshot.docs
              .map((doc) => ActivityLog.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false);
          items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return items;
        });
  }

  @override
  Future<void> createLog(ActivityLog log) {
    return _firestoreService.logs.doc(log.id).set(log.toMap());
  }

  List<SafetyAlert> _mapAlerts(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<SafetyAlert> alerts = snapshot.docs
        .map((doc) => SafetyAlert.fromMap(doc.data(), documentId: doc.id))
        .toList(growable: false);
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }
}
