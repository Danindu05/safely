import 'package:flutter/foundation.dart';

/// Represents the real-time status and safety metrics of a monitored device.
class ChildActivity {
  final String childId;
  final String childName;
  final DateTime lastUpdated;
  
  // Safety Metrics
  final double latitude;
  final double longitude;
  final double batteryLevel;
  final bool isInsideSafeZone;
  
  // Activity Monitoring
  final String currentAppUsage; // e.g., "Educational Game" or "Social Media"
  final List<String> safetyAlerts;

  ChildActivity({
    required this.childId,
    required this.childName,
    required this.lastUpdated,
    required this.latitude,
    required this.longitude,
    required this.batteryLevel,
    this.isInsideSafeZone = true,
    this.currentAppUsage = "None",
    this.safetyAlerts = const [],
  });

  /// Helper method to determine if an immediate notification is needed
  bool get requiresAttention => !isInsideSafeZone || batteryLevel < 0.15;

  /// Factory method to simulate data fetching from a backend API
  factory ChildActivity.mock() {
    return ChildActivity(
      childId: "USR-7721",
      childName: "Alex",
      lastUpdated: DateTime.now(),
      latitude: 34.0522,
      longitude: -118.2437,
      batteryLevel: 0.85,
      isInsideSafeZone: true,
      currentAppUsage: "Google Classroom",
    );
  }
}
