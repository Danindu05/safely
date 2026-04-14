import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

enum EmergencyEventType {
  fallDetected,
  abnormalMovement,
  suddenStop,
  phoneDrop,
}

extension EmergencyEventTypeX on EmergencyEventType {
  String get value => switch (this) {
    EmergencyEventType.fallDetected => 'fall_detected',
    EmergencyEventType.abnormalMovement => 'abnormal_movement',
    EmergencyEventType.suddenStop => 'sudden_stop_after_motion',
    EmergencyEventType.phoneDrop => 'phone_drop',
  };

  String get label => switch (this) {
    EmergencyEventType.fallDetected => 'Possible fall detected',
    EmergencyEventType.abnormalMovement => 'Unusual movement detected',
    EmergencyEventType.suddenStop => 'Sudden stop detected',
    EmergencyEventType.phoneDrop => 'Possible phone drop detected',
  };

  String get sosReason => switch (this) {
    EmergencyEventType.fallDetected => 'fall_detected',
    EmergencyEventType.abnormalMovement => 'abnormal_movement',
    EmergencyEventType.suddenStop => 'abnormal_movement',
    EmergencyEventType.phoneDrop => 'fall_detected',
  };
}

class EmergencyEvent {
  const EmergencyEvent({
    required this.type,
    required this.confidenceLevel,
    required this.detectedAt,
    required this.details,
  });

  final EmergencyEventType type;
  final double confidenceLevel;
  final DateTime detectedAt;
  final Map<String, Object?> details;
}

class EmergencyDetectionConfig {
  const EmergencyDetectionConfig({
    required this.enabled,
    required this.fallDetectionEnabled,
    required this.movementDetectionEnabled,
  });

  final bool enabled;
  final bool fallDetectionEnabled;
  final bool movementDetectionEnabled;

  bool get shouldRun {
    return enabled && (fallDetectionEnabled || movementDetectionEnabled);
  }
}

class EmergencyDetectionService {
  EmergencyDetectionService();

  static const double _gravity = 9.80665;
  static const double _impactThreshold = _gravity * 2.5;
  static const double _dropImpactThreshold = _gravity * 3.0;
  static const double _stillAccelerationDelta = 1.2;
  static const double _stillGyroscopeMagnitude = 0.45;
  static const double _highMotionDelta = 8.0;
  static const double _highRotationMagnitude = 3.2;
  static const Duration _stillnessAfterImpactWindow = Duration(seconds: 3);
  static const Duration _eventWindow = Duration(seconds: 4);
  static const Duration _minimumStillnessForFall = Duration(milliseconds: 1800);
  static const Duration _minimumStillnessForStop = Duration(milliseconds: 1400);

  final StreamController<EmergencyEvent> _eventController =
      StreamController<EmergencyEvent>.broadcast();
  final Queue<_MotionSample> _recentSamples = Queue<_MotionSample>();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  EmergencyDetectionConfig _config = const EmergencyDetectionConfig(
    enabled: false,
    fallDetectionEnabled: false,
    movementDetectionEnabled: false,
  );

  DateTime? _lastImpactAt;
  double _lastImpactMagnitude = 0;
  double _lastImpactRotation = 0;
  DateTime? _stillnessStartedAt;
  DateTime? _lastHighMotionAt;
  DateTime? _lastEmittedAt;
  double _latestGyroscopeMagnitude = 0;
  bool _running = false;

  Stream<EmergencyEvent> get events => _eventController.stream;

  bool get isRunning => _running;

