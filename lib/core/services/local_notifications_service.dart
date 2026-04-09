import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../constants/app_constants.dart';
import 'notification_intent_service.dart';

class LocalNotificationsService {
  LocalNotificationsService(this._notificationIntentService);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationIntentService _notificationIntentService;

  static const AndroidNotificationChannel alertsChannel =
      AndroidNotificationChannel(
        AppConstants.alertsNotificationChannelId,
        AppConstants.alertsNotificationChannelName,
        description: AppConstants.alertsNotificationChannelDescription,
        importance: Importance.max,
      );

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _notificationIntentService.queueAlertFromPayload(response.payload);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alertsChannel);
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final String title =
        notification?.title ??
        ((message.data['title'] as String?)?.trim().isNotEmpty ?? false
            ? (message.data['title'] as String).trim()
            : 'Safely');
    final String body =
        notification?.body ??
        ((message.data['description'] as String?)?.trim().isNotEmpty ?? false
            ? (message.data['description'] as String).trim()
            : 'New alert received');

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    await _plugin.show(
      id:
          (message.data['alertId'] ??
                  message.messageId ??
                  notification.hashCode)
              .hashCode,
      title: title,
      body: body,
      payload: (message.data['alertId'] as String?)?.trim(),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alertsNotificationChannelId,
          AppConstants.alertsNotificationChannelName,
          channelDescription: alertsChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          groupKey: 'safely_guardian_alerts',
        ),
      ),
    );
  }

  Future<void> showLocalWarning({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alertsNotificationChannelId,
          AppConstants.alertsNotificationChannelName,
          channelDescription: alertsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
