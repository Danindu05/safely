import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationsService {
  LocalNotificationsService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel emergencyChannel =
      AndroidNotificationChannel(
        'safely_emergency',
        'Emergency Alerts',
        description: 'Critical safety alerts for Safely.',
        importance: Importance.max,
      );

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(emergencyChannel);
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) {
      return;
    }

    await _plugin.show(
      id: notification.hashCode,
      title: notification.title ?? 'Safely',
      body: notification.body ?? 'New update',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'safely_emergency',
          'Emergency Alerts',
          channelDescription: emergencyChannel.description,
          importance: Importance.max,
          priority: Priority.high,
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
          'safely_emergency',
          'Emergency Alerts',
          channelDescription: emergencyChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
