import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/services/firebase_messaging_service.dart';
import '../core/services/local_notifications_service.dart';
import '../core/services/notification_intent_service.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/retry_helper.dart';
import '../core/constants/app_constants.dart';
import '../models/user_settings.dart';
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
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _currentUserId;

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
      await _foregroundSubscription?.cancel();
      _foregroundSubscription = _messagingService.onMessage.listen((
        RemoteMessage message,
      ) async {
        try {
          final bool shouldShow = await _shouldShowForegroundMessage(message);
          if (!shouldShow) {
            AppLogger.info('Foreground notification suppressed by settings.');
            return;
          }
          await _localNotificationsService.showRemoteMessage(message);
        } catch (error, stackTrace) {
          AppLogger.error(
            'Foreground notification handling failed',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });
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
    _currentUserId = userId;
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

  Future<bool> _shouldShowForegroundMessage(RemoteMessage message) async {
    final String? userId = _currentUserId;
    if (userId == null || userId.isEmpty) {
      return true;
    }

    final String type = (message.data['type'] as String?)?.trim() ?? '';
    if (type.isEmpty) {
      return true;
    }

    try {
      final UserSettings? settings = await _profileRepository
          .watchSettings(userId)
          .first
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      final UserSettings effectiveSettings =
          settings ?? UserSettings.defaults(userId);
      return switch (type) {
        'sos' => effectiveSettings.sosNotificationsEnabled,
        'low_battery' => effectiveSettings.batteryNotificationsEnabled,
        'geofence' ||
        'route_deviation' => effectiveSettings.geofenceNotificationsEnabled,
        'missed_checkin' ||
        'manual_checkin' => effectiveSettings.checkInNotificationsEnabled,
        _ => true,
      };
    } catch (error, stackTrace) {
      AppLogger.error(
        'Could not read notification settings; showing notification by default',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }
  }
}
