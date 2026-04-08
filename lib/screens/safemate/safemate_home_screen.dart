import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/route_geometry.dart';
import '../../models/route_tracking_session.dart';
import '../../models/safety_alert.dart';
import '../../models/safety_timer_state.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../viewmodels/safemate_home_viewmodel.dart';
import '../../viewmodels/safemate_shell_viewmodel.dart';

class SafemateHomeScreen extends StatelessWidget {
  const SafemateHomeScreen({
    super.key,
    required this.profile,
    required this.settings,
    required this.batteryLevel,
    required this.isOnline,
  });

  final UserProfile profile;
  final UserSettings? settings;
  final int? batteryLevel;
  final bool isOnline;

  Future<_RouteDestination?> _showRouteDialog(BuildContext context) async {
    final TextEditingController latitudeController = TextEditingController();
    final TextEditingController longitudeController = TextEditingController();

    return showDialog<_RouteDestination>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Start journey monitoring'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Destination latitude',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Destination longitude',
                    ),
                  ),
                  if (errorText != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final double? latitude = double.tryParse(
                      latitudeController.text.trim(),
                    );
                    final double? longitude = double.tryParse(
                      longitudeController.text.trim(),
                    );

                    if (latitude == null ||
                        longitude == null ||
                        latitude < -90 ||
                        latitude > 90 ||
                        longitude < -180 ||
                        longitude > 180) {
                      setState(() {
                        errorText = 'Enter valid destination coordinates.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(_RouteDestination(latitude, longitude));
                  },
                  child: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SafemateHomeViewModel>(
      create: (_) => SafemateHomeViewModel(
        alertRepository: context.read<AlertRepository>(),
        safetyRepository: context.read<SafetyRepository>(),
        profile: profile,
        settings: settings,
      ),
      child: Consumer<SafemateHomeViewModel>(
        builder: (BuildContext context, SafemateHomeViewModel viewModel, Widget? child) {
          final SafemateShellViewModel shellViewModel = context
              .watch<SafemateShellViewModel>();
          final SafetyRuntimeState runtimeState = viewModel.runtimeState;
          final bool emergencyActive = profile.isEmergencyActive;
          final RouteTrackingSession? activeRoute =
              shellViewModel.runtimeState.activeRouteTracking;
          final SafetyTimerState? activeSafetyTimer =
              shellViewModel.runtimeState.safetyTimer;
          final StatusChip statusChip = emergencyActive
              ? const StatusChip(
                  label: 'Emergency active',
                  color: AppColors.emergency,
                )
              : runtimeState.isLiveSharingActive
              ? const StatusChip(label: 'Monitoring', color: AppColors.warning)
              : activeSafetyTimer != null
              ? const StatusChip(
                  label: 'Timer active',
                  color: AppColors.warning,
                )
              : runtimeState.isNightMonitoringActive
              ? const StatusChip(
                  label: 'Night monitoring',
                  color: AppColors.warning,
                )
              : runtimeState.isTrustedPlaceActive
              ? const StatusChip(label: 'Trusted place', color: AppColors.safe)
              : const StatusChip(label: 'Safe', color: AppColors.safe);

          final String? errorMessage =
              viewModel.errorMessage ?? shellViewModel.errorMessage;
          final String? infoMessage =
              viewModel.infoMessage ?? shellViewModel.infoMessage;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Safemate'),
              actions: <Widget>[
                TextButton.icon(
                  onPressed: null,
                  icon: Icon(
                    Icons.cloud_done_outlined,
                    color: profile.lastLocationSyncAt == null
                        ? AppColors.muted
                        : AppColors.safe,
                  ),
                  label: Text(
                    profile.lastLocationSyncAt == null ? 'Idle' : 'Synced',
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: <Widget>[
                SectionCard(
                  title: 'Current safety status',
                  trailing: statusChip,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          MetricTile(
                            label: 'Battery',
                            value: '${batteryLevel ?? '--'}%',
                            icon: Icons.battery_5_bar_outlined,
                            emphasisColor: (batteryLevel ?? 100) <= 15
                                ? AppColors.emergency
                                : AppColors.safe,
                          ),
                          const SizedBox(width: 12),
                          MetricTile(
                            label: 'Guardians',
                            value: '${profile.guardianIds.length}',
                            icon: Icons.groups_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          MetricTile(
                            label: 'Last sync',
                            value: profile.lastLocationSyncAt == null
                                ? 'Not yet'
                                : DateTimeFormatter.formatShort(
                                    profile.lastLocationSyncAt!,
                                  ),
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(width: 12),
                          MetricTile(
                            label: 'Connection',
                            value: isOnline ? 'Online' : 'Offline',
                            icon: isOnline
                                ? Icons.wifi_tethering
                                : Icons.wifi_off,
                            emphasisColor: isOnline
                                ? AppColors.safe
                                : AppColors.warning,
                          ),
                        ],
                      ),
                      if (runtimeState.isTrustedPlaceActive ||
                          runtimeState.isNightMonitoringActive ||
                          activeSafetyTimer != null ||
                          activeRoute != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (runtimeState.isTrustedPlaceActive)
                              const StatusChip(
                                label: 'Safe zone active',
                                color: AppColors.safe,
                              ),
                            if (runtimeState.isNightMonitoringActive)
                              const StatusChip(
                                label: 'Overnight watch on',
                                color: AppColors.warning,
                              ),
                            if (activeSafetyTimer != null)
                              StatusChip(
                                label:
                                    'Timer ${_formatDuration(activeSafetyTimer.remainingAt(DateTime.now()))}',
                                color: AppColors.warning,
                              ),
                            if (activeRoute != null)
                              StatusChip(
                                label: activeRoute.deviationAlertSent
                                    ? 'Deviation shared'
                                    : 'Journey active',
                                color: activeRoute.deviationAlertSent
                                    ? AppColors.emergency
                                    : AppColors.safe,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Emergency SOS',
                  subtitle:
                      'One tap starts alerts, live sharing, and emergency recording.',
                  child: Column(
                    children: <Widget>[
                      Center(
                        child: SizedBox(
                          width: AppConstants.sosButtonSize,
                          height: AppConstants.sosButtonSize,
                          child: FilledButton(
                            onPressed: viewModel.isBusy
                                ? null
                                : viewModel.triggerSos,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emergency,
                              foregroundColor: Colors.white,
                              shape: const CircleBorder(),
                            ),
                            child: Text(
                              viewModel.isBusy ? 'Sending...' : 'SOS',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  viewModel.sendCheckIn(batteryLevel),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Quick check-in'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: viewModel.toggleManualLiveSharing,
                              icon: Icon(
                                runtimeState.isLiveSharingActive
                                    ? Icons.location_off
                                    : Icons.share_location_outlined,
                              ),
                              label: Text(
                                runtimeState.isLiveSharingActive
                                    ? 'Stop live'
                                    : 'Start live',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (runtimeState.isRecordingActive ||
                          runtimeState.isAudioUploading ||
                          runtimeState.audioUploadError != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              if (runtimeState.isRecordingActive)
                                const StatusChip(
                                  label: 'Recording active',
                                  color: AppColors.emergency,
                                ),
                              if (runtimeState.isAudioUploading)
                                const StatusChip(
                                  label: 'Uploading audio',
                                  color: AppColors.warning,
                                ),
                              if (runtimeState.audioUploadError != null)
                                const StatusChip(
                                  label: 'Audio upload failed',
                                  color: AppColors.warning,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Safety tools',
                  subtitle:
                      'Use timers and journey monitoring when you want extra reassurance.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Safety timer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeSafetyTimer == null
                            ? 'If the timer expires without a cancel, SOS starts automatically.'
                            : 'Time remaining: ${_formatDuration(activeSafetyTimer.remainingAt(DateTime.now()))}',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed:
                                activeSafetyTimer != null ||
                                    shellViewModel.isBusy
                                ? null
                                : () => shellViewModel.startSafetyTimer(
                                    const Duration(minutes: 15),
                                  ),
                            child: const Text('15 min'),
                          ),
                          OutlinedButton(
                            onPressed:
                                activeSafetyTimer != null ||
                                    shellViewModel.isBusy
                                ? null
                                : () => shellViewModel.startSafetyTimer(
                                    const Duration(minutes: 30),
                                  ),
                            child: const Text('30 min'),
                          ),
                          OutlinedButton(
                            onPressed:
                                activeSafetyTimer != null ||
                                    shellViewModel.isBusy
                                ? null
                                : () => shellViewModel.startSafetyTimer(
                                    const Duration(hours: 1),
                                  ),
                            child: const Text('1 hour'),
                          ),
                          if (activeSafetyTimer != null)
                            FilledButton.tonal(
                              onPressed: shellViewModel.isBusy
                                  ? null
                                  : shellViewModel.cancelSafetyTimer,
                              child: const Text('Cancel timer'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Journey monitoring',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeRoute == null
                            ? 'Add a destination and Safely will watch for major route changes.'
                            : 'Destination: ${activeRoute.destinationLat.toStringAsFixed(5)}, ${activeRoute.destinationLng.toStringAsFixed(5)}',
                      ),
                      if (activeRoute != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Threshold: ${activeRoute.deviationThresholdMeters.toStringAsFixed(0)}m from the planned path.',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeRoute.routeSource == 'osrm'
                              ? 'Route source: road-aware map route.'
                              : 'Route source: straight-line fallback.',
                        ),
                        const SizedBox(height: 12),
                        _RoutePreviewMap(
                          session: activeRoute,
                          currentPosition: runtimeState.currentRoutePosition,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed:
                                activeRoute != null || shellViewModel.isBusy
                                ? null
                                : () async {
                                    final _RouteDestination? destination =
                                        await _showRouteDialog(context);
                                    if (destination == null) {
                                      return;
                                    }
                                    await shellViewModel.startRouteTracking(
                                      destinationLat: destination.latitude,
                                      destinationLng: destination.longitude,
                                    );
                                  },
                            icon: const Icon(Icons.alt_route),
                            label: const Text('Start route'),
                          ),
                          if (activeRoute != null)
                            FilledButton.tonalIcon(
                              onPressed: shellViewModel.isBusy
                                  ? null
                                  : shellViewModel.stopRouteTracking,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Stop route'),
                            ),
                        ],
                      ),
                      if (shellViewModel.nextCheckInDueAt != null) ...<Widget>[
                        const SizedBox(height: 20),
                        Text(
                          'Next check-in prompt: ${DateTimeFormatter.formatShort(shellViewModel.nextCheckInDueAt!)}',
                        ),
                      ],
                      if (errorMessage != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (infoMessage != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(infoMessage),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (viewModel.latestAlert == null)
                  const EmptyStateCard(
                    icon: Icons.notifications_none,
                    title: 'No recent alerts',
                    message:
                        'Your latest SOS, battery, geofence, and check-in activity will appear here.',
                  )
                else
                  _LatestAlertCard(alert: viewModel.latestAlert!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LatestAlertCard extends StatelessWidget {
  const _LatestAlertCard({required this.alert});

  final SafetyAlert alert;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Latest alert',
      subtitle: DateTimeFormatter.formatShort(alert.timestamp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(alert.description),
        ],
      ),
    );
  }
}

class _RouteDestination {
  const _RouteDestination(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class _RoutePreviewMap extends StatelessWidget {
  const _RoutePreviewMap({
    required this.session,
    required this.currentPosition,
  });

  final RouteTrackingSession session;
  final RoutePoint? currentPosition;

  @override
  Widget build(BuildContext context) {
    final RoutePoint current =
        currentPosition ??
        RoutePoint(lat: session.startLat, lng: session.startLng);
    final List<RoutePoint> routePoints = _routePoints(session);
    final List<LatLng> polylinePoints = routePoints
        .map((RoutePoint point) => LatLng(point.lat, point.lng))
        .toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: SizedBox(
        height: 220,
        child: SafelyMap(
          center: LatLng(current.lat, current.lng),
          zoom: 14,
          polylines: polylinePoints.length < 2
              ? const <Polyline>[]
              : <Polyline>[
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 5,
                    color: AppColors.navy,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
          markers: <Marker>[
            Marker(
              point: LatLng(session.startLat, session.startLng),
              width: 36,
              height: 36,
              child: const Icon(
                Icons.trip_origin,
                color: AppColors.safe,
                size: 28,
              ),
            ),
            Marker(
              point: LatLng(session.destinationLat, session.destinationLng),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.place,
                color: AppColors.emergency,
                size: 36,
              ),
            ),
            Marker(
              point: LatLng(current.lat, current.lng),
              width: 42,
              height: 42,
              child: const Icon(
                Icons.my_location,
                color: AppColors.warning,
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RoutePoint> _routePoints(RouteTrackingSession session) {
    final String? encodedPolyline = session.encodedPolyline;
    if (encodedPolyline != null && encodedPolyline.isNotEmpty) {
      try {
        final List<RoutePoint> decoded = RouteGeometryCodec.decodePolyline(
          encodedPolyline,
        );
        if (decoded.length >= 2) {
          return decoded;
        }
      } catch (_) {
        // Visual fallback only; repository-side deviation logic already logs.
      }
    }

    return <RoutePoint>[
      RoutePoint(lat: session.startLat, lng: session.startLng),
      RoutePoint(lat: session.destinationLat, lng: session.destinationLng),
    ];
  }
}

String _formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  if (minutes >= 60) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}
