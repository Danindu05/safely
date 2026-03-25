import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../models/geofence_zone.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/geofence_setup_viewmodel.dart';

class GeofenceSetupScreen extends StatelessWidget {
  const GeofenceSetupScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GeofenceSetupViewModel>(
      create: (_) => GeofenceSetupViewModel(
        profileRepository: context.read<ProfileRepository>(),
        locationRepository: context.read<LocationRepository>(),
        userId: userId,
      ),
      child: const _GeofenceSetupScreenBody(),
    );
  }
}

class _GeofenceSetupScreenBody extends StatefulWidget {
  const _GeofenceSetupScreenBody();

  @override
  State<_GeofenceSetupScreenBody> createState() =>
      _GeofenceSetupScreenBodyState();
}

class _GeofenceSetupScreenBodyState extends State<_GeofenceSetupScreenBody> {
  LatLng _initialPosition = const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final (double lat, double lng) = await context
          .read<GeofenceSetupViewModel>()
          .loadInitialPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _initialPosition = LatLng(lat, lng);
      });
    });
  }

  Future<void> _showAddZoneDialog(BuildContext context, LatLng point) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController radiusController = TextEditingController(
      text: '120',
    );
    GeofenceType selectedType = GeofenceType.unsafe;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add zone'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Zone name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GeofenceType>(
                    initialValue: selectedType,
                    items: GeofenceType.values
                        .map(
                          (GeofenceType type) => DropdownMenuItem<GeofenceType>(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (GeofenceType? value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Radius meters',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final double radius =
                    double.tryParse(radiusController.text.trim()) ?? 120;
                await context.read<GeofenceSetupViewModel>().addZone(
                  name: nameController.text.trim(),
                  type: selectedType,
                  lat: point.latitude,
                  lng: point.longitude,
                  radiusMeters: radius,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeofenceSetupViewModel>(
      builder:
          (
            BuildContext context,
            GeofenceSetupViewModel viewModel,
            Widget? child,
          ) {
            final List<Marker> markers = viewModel.config.zones
                .map(
                  (GeofenceZone zone) => Marker(
                    point: LatLng(zone.lat, zone.lng),
                    width: 56,
                    height: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          zone.type == GeofenceType.unsafe
                              ? Icons.gpp_bad_outlined
                              : Icons.home_work_outlined,
                          color: zone.type == GeofenceType.unsafe
                              ? Colors.red
                              : Colors.green,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            zone.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false);
            final List<CircleMarker> circles = viewModel.config.zones
                .map(
                  (GeofenceZone zone) => CircleMarker(
                    point: LatLng(zone.lat, zone.lng),
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: zone.type == GeofenceType.unsafe
                        ? Colors.red.withValues(alpha: 0.18)
                        : Colors.green.withValues(alpha: 0.18),
                    borderColor: zone.type == GeofenceType.unsafe
                        ? Colors.red
                        : Colors.green,
                    borderStrokeWidth: 2,
                  ),
                )
                .toList(growable: false);

            return Scaffold(
              appBar: AppBar(title: const Text('Geofence setup')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      child: SafelyMap(
                        center: _initialPosition,
                        zoom: 14,
                        markers: markers,
                        circles: circles,
                        onLongPress: (LatLng point) =>
                            _showAddZoneDialog(context, point),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Saved zones',
                    subtitle:
                        'Long press the map to create a safe or unsafe zone.',
                    child: Column(
                      children: viewModel.config.zones.isEmpty
                          ? const <Widget>[Text('No zones saved yet.')]
                          : viewModel.config.zones
                                .map(
                                  (GeofenceZone zone) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(zone.name),
                                    subtitle: Text(
                                      '${zone.type.label} • ${zone.radiusMeters.toStringAsFixed(0)}m',
                                    ),
                                    leading: Switch(
                                      value: zone.isEnabled,
                                      onChanged: (_) =>
                                          viewModel.toggleZone(zone),
                                    ),
                                    trailing: IconButton(
                                      onPressed: () =>
                                          viewModel.removeZone(zone.id),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
