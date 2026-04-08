import 'route_geometry.dart';

class RouteTrackingSession {
  const RouteTrackingSession({
    required this.startLat,
    required this.startLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.startedAt,
    required this.deviationThresholdMeters,
    required this.deviationAlertSent,
    required this.startedLiveSharingForRoute,
    required this.encodedPolyline,
    required this.routeBounds,
    required this.routeSource,
  });

  final double startLat;
  final double startLng;
  final double destinationLat;
  final double destinationLng;
  final DateTime startedAt;
  final double deviationThresholdMeters;
  final bool deviationAlertSent;
  final bool startedLiveSharingForRoute;
  final String? encodedPolyline;
  final RouteBounds? routeBounds;
  final String routeSource;

  factory RouteTrackingSession.fromMap(Map<String, dynamic> map) {
    return RouteTrackingSession(
      startLat: (map['startLat'] as num?)?.toDouble() ?? 0,
      startLng: (map['startLng'] as num?)?.toDouble() ?? 0,
      destinationLat: (map['destinationLat'] as num?)?.toDouble() ?? 0,
      destinationLng: (map['destinationLng'] as num?)?.toDouble() ?? 0,
      startedAt:
          DateTime.tryParse(map['startedAt'] as String? ?? '') ??
          DateTime.now(),
      deviationThresholdMeters:
          (map['deviationThresholdMeters'] as num?)?.toDouble() ?? 150,
      deviationAlertSent: map['deviationAlertSent'] as bool? ?? false,
      startedLiveSharingForRoute:
          map['startedLiveSharingForRoute'] as bool? ?? false,
      encodedPolyline:
          (map['encodedPolyline'] as String?)?.trim().isEmpty == true
          ? null
          : map['encodedPolyline'] as String?,
      routeBounds: map['routeBounds'] is Map
          ? RouteBounds.fromMap(
              (map['routeBounds'] as Map).cast<String, dynamic>(),
            )
          : null,
      routeSource: (map['routeSource'] as String?)?.trim() ?? 'straight_line',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startLat': startLat,
      'startLng': startLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startedAt': startedAt.toIso8601String(),
      'deviationThresholdMeters': deviationThresholdMeters,
      'deviationAlertSent': deviationAlertSent,
      'startedLiveSharingForRoute': startedLiveSharingForRoute,
      'encodedPolyline': encodedPolyline,
      'routeBounds': routeBounds?.toMap(),
      'routeSource': routeSource,
    };
  }

  RouteTrackingSession copyWith({
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
    DateTime? startedAt,
    double? deviationThresholdMeters,
    bool? deviationAlertSent,
    bool? startedLiveSharingForRoute,
    String? encodedPolyline,
    RouteBounds? routeBounds,
    String? routeSource,
  }) {
    return RouteTrackingSession(
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      startedAt: startedAt ?? this.startedAt,
      deviationThresholdMeters:
          deviationThresholdMeters ?? this.deviationThresholdMeters,
      deviationAlertSent: deviationAlertSent ?? this.deviationAlertSent,
      startedLiveSharingForRoute:
          startedLiveSharingForRoute ?? this.startedLiveSharingForRoute,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      routeBounds: routeBounds ?? this.routeBounds,
      routeSource: routeSource ?? this.routeSource,
    );
  }
}
