import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class SafelyMap extends StatefulWidget {
  const SafelyMap({
    super.key,
    required this.center,
    this.controller,
    this.zoom = 14,
    this.markers = const <Marker>[],
    this.circles = const <CircleMarker>[],
    this.polylines = const <Polyline>[],
    this.onLongPress,
  });

  final LatLng center;
  final MapController? controller;
  final double zoom;
  final List<Marker> markers;
  final List<CircleMarker> circles;
  final List<Polyline> polylines;
  final void Function(LatLng point)? onLongPress;

  @override
  State<SafelyMap> createState() => _SafelyMapState();
}

class _SafelyMapState extends State<SafelyMap> {
  late final MapController _internalController;
  MapController get _controller => widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = MapController();
  }

  Future<void> _openAttribution() {
    return launchUrl(
      Uri.parse(AppConstants.openStreetMapCopyrightUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        onLongPress: widget.onLongPress == null
            ? null
            : (_, LatLng point) => widget.onLongPress!(point),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: AppConstants.openStreetMapTileUrl,
          userAgentPackageName: AppConstants.mapUserAgentPackageName,
        ),
        if (widget.polylines.isNotEmpty)
          PolylineLayer(polylines: widget.polylines),
        if (widget.circles.isNotEmpty) CircleLayer(circles: widget.circles),
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
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

  @override
  void didUpdateWidget(covariant SafelyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameCenter(oldWidget.center, widget.center) &&
        oldWidget.zoom == widget.zoom) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.move(widget.center, widget.zoom);
    });
  }

  bool _sameCenter(LatLng a, LatLng b) {
    return a.latitude == b.latitude && a.longitude == b.longitude;
  }
}
