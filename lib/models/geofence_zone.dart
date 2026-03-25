import '../core/constants/app_constants.dart';
import 'app_enums.dart';

class GeofenceZone {
  const GeofenceZone({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.isEnabled,
  });

  final String id;
  final String name;
  final GeofenceType type;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isEnabled;

  factory GeofenceZone.fromMap(Map<String, dynamic> map) {
    final GeofenceType? type = geofenceTypeFromValue(
      map[FirestoreFields.type] as String?,
    );
    if (type == null) {
      throw const FormatException('Geofence type is invalid.');
    }

    return GeofenceZone(
      id: (map[FirestoreFields.id] as String?)?.trim() ?? '',
      name: (map[FirestoreFields.name] as String?)?.trim() ?? '',
      type: type,
      lat: (map[FirestoreFields.locationLat] as num?)?.toDouble() ?? 0,
      lng: (map[FirestoreFields.locationLng] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.id: id,
      FirestoreFields.name: name,
      FirestoreFields.type: type.value,
      FirestoreFields.locationLat: lat,
      FirestoreFields.locationLng: lng,
      'radiusMeters': radiusMeters,
      'isEnabled': isEnabled,
    };
  }
}

class GeofenceConfig {
  const GeofenceConfig({required this.userId, required this.zones});

  final String userId;
  final List<GeofenceZone> zones;

  factory GeofenceConfig.empty(String userId) {
    return GeofenceConfig(userId: userId, zones: const <GeofenceZone>[]);
  }

  factory GeofenceConfig.fromMap(Map<String, dynamic> map) {
    return GeofenceConfig(
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      zones: (map[FirestoreFields.zones] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(GeofenceZone.fromMap)
          .toList(growable: false),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.userId: userId,
      FirestoreFields.zones: zones
          .map((GeofenceZone zone) => zone.toMap())
          .toList(),
    };
  }
}
