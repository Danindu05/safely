import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class SafelyMap extends StatelessWidget {
  const SafelyMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const <Marker>[],
    this.circles = const <CircleMarker>[],
    this.onLongPress,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final List<CircleMarker> circles;
  final void Function(LatLng point)? onLongPress;

  Future<void> _openAttribution() {
    return launchUrl(
      Uri.parse(AppConstants.openStreetMapCopyrightUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: ValueKey<String>(
        '${center.latitude}_${center.longitude}_${zoom}_${markers.length}_${circles.length}',
      ),
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onLongPress: onLongPress == null
            ? null
            : (_, LatLng point) => onLongPress!(point),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: AppConstants.openStreetMapTileUrl,
          userAgentPackageName: AppConstants.mapUserAgentPackageName,
        ),
        if (circles.isNotEmpty) CircleLayer(circles: circles),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        RichAttributionWidget(
          showFlutterMapAttribution: false,
          attributions: <SourceAttribution>[
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: _openAttribution,
            ),
          ],
        ),
      ],
    );
  }
}
