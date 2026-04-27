import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

/// Service to monitor device battery levels and trigger safety protocols.
class BatteryMonitorService {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;

  // Thresholds defined in your README
  final int lowBatteryThreshold = 20;
  final int criticalBatteryThreshold = 5;

  /// Starts listening to battery state changes
  void startMonitoring(Function(int) onCriticalLevel) {
    _batterySubscription = _battery.onBatteryStateChanged.listen((BatteryState state) async {
      final level = await _battery.batteryLevel;
      
      if (level <= criticalBatteryThreshold) {
        // Trigger the Critical Battery Emergency Mode mentioned in README
        onCriticalLevel(level);
      }
    });
  }

  /// Manually check battery level (used for check-ins)
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  void stopMonitoring() {
    _batterySubscription?.cancel();
  }
}
