import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/app_logger.dart';

class NotificationIntentService extends ChangeNotifier {
  String? _pendingAlertId;

  String? get pendingAlertId => _pendingAlertId;

  void queueAlertFromRemoteMessage(RemoteMessage message) {
    queueAlertId(message.data['alertId']);
  }

  void queueAlertFromPayload(String? payload) {
    queueAlertId(payload);
  }

  void queueAlertId(String? alertId) {
    final String trimmed = (alertId ?? '').trim();
    if (trimmed.isEmpty) {
      AppLogger.warning('Notification tap received without an alertId.');
      return;
    }

    _pendingAlertId = trimmed;
    notifyListeners();
  }

  String? takePendingAlertId() {
    final String? alertId = _pendingAlertId;
    _pendingAlertId = null;
    return alertId;
  }
}
