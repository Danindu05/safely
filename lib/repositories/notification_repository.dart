import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/services/firebase_messaging_service.dart';
import '../core/services/local_notifications_service.dart';
import '../core/services/notification_intent_service.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/retry_helper.dart';
import '../core/constants/app_constants.dart';
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
    required NotificationIntentService notificationIntentService,
    required ProfileRepository profileRepository,
  }) : _messagingService = messagingService,
       _localNotificationsService = localNotificationsService,
       _notificationIntentService = notificationIntentService,
       _profileRepository = profileRepository;

  final FirebaseMessagingService _messagingService;
  final LocalNotificationsService _localNotificationsService;
  final NotificationIntentService _notificationIntentService;
  final ProfileRepository _profileRepository;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  @override
  Future<void> initialize() async {
    try {
      await _messagingService.configure();
      await _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = _messagingService.onMessageOpenedApp.listen(
        _notificationIntentService.queueAlertFromRemoteMessage,
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.error(
            'Notification open stream failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      _messagingService.onMessage.listen(
        _localNotificationsService.showRemoteMessage,
      );
      final RemoteMessage? initialMessage = await _messagingService
          .getInitialMessage();
      if (initialMessage != null) {
        _notificationIntentService.queueAlertFromRemoteMessage(initialMessage);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Notification initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> syncCurrentToken(String userId) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messagingService.onTokenRefresh.listen(
      (String token) async {
        try {
          await RetryHelper.run<void>(
            label: 'sync refreshed FCM token',
            attempts: AppConstants.maxCriticalWriteAttempts,
            operation: () => _profileRepository.updateFcmToken(userId, token),
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'Token refresh sync failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Token refresh stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    final String? token = await RetryHelper.run<String?>(
      label: 'fetch current FCM token',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: _messagingService.getToken,
    );
    await RetryHelper.run<void>(
      label: 'sync current FCM token',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () => _profileRepository.updateFcmToken(userId, token),
    );
  }

  @override
  Future<NotificationSettings> requestPushPermission() {
    return _messagingService.requestPermission();
  }

  @override
  Stream<RemoteMessage> get foregroundMessages => _messagingService.onMessage;
}
