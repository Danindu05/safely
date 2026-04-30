class BatteryConstants {
  // Battery Warning Thresholds
  static const int lowBatteryWarningThreshold = 15; // Percent
  static const int criticalBatteryThreshold = 5; // Percent
  
  // Alert Messages
  static const String lowBatteryAlertTitle = 'Low Battery Warning';
  static const String criticalBatteryAlertTitle = 'CRITICAL BATTERY: Device Shutting Down';
  
  static const String criticalAlertBody = 'Safemate device is about to power off. Final location sent.';
}
