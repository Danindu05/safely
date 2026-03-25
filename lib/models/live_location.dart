class LiveLocation {
  const LiveLocation({
    required this.userId,
    required this.guardianIds,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.updatedAt,
    required this.isEmergencyActive,
    required this.source,
  });

  final String userId;
  final List<String> guardianIds;
  final double lat;
  final double lng;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime updatedAt;
  final bool isEmergencyActive;
  final String source;

  factory LiveLocation.fromMap(
    Map<Object?, Object?> map, {
    required String userId,
  }) {
    final Map<Object?, Object?> guardianAccess =
        map['guardianAccess'] as Map<Object?, Object?>? ??
        const <Object?, Object?>{};
    final List<String> guardianIds = guardianAccess.isNotEmpty
        ? guardianAccess.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList(growable: false)
        : (map['guardianIds'] as List<Object?>? ?? const <Object?>[])
              .whereType<String>()
              .toList(growable: false);

    return LiveLocation(
      userId: userId,
      guardianIds: guardianIds,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0,
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      isEmergencyActive: map['isEmergencyActive'] as bool? ?? false,
      source: (map['source'] as String?)?.trim() ?? 'manual_share',
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'guardianIds': guardianIds,
      'guardianAccess': <String, bool>{
        for (final String guardianId in guardianIds) guardianId: true,
      },
      'lat': lat,
      'lng': lng,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'updatedAt': updatedAt.toIso8601String(),
      'isEmergencyActive': isEmergencyActive,
      'source': source,
    };
  }
}