  Future<void> start(EmergencyDetectionConfig config) async {
    _config = config;
    if (!config.shouldRun) {
      await stop();
      return;
    }

    if (_running) {
      return;
    }

    try {
      _accelerometerSubscription =
          accelerometerEventStream(
            samplingPeriod: SensorInterval.uiInterval,
          ).listen(
            _handleAccelerometerEvent,
            onError: (Object error, StackTrace stackTrace) {
              AppLogger.error(
                'Accelerometer stream failed; emergency detection disabled',
                error: error,
                stackTrace: stackTrace,
              );
              unawaited(stop());
            },
            cancelOnError: false,
          );
      _gyroscopeSubscription =
          gyroscopeEventStream(
            samplingPeriod: SensorInterval.uiInterval,
          ).listen(
            _handleGyroscopeEvent,
            onError: (Object error, StackTrace stackTrace) {
              AppLogger.error(
                'Gyroscope stream failed; emergency detection will use acceleration only',
                error: error,
                stackTrace: stackTrace,
              );
            },
            cancelOnError: false,
          );
      _running = true;
      AppLogger.info('Emergency detection service started.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Emergency detection service could not start',
        error: error,
        stackTrace: stackTrace,
      );
      await stop();
    }
  }

  Future<void> updateConfig(EmergencyDetectionConfig config) async {
    _config = config;
    if (!config.shouldRun) {
      await stop();
      return;
    }
    if (!_running) {
      await start(config);
    }
  }

