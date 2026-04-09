import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/guardian_map_info_card.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../models/geofence_zone.dart';
import '../../models/live_location.dart';
import '../../models/user_profile.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/guardian_live_map_viewmodel.dart';
import 'alert_detail_screen.dart';

class GuardianLiveMapScreen extends StatelessWidget {
  const GuardianLiveMapScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardianLiveMapViewModel>(
      create: (_) => GuardianLiveMapViewModel(
        alertRepository: context.read<AlertRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        locationRepository: context.read<LocationRepository>(),
        guardianId: guardianId,
      ),
      child: _GuardianLiveMapScreenBody(guardianId: guardianId),
    );
  }
}

class _GuardianLiveMapScreenBody extends StatefulWidget {
  const _GuardianLiveMapScreenBody({required this.guardianId});

  final String guardianId;

  @override
  State<_GuardianLiveMapScreenBody> createState() =>
      _GuardianLiveMapScreenBodyState();
}

class _GuardianLiveMapScreenBodyState
    extends State<_GuardianLiveMapScreenBody> {
  final MapController _mapController = MapController();

  Future<void> _callContact(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _messageContact(BuildContext context, String phone) async {
    final bool launched = await launchUrl(Uri.parse('sms:$phone'));
    if (launched || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging handoff is not available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuardianLiveMapViewModel>(
      builder: (BuildContext context, GuardianLiveMapViewModel viewModel, Widget? child) {
        final UserProfile? selectedSafemate = viewModel.safemates
            .where(
              (UserProfile user) => user.id == viewModel.selectedSafemateId,
            )
            .firstOrNull;
        final LiveLocation? liveLocation = viewModel.liveLocation;
        final _ConnectionHealth connection = _connectionHealth(
          liveLocation,
          selectedSafemate?.lastLocationSyncAt,
        );
        final List<CircleMarker> geofenceCircles = viewModel.geofenceZones
            .map(
              (GeofenceZone zone) => CircleMarker(
                point: LatLng(zone.lat, zone.lng),
                radius: zone.radiusMeters,
                useRadiusInMeter: true,
                color: zone.type == GeofenceType.unsafe
                    ? AppColors.emergency.withValues(alpha: 0.12)
                    : AppColors.safe.withValues(alpha: 0.12),
                borderColor: zone.type == GeofenceType.unsafe
                    ? AppColors.emergency
                    : AppColors.safe,
                borderStrokeWidth: 2,
              ),
            )
            .toList(growable: false);
        final List<Marker> markers = <Marker>[
          ...viewModel.geofenceZones.map(
            (GeofenceZone zone) => Marker(
              point: LatLng(zone.lat, zone.lng),
              width: 40,
              height: 40,
              child: Icon(
                zone.type == GeofenceType.unsafe
                    ? Icons.warning_amber_rounded
                    : Icons.home_work_outlined,
                color: zone.type == GeofenceType.unsafe
                    ? AppColors.emergency
                    : AppColors.safe,
              ),
            ),
          ),
          if (liveLocation != null)
            Marker(
              point: LatLng(liveLocation.lat, liveLocation.lng),
              width: 52,
              height: 52,
              child: const Icon(
                Icons.my_location,
                color: AppColors.info,
                size: 34,
              ),
            ),
        ];

        return Scaffold(
          appBar: AppBar(title: const Text('Guardian live map')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppSectionHeader(
                      title: 'Monitor live location',
                      subtitle:
                          'Choose a Safemate to see their latest live session and location freshness.',
                    ),
                    if (viewModel.safemates.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: viewModel.selectedSafemateId,
                        items: viewModel.safemates
                            .map(
                              (UserProfile user) => DropdownMenuItem<String>(
                                value: user.id,
                                child: Text(user.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          viewModel.selectSafemate(value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Selected Safemate',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (viewModel.safemates.isEmpty)
                const EmptyStateCard(
                  icon: Icons.groups_outlined,
                  title: 'No linked Safemates yet',
                  message:
                      'Once a Safemate links to you, their live monitoring view will appear here.',
                )
              else if (selectedSafemate == null)
                const EmptyStateCard(
                  icon: Icons.person_search_outlined,
                  title: 'Choose a Safemate',
                  message:
                      'Select a linked Safemate to view live location and safety context.',
                )
              else ...<Widget>[
                if (viewModel.errorMessage != null) ...<Widget>[
                  AppInfoBanner(
                    title: 'Map status',
                    message: viewModel.errorMessage!,
                    icon: Icons.map_outlined,
                    tone: AppTone.warning,
                  ),
                  const SizedBox(height: 16),
                ],
                if (liveLocation != null)
                  SizedBox(
                    height: 420,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      child: Stack(
                        children: <Widget>[
                          SafelyMap(
                            controller: _mapController,
                            center: LatLng(liveLocation.lat, liveLocation.lng),
                            zoom: 15,
                            markers: markers,
                            circles: geofenceCircles,
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: GuardianMapInfoCard(
                              name: selectedSafemate.name,
                              statusLabel: selectedSafemate.isEmergencyActive
                                  ? 'Emergency active'
                                  : 'Monitoring',
                              connectionLabel: connection.label,
                              connectionTone: connection.tone,
                              batteryLabel: _batteryLabel(
                                selectedSafemate.batteryLevel,
                              ),
                              lastUpdatedLabel: _lastUpdatedLabel(
                                liveLocation.updatedAt,
                                connection,
                              ),
                              sourceLabel:
                                  'Source: ${_sourceLabel(liveLocation.source)}',
                              isEmergencyActive:
                                  selectedSafemate.isEmergencyActive,
                            ),
                          ),
                          if (viewModel.geofenceZones.isNotEmpty)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: <Widget>[
                                    const AppStatusChip(
                                      label: 'Safe zone',
                                      tone: AppTone.safe,
                                      compact: true,
                                    ),
                                    const SizedBox(width: 8),
                                    const AppStatusChip(
                                      label: 'Unsafe zone',
                                      tone: AppTone.danger,
                                      compact: true,
                                    ),
                                    const SizedBox(width: 8),
                                    AppStatusChip(
                                      label:
                                          '${viewModel.geofenceZones.length} zone${viewModel.geofenceZones.length == 1 ? '' : 's'} visible',
                                      tone: AppTone.neutral,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else ...<Widget>[
                  GuardianMapInfoCard(
                    name: selectedSafemate.name,
                    statusLabel: selectedSafemate.isEmergencyActive
                        ? 'Emergency active'
                        : 'No live session',
                    connectionLabel: connection.label,
                    connectionTone: connection.tone,
                    batteryLabel: _batteryLabel(selectedSafemate.batteryLevel),
                    lastUpdatedLabel:
                        selectedSafemate.lastLocationSyncAt == null
                        ? 'Location has not been shared recently.'
                        : 'Last sync ${DateTimeFormatter.formatRelative(selectedSafemate.lastLocationSyncAt!)}',
                    sourceLabel: selectedSafemate.isEmergencyActive
                        ? 'Waiting for live updates from the emergency session.'
                        : 'Live sharing is currently off.',
                    isEmergencyActive: selectedSafemate.isEmergencyActive,
                  ),
                  const SizedBox(height: 16),
                  EmptyStateCard(
                    icon: Icons.location_disabled_outlined,
                    title: selectedSafemate.isEmergencyActive
                        ? 'Waiting for location updates'
                        : 'No live location available',
                    message: selectedSafemate.isEmergencyActive
                        ? 'An emergency is active, but this device has not received a fresh live location yet.'
                        : 'The Safemate is not sharing live location right now, or the last update has expired.',
                  ),
                ],
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Quick actions',
                  subtitle:
                      'Use the fastest path to respond when something changes.',
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: viewModel.latestAlert == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => AlertDetailScreen(
                                            alertId: viewModel.latestAlert!.id,
                                            guardianId: widget.guardianId,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('View alert'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  (selectedSafemate.emergencyContactPhone)
                                      .isEmpty
                                  ? null
                                  : () => _callContact(
                                      selectedSafemate.emergencyContactPhone,
                                    ),
                              icon: const Icon(Icons.call_outlined),
                              label: const Text('Call'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  (selectedSafemate.emergencyContactPhone)
                                      .isEmpty
                                  ? null
                                  : () => _messageContact(
                                      context,
                                      selectedSafemate.emergencyContactPhone,
                                    ),
                              icon: const Icon(Icons.message_outlined),
                              label: const Text('Message'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: liveLocation == null
                                  ? null
                                  : () => _mapController.move(
                                      LatLng(
                                        liveLocation.lat,
                                        liveLocation.lng,
                                      ),
                                      15,
                                    ),
                              icon: const Icon(Icons.center_focus_strong),
                              label: const Text('Center map'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (viewModel.infoMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AppInfoBanner(
                    title: 'Map update',
                    message: viewModel.infoMessage!,
                    icon: Icons.info_outline,
                    tone: AppTone.info,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

_ConnectionHealth _connectionHealth(
  LiveLocation? liveLocation,
  DateTime? lastLocationSyncAt,
) {
  final DateTime? basis = liveLocation?.updatedAt ?? lastLocationSyncAt;
  if (basis == null) {
    return const _ConnectionHealth(label: 'Unavailable', tone: AppTone.neutral);
  }

  final Duration difference = DateTime.now().difference(basis);
  if (difference.inSeconds <= 15) {
    return const _ConnectionHealth(label: 'Live', tone: AppTone.safe);
  }
  if (difference.inSeconds <= 60) {
    return const _ConnectionHealth(label: 'Delayed', tone: AppTone.warning);
  }
  return const _ConnectionHealth(label: 'Lost', tone: AppTone.danger);
}

String _batteryLabel(int? batteryLevel) {
  if (batteryLevel == null) {
    return 'Battery unknown';
  }
  if (batteryLevel <= 5) {
    return 'Battery critical • $batteryLevel%';
  }
  if (batteryLevel <= 15) {
    return 'Battery low • $batteryLevel%';
  }
  return 'Battery $batteryLevel%';
}

String _lastUpdatedLabel(DateTime updatedAt, _ConnectionHealth connection) {
  final String prefix = switch (connection.label) {
    'Live' => 'Updated',
    'Delayed' => 'Location delayed',
    'Lost' => 'Location lost',
    _ => 'Updated',
  };
  return '$prefix ${DateTimeFormatter.formatRelative(updatedAt)}';
}

String _sourceLabel(String source) {
  return switch (source) {
    'sos' => 'Emergency SOS',
    'manual_share' => 'Manual live sharing',
    'low_battery' => 'Critical battery protection',
    'route_tracking' => 'Route tracking',
    _ => source.replaceAll('_', ' '),
  };
}

class _ConnectionHealth {
  const _ConnectionHealth({required this.label, required this.tone});

  final String label;
  final AppTone tone;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
