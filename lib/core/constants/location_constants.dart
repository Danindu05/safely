class LocationConstants {
  // Constants related to Live Location Tracking
  static const double minLocationAccuracy = 15.0; // In meters
  static const int updateIntervalSeconds = 5; // Minimum time between updates
  static const int distanceFilterMeters = 10; // Minimum distance to trigger update
  
  // Realtime Database Nodes
  static const String liveLocationNode = 'live_locations';
  static const String sosActiveStatusNode = 'sos_status';
}