  Future<void> stop() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _recentSamples.clear();
    _lastImpactAt = null;
    _stillnessStartedAt = null;
    _lastHighMotionAt = null;
    _running = false;
  }

  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    _latestGyroscopeMagnitude = _magnitude(event.x, event.y, event.z);
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_config.shouldRun) {
      return;
    }

    final DateTime now = DateTime.now();
    final double magnitude = _magnitude(event.x, event.y, event.z);
    final double movementDelta = (magnitude - _gravity).abs();
    final double rotationMagnitude = _latestGyroscopeMagnitude;
    final bool isStill =
        movementDelta <= _stillAccelerationDelta &&
        rotationMagnitude <= _stillGyroscopeMagnitude;

    final _MotionSample sample = _MotionSample(
      timestamp: now,
      accelerationMagnitude: magnitude,
      movementDelta: movementDelta,
      gyroscopeMagnitude: rotationMagnitude,
      isStill: isStill,
    );
    _recentSamples.add(sample);
    _trimSamples(now);

    if (isStill) {
      _stillnessStartedAt ??= now;
    } else {
      _stillnessStartedAt = null;
    }

    if (movementDelta >= _highMotionDelta) {
      _lastHighMotionAt = now;
    }

    if (_config.fallDetectionEnabled && magnitude >= _impactThreshold) {
      _lastImpactAt = now;
      _lastImpactMagnitude = magnitude;
      _lastImpactRotation = rotationMagnitude;
    }

    _evaluateFallOrDrop(now, sample);
    _evaluateAbnormalMovement(now);
    _evaluateSuddenStop(now);
  }

  void _evaluateFallOrDrop(DateTime now, _MotionSample sample) {
    if (!_config.fallDetectionEnabled || _lastImpactAt == null) {
      return;
    }

    final DateTime impactAt = _lastImpactAt!;
    final Duration sinceImpact = now.difference(impactAt);
    if (sinceImpact > _stillnessAfterImpactWindow) {
      _lastImpactAt = null;
      return;
    }

    final DateTime? stillnessStartedAt = _stillnessStartedAt;
    if (stillnessStartedAt == null ||
        now.difference(stillnessStartedAt) < _minimumStillnessForFall ||
        now.isBefore(impactAt)) {
      return;
    }

    final bool likelyPhoneDrop =
        _lastImpactMagnitude >= _dropImpactThreshold &&
        _lastImpactRotation >= _highRotationMagnitude;
    _emit(
      EmergencyEvent(
        type: likelyPhoneDrop
            ? EmergencyEventType.phoneDrop
            : EmergencyEventType.fallDetected,
        confidenceLevel: likelyPhoneDrop ? 0.72 : 0.82,
        detectedAt: now,
        details: <String, Object?>{
          'impactMagnitude': _lastImpactMagnitude,
          'impactRotation': _lastImpactRotation,
          'stillnessSeconds': now.difference(stillnessStartedAt).inSeconds,
          'currentMovementDelta': sample.movementDelta,
        },
      ),
    );
    _lastImpactAt = null;
  }

  void _evaluateAbnormalMovement(DateTime now) {
    if (!_config.movementDetectionEnabled || _recentSamples.length < 12) {
      return;
    }

    final int highMotionSamples = _recentSamples
        .where(
          (_MotionSample sample) => sample.movementDelta >= _highMotionDelta,
        )
        .length;
    final int highRotationSamples = _recentSamples
        .where(
          (_MotionSample sample) =>
              sample.gyroscopeMagnitude >= _highRotationMagnitude,
        )
        .length;
    final int directionChanges = _directionChangeCount();

    if (highMotionSamples < 8 ||
        highRotationSamples < 5 ||
        directionChanges < 4) {
      return;
    }

    _emit(
      EmergencyEvent(
        type: EmergencyEventType.abnormalMovement,
        confidenceLevel: 0.7,
        detectedAt: now,
        details: <String, Object?>{
          'highMotionSamples': highMotionSamples,
          'highRotationSamples': highRotationSamples,
          'directionChanges': directionChanges,
        },
      ),
    );
  }

  void _evaluateSuddenStop(DateTime now) {
    if (!_config.movementDetectionEnabled) {
      return;
    }

    final DateTime? lastHighMotionAt = _lastHighMotionAt;
    final DateTime? stillnessStartedAt = _stillnessStartedAt;
    if (lastHighMotionAt == null || stillnessStartedAt == null) {
      return;
    }

    if (stillnessStartedAt.isBefore(lastHighMotionAt) ||
        now.difference(stillnessStartedAt) < _minimumStillnessForStop ||
        now.difference(lastHighMotionAt) > const Duration(seconds: 4)) {
      return;
    }

    _emit(
      EmergencyEvent(
        type: EmergencyEventType.suddenStop,
        confidenceLevel: 0.66,
        detectedAt: now,
        details: <String, Object?>{
          'lastHighMotionAt': lastHighMotionAt.toIso8601String(),
          'stillnessSeconds': now.difference(stillnessStartedAt).inSeconds,
        },
      ),
    );
    _lastHighMotionAt = null;
  }

  void _emit(EmergencyEvent event) {
    final DateTime now = DateTime.now();
    final DateTime? lastEmittedAt = _lastEmittedAt;
    if (lastEmittedAt != null &&
        now.difference(lastEmittedAt).inSeconds <
            AppConstants.emergencyDetectionCooldownSeconds) {
      return;
    }

    _lastEmittedAt = now;
    AppLogger.warning(
      'Emergency detection event emitted: ${event.type.value} '
      'confidence=${event.confidenceLevel.toStringAsFixed(2)}',
    );
    _eventController.add(event);
  }

  void _trimSamples(DateTime now) {
    while (_recentSamples.isNotEmpty &&
        now.difference(_recentSamples.first.timestamp) > _eventWindow) {
      _recentSamples.removeFirst();
    }
  }

  int _directionChangeCount() {
    if (_recentSamples.length < 3) {
      return 0;
    }

    int changes = 0;
    double? previousTrend;
    double? previousDelta;
    for (final _MotionSample sample in _recentSamples) {
      final double? lastDelta = previousDelta;
      if (lastDelta != null) {
        final double trend = sample.movementDelta - lastDelta;
        final double? lastTrend = previousTrend;
        if (lastTrend != null &&
            trend.abs() > 1.5 &&
            lastTrend.abs() > 1.5 &&
            trend.sign != lastTrend.sign) {
          changes++;
        }
        if (trend.abs() > 1.5) {
          previousTrend = trend;
        }
      }
      previousDelta = sample.movementDelta;
    }
    return changes;
  }

  double _magnitude(double x, double y, double z) {
    return math.sqrt(x * x + y * y + z * z);
  }
}

class _MotionSample {
  const _MotionSample({
    required this.timestamp,
    required this.accelerationMagnitude,
    required this.movementDelta,
    required this.gyroscopeMagnitude,
    required this.isStill,
  });

  final DateTime timestamp;
  final double accelerationMagnitude;
  final double movementDelta;
  final double gyroscopeMagnitude;
  final bool isStill;
}
