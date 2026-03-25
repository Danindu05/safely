import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../models/geofence_zone.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/guardian_live_map_viewmodel.dart';

class GuardianLiveMapScreen extends StatelessWidget {
  const GuardianLiveMapScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardianLiveMapViewModel>(
      create: (_) => GuardianLiveMapViewModel(
        profileRepository: context.read<ProfileRepository>(),
        locationRepository: context.read<LocationRepository>(),
        guardianId: guardianId,
      ),
      child: const _GuardianLiveMapScreenBody(),
    );
  }
}

class _GuardianLiveMapScreenBody extends StatelessWidget {
  const _GuardianLiveMapScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<GuardianLiveMapViewModel>(
      builder:
          (
            BuildContext context,
            GuardianLiveMapViewModel viewModel,
            Widget? child,
          ) {
            final liveLocation = viewModel.liveLocation;
            final List<CircleMarker> geofenceCircles = viewModel.geofenceZones
                .map(
                  (GeofenceZone zone) => CircleMarker(
                    point: LatLng(zone.lat, zone.lng),
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: zone.type == GeofenceType.unsafe
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.12),
                    borderColor: zone.type == GeofenceType.unsafe
                        ? Colors.red
                        : Colors.green,
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
                        ? Colors.red
                        : Colors.green,
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
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
            ];

            return Scaffold(
              appBar: AppBar(title: const Text('Guardian live map')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  if (viewModel.safemates.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: viewModel.selectedSafemateId,
                      items: viewModel.safemates
                          .map(
                            (user) => DropdownMenuItem<String>(
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
                    ),
                  const SizedBox(height: 16),
                  if (liveLocation == null)
                    const EmptyStateCard(
                      icon: Icons.location_disabled_outlined,
                      title: 'No live location yet',
                      message:
                          'Live locations appear here during emergency or manual live sharing sessions.',
                    )
                  else ...<Widget>[
                    SizedBox(
                      height: 340,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.cardRadius,
                        ),
                        child: SafelyMap(
                          center: LatLng(liveLocation.lat, liveLocation.lng),
                          zoom: 15,
                          markers: markers,
                          circles: geofenceCircles,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Live session status',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Source: ${liveLocation.source}'),
                          const SizedBox(height: 6),
                          Text(
                            'Emergency active: ${liveLocation.isEmergencyActive ? 'Yes' : 'No'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }
}
