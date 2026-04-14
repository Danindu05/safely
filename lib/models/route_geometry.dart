class RoutePoint {
  const RoutePoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{'lat': lat, 'lng': lng};
  }
}

class RouteBounds {
  const RouteBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  factory RouteBounds.fromPoints(List<RoutePoint> points) {
    if (points.isEmpty) {
      return const RouteBounds(south: 0, west: 0, north: 0, east: 0);
    }

    double south = points.first.lat;
    double north = points.first.lat;
    double west = points.first.lng;
    double east = points.first.lng;

    for (final RoutePoint point in points) {
      if (point.lat < south) {
        south = point.lat;
      }
      if (point.lat > north) {
        north = point.lat;
      }
      if (point.lng < west) {
        west = point.lng;
      }
      if (point.lng > east) {
        east = point.lng;
      }
    }

    return RouteBounds(south: south, west: west, north: north, east: east);
  }

  factory RouteBounds.fromMap(Map<String, dynamic> map) {
    return RouteBounds(
      south: (map['south'] as num?)?.toDouble() ?? 0,
      west: (map['west'] as num?)?.toDouble() ?? 0,
      north: (map['north'] as num?)?.toDouble() ?? 0,
      east: (map['east'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'south': south,
      'west': west,
      'north': north,
      'east': east,
    };
  }
}

class RoutePlan {
  const RoutePlan({
    required this.encodedPolyline,
    required this.points,
    required this.bounds,
  });

  final String encodedPolyline;
  final List<RoutePoint> points;
  final RouteBounds bounds;
}

class RouteGeometryCodec {
  const RouteGeometryCodec._();

  static List<RoutePoint> decodePolyline(String encodedPolyline) {
    final List<RoutePoint> points = <RoutePoint>[];
    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encodedPolyline.length) {
      final _DecodedValue decodedLatitude = _decodeValue(
        encodedPolyline,
        index,
      );
      index = decodedLatitude.nextIndex;
      latitude += decodedLatitude.value;

      final _DecodedValue decodedLongitude = _decodeValue(
        encodedPolyline,
        index,
      );
      index = decodedLongitude.nextIndex;
      longitude += decodedLongitude.value;

      points.add(RoutePoint(lat: latitude / 1e5, lng: longitude / 1e5));
    }

    return points;
  }

  static _DecodedValue _decodeValue(String encodedPolyline, int startIndex) {
    int result = 0;
    int shift = 0;
    int index = startIndex;
    int byte;

    do {
      if (index >= encodedPolyline.length) {
        throw const FormatException('Polyline ended unexpectedly.');
      }
      byte = encodedPolyline.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final int value = (result & 1) == 1 ? ~(result >> 1) : result >> 1;
    return _DecodedValue(value: value, nextIndex: index);
  }
}

class _DecodedValue {
  const _DecodedValue({required this.value, required this.nextIndex});

  final int value;
  final int nextIndex;
}
