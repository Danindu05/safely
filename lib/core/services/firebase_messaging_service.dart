import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  FirebaseMessagingService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> configure() async {
    await _messaging.setAutoInitEnabled(true);
  }

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission();
  }

  Future<String?> getToken() {
    return _messaging.getToken();
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp;
  }

  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
