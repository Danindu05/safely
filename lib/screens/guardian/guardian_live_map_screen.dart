import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/safely_map.dart';
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

class _GuardianLiveMapScreenBody extends StatelessWidget {
  const _GuardianLiveMapScreenBody({required this.guardianId});

  final String guardianId;

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
      builder:
          (
            BuildContext context,
            GuardianLiveMapViewModel viewModel,
            Widget? child,
          ) {
            final UserProfile? selectedSafemate = _selectedSafemate(
              viewModel.safemates,
              viewModel.selectedSafemateId,
            );
            final LiveLocation? liveLocation = viewModel.liveLocation;
            final _ConnectionState connection = _connectionStateFor(
              liveLocation: liveLocation,
              lastLocationSyncAt: selectedSafemate?.lastLocationSyncAt,
            );
            final LatLng center = liveLocation != null
                ? LatLng(liveLocation.lat, liveLocation.lng)
                : _fallbackCenter(viewModel.geofenceZones);
            final List<CircleMarker> circles = viewModel.geofenceZones
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
                  width: 48,
                  height: 48,
                  child: const Icon(
                    Icons.my_location,
                    color: AppColors.navy,
                    size: 34,
                  ),
                ),
            ];

            return Scaffold(
              body: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: SafelyMap(
                      center: center,
                      zoom: liveLocation == null ? 13 : 15,
                      markers: markers,
                      circles: circles,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.pagePadding),
                      child: Column(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topLeft,
                            child: _SafematePickerCard(
                              safemates: viewModel.safemates,
                              selectedSafemateId: viewModel.selectedSafemateId,
                              onSelected: viewModel.selectSafemate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (selectedSafemate != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _LiveInfoCard(
                                key: ValueKey<String>(selectedSafemate.id),
                                safemate: selectedSafemate,
                                liveLocation: liveLocation,
                                connection: connection,
                              ),
                            ),
                          const Spacer(),
                          if (selectedSafemate != null)
                            _MapActionBar(
                              onCall:
                                  selectedSafemate.emergencyContactPhone
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : () => _callContact(
                                      selectedSafemate.emergencyContactPhone,
                                    ),
                              onMessage:
                                  selectedSafemate.emergencyContactPhone
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : () => _messageContact(
                                      context,
                                      selectedSafemate.emergencyContactPhone,
                                    ),
                              onViewAlert: viewModel.latestAlert == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => AlertDetailScreen(
                                            alertId: viewModel.latestAlert!.id,
                                            guardianId: guardianId,
                                          ),
                                        ),
                                      );
                                    },
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedSafemate == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.pagePadding),
                        child: InfoCard(
                          child: Text(
                            'Link a Safemate to start monitoring live location.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else if (liveLocation == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.pagePadding),
                        child: InfoCard(
                          child: Text(
                            selectedSafemate.isEmergencyActive
                                ? 'Waiting for live location updates.'
                                : 'Live location is not being shared right now.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
    );
  }
}

class _SafematePickerCard extends StatelessWidget {
  const _SafematePickerCard({
    required this.safemates,
    required this.selectedSafemateId,
    required this.onSelected,
  });

  final List<UserProfile> safemates;
  final String? selectedSafemateId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (safemates.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: InfoCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSafemateId ?? safemates.first.id,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: safemates
                .map(
                  (UserProfile user) => DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(user.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              onSelected(value);
            },
          ),
        ),
      ),
    );
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({
    super.key,
    required this.safemate,
    required this.liveLocation,
    required this.connection,
  });

  final UserProfile safemate;
  final LiveLocation? liveLocation;
  final _ConnectionState connection;

  @override
  Widget build(BuildContext context) {
    final String updatedText = liveLocation == null
        ? 'Location unavailable'
        : 'Updated ${DateTimeFormatter.formatRelative(liveLocation!.updatedAt)}';

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  safemate.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppStatusChip(
                label: safemate.isEmergencyActive ? 'Emergency' : 'Safe',
                tone: safemate.isEmergencyActive
                    ? AppTone.danger
                    : AppTone.safe,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AppStatusChip(
                label: connection.label,
                tone: connection.tone,
                compact: true,
              ),
              AppStatusChip(
                label: _batteryLabel(safemate.batteryLevel),
                tone: _batteryTone(safemate.batteryLevel),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            updatedText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionBar extends StatelessWidget {
  const _MapActionBar({
    required this.onCall,
    required this.onMessage,
    required this.onViewAlert,
  });

  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onViewAlert;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onViewAlert,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Alert'),
            ),
          ),
        ],
      ),
    );
  }
}

UserProfile? _selectedSafemate(
  List<UserProfile> safemates,
  String? selectedId,
) {
  if (selectedId == null) {
    return safemates.isEmpty ? null : safemates.first;
  }
  for (final UserProfile user in safemates) {
    if (user.id == selectedId) {
      return user;
    }
  }
  return safemates.isEmpty ? null : safemates.first;
}

LatLng _fallbackCenter(List<GeofenceZone> zones) {
  if (zones.isNotEmpty) {
    final GeofenceZone zone = zones.first;
    return LatLng(zone.lat, zone.lng);
  }
  return const LatLng(6.9271, 79.8612);
}

_ConnectionState _connectionStateFor({
  required LiveLocation? liveLocation,
  required DateTime? lastLocationSyncAt,
}) {
  final DateTime? updatedAt = liveLocation?.updatedAt ?? lastLocationSyncAt;
  if (updatedAt == null) {
    return const _ConnectionState(label: 'Unavailable', tone: AppTone.neutral);
  }

  final Duration difference = DateTime.now().difference(updatedAt);
  if (difference.inSeconds <= 15) {
    return const _ConnectionState(label: 'Live', tone: AppTone.safe);
  }
  if (difference.inSeconds <= 60) {
    return const _ConnectionState(label: 'Delayed', tone: AppTone.warning);
  }
  return const _ConnectionState(label: 'Lost', tone: AppTone.danger);
}

String _batteryLabel(int? batteryLevel) {
  if (batteryLevel == null) {
    return 'Battery --';
  }
  return 'Battery $batteryLevel%';
}

AppTone _batteryTone(int? batteryLevel) {
  if (batteryLevel == null) {
    return AppTone.neutral;
  }
  if (batteryLevel <= 5) {
    return AppTone.danger;
  }
  if (batteryLevel <= 15) {
    return AppTone.warning;
  }
  return AppTone.neutral;
}

class _ConnectionState {
  const _ConnectionState({required this.label, required this.tone});

  final String label;
  final AppTone tone;
}
