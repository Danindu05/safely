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
  Future<void>? _initializationFuture;

  @override
  Future<void> initialize() async {
    final Future<void>? existingInitialization = _initializationFuture;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    _initializationFuture = _initializeInternal();
    return _initializationFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      await _localNotificationsService.initialize();
      await _messagingService.configure();
      await requestPushPermission();

      await _messageOpenedSubscription?.cancel();
      _messageOpenedSubscription = _messagingService.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          AppLogger.info(
            'Notification tap opened app for alert '
            '${(message.data['alertId'] as String?)?.trim() ?? 'unknown'}.',
          );
          _notificationIntentService.queueAlertFromRemoteMessage(message);
        },
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
          AppLogger.info(
            'Foreground FCM received. '
            'messageId=${message.messageId ?? 'unknown'} '
            'alertId=${(message.data['alertId'] as String?)?.trim() ?? 'unknown'} '
            'type=${(message.data['type'] as String?)?.trim() ?? 'unknown'}',
          );
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
        AppLogger.info(
          'App launched from terminated notification for alert '
          '${(initialMessage.data['alertId'] as String?)?.trim() ?? 'unknown'}.',
        );
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
    await initialize();
    _currentUserId = userId;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messagingService.onTokenRefresh.listen(
      (String token) async {
        final String trimmedToken = token.trim();
        AppLogger.info('FCM token refreshed for user $userId: $trimmedToken');
        if (trimmedToken.isEmpty) {
          AppLogger.warning(
            'Ignoring empty refreshed FCM token for user $userId.',
          );
          return;
        }

        try {
          await RetryHelper.run<void>(
            label: 'sync refreshed FCM token',
            attempts: AppConstants.maxCriticalWriteAttempts,
            operation: () =>
                _profileRepository.updateFcmToken(userId, trimmedToken),
          );
          AppLogger.info('Refreshed FCM token synced for user $userId.');
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

    final NotificationSettings settings = await _messagingService
        .getNotificationSettings();
    _logPermissionSettings(settings, prefix: 'Current notification permission');

    await _fetchAndPersistCurrentToken(userId);
  }

  @override
  Future<NotificationSettings> requestPushPermission() async {
    final NotificationSettings settings = await _messagingService
        .requestPermission();
    _logPermissionSettings(settings);

    final String? userId = _currentUserId;
    final bool canSyncToken =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (canSyncToken && userId != null && userId.isNotEmpty) {
      try {
        await _fetchAndPersistCurrentToken(userId);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to sync FCM token after permission grant',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return settings;
  }

  Future<void> _fetchAndPersistCurrentToken(String userId) async {
    final String? token = await RetryHelper.run<String?>(
      label: 'fetch current FCM token',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: _messagingService.getToken,
    );
    final String trimmedToken = (token ?? '').trim();
    if (trimmedToken.isEmpty) {
      AppLogger.warning(
        'Current FCM token was empty for user $userId. Skipping Firestore update.',
      );
      return;
    }
    AppLogger.info('Current FCM token for user $userId: $trimmedToken');

    await RetryHelper.run<void>(
      label: 'sync current FCM token',
      attempts: AppConstants.maxCriticalWriteAttempts,
      operation: () => _profileRepository.updateFcmToken(userId, trimmedToken),
    );
    AppLogger.info('Current FCM token synced for user $userId.');
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

  void _logPermissionSettings(
    NotificationSettings settings, {
    String prefix = 'Notification permission result',
  }) {
    AppLogger.info(
      '$prefix: '
      'authorization=${settings.authorizationStatus.name}, '
      'alert=${settings.alert.name}, '
      'badge=${settings.badge.name}, '
      'sound=${settings.sound.name}',
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.warning(
        'Notification permission is denied. Remote notifications will not be visible.',
      );
    }
  }
}
