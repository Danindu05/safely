import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/services/firebase_messaging_service.dart';
import '../core/services/local_notifications_service.dart';
import 'profile_repository.dart';

abstract class NotificationRepository {
  Future<void> initialize();

  Future<void> syncCurrentToken(String userId);

  Future<NotificationSettings> requestPushPermission();

  Stream<RemoteMessage> get foregroundMessages;
}

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({
    required FirebaseMessagingService messagingService,
    required LocalNotificationsService localNotificationsService,
    required ProfileRepository profileRepository,
  }) : _messagingService = messagingService,
       _localNotificationsService = localNotificationsService,
       _profileRepository = profileRepository;

  final FirebaseMessagingService _messagingService;
  final LocalNotificationsService _localNotificationsService;
  final ProfileRepository _profileRepository;
  StreamSubscription<String>? _tokenSubscription;

  @override
  Future<void> initialize() async {
    await _messagingService.configure();
    _messagingService.onMessage.listen(
      _localNotificationsService.showRemoteMessage,
    );
  }

  @override
  Future<void> syncCurrentToken(String userId) async {
    final String? token = await _messagingService.getToken();
    await _profileRepository.updateFcmToken(userId, token);

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messagingService.onTokenRefresh.listen((
      String token,
    ) {
      _profileRepository.updateFcmToken(userId, token);
    });
  }

  @override
  Future<NotificationSettings> requestPushPermission() {
    return _messagingService.requestPermission();
  }

  @override
  Stream<RemoteMessage> get foregroundMessages => _messagingService.onMessage;
}
