import 'dart:convert';
import 'dart:io';

import '../../models/route_geometry.dart';
import '../constants/app_constants.dart';

class RouteService {
  RouteService({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;

  Future<RoutePlan> fetchRoute({
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final Uri uri = Uri.https(
      AppConstants.osrmRouteHost,
      '/route/v1/driving/$startLng,$startLat;$destinationLng,$destinationLat',
      <String, String>{
        'overview': 'full',
        'geometries': 'polyline',
        'steps': 'false',
      },
    );

    final HttpClientRequest request = await _httpClient
        .getUrl(uri)
        .timeout(
          const Duration(seconds: AppConstants.routeFetchTimeoutSeconds),
        );
    request.headers.set(HttpHeaders.userAgentHeader, 'Safely/1.0 Android');

    final HttpClientResponse response = await request.close().timeout(
      const Duration(seconds: AppConstants.routeFetchTimeoutSeconds),
    );
    final String body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Route service returned ${response.statusCode}.');
    }

    final Object? decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Route response was not a JSON object.');
    }

    final String code = (decoded['code'] as String?)?.trim() ?? '';
    final List<dynamic> routes =
        decoded['routes'] as List<dynamic>? ?? const <dynamic>[];
    if (code != 'Ok' || routes.isEmpty || routes.first is! Map) {
      throw StateError('Route service could not build a route.');
    }

    final Map<String, dynamic> route = (routes.first as Map)
        .cast<String, dynamic>();
    final String encodedPolyline = (route['geometry'] as String?)?.trim() ?? '';
    if (encodedPolyline.isEmpty) {
      throw const FormatException('Route response did not include geometry.');
    }

    final List<RoutePoint> points = decodePolyline(encodedPolyline);
    if (points.length < 2) {
      throw const FormatException('Route geometry was too short.');
    }

    return RoutePlan(
      encodedPolyline: encodedPolyline,
      points: points,
      bounds: RouteBounds.fromPoints(points),
    );
  }

  List<RoutePoint> decodePolyline(String encodedPolyline) {
    return RouteGeometryCodec.decodePolyline(encodedPolyline);
  }

  void dispose() {
    _httpClient.close(force: true);
  }
}
