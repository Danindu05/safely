import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/alert_detail_viewmodel.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.alertId,
    required this.guardianId,
  });

  final String alertId;
  final String guardianId;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _callContact(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlertDetailViewModel>(
      create: (_) => AlertDetailViewModel(
        alertRepository: context.read<AlertRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        alertId: widget.alertId,
        guardianId: widget.guardianId,
      ),
      child: Consumer<AlertDetailViewModel>(
        builder:
            (
              BuildContext context,
              AlertDetailViewModel viewModel,
              Widget? child,
            ) {
              final alert = viewModel.alert;
              final profile = viewModel.profile;
              final medical = viewModel.medicalProfile;

              return Scaffold(
                appBar: AppBar(title: const Text('Alert detail')),
                body: ListView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  children: <Widget>[
                    if (alert != null)
                      SectionCard(
                        title: alert.title,
                        subtitle: DateTimeFormatter.formatShort(
                          alert.timestamp,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(alert.description),
                            const SizedBox(height: 8),
                            Text('Status: ${alert.status.label}'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (profile != null)
                      SectionCard(
                        title: profile.name,
                        subtitle: profile.email,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Battery: ${profile.batteryLevel ?? '--'}%'),
                            const SizedBox(height: 6),
                            Text(
                              'Emergency contact: ${profile.emergencyContactName}',
                            ),
                            const SizedBox(height: 6),
                            Text(profile.emergencyContactPhone),
                          ],
                        ),
                      ),
                    if (medical != null) ...<Widget>[
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Medical info',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Blood group: ${medical.bloodGroup}'),
                            const SizedBox(height: 6),
                            Text('Allergies: ${medical.allergies}'),
                            const SizedBox(height: 6),
                            Text('Conditions: ${medical.medicalConditions}'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (alert?.locationLat != null &&
                        alert?.locationLng != null)
                      SectionCard(
                        title: 'Location',
                        child: SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius - 8,
                            ),
                            child: SafelyMap(
                              center: LatLng(
                                alert!.locationLat!,
                                alert.locationLng!,
                              ),
                              zoom: 15,
                              markers: <Marker>[
                                Marker(
                                  point: LatLng(
                                    alert.locationLat!,
                                    alert.locationLng!,
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.place,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (alert?.locationLat != null &&
                        alert?.locationLng != null)
                      const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                (profile?.emergencyContactPhone ?? '').isEmpty
                                ? null
                                : () => _callContact(
                                    profile!.emergencyContactPhone,
                                  ),
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Messaging handoff is prepared for a later step.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.message_outlined),
                            label: const Text('Message'),
                          ),
                        ),
                      ],
                    ),
                    if ((alert?.audioUrl ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _audioPlayer.play(UrlSource(alert!.audioUrl!)),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play emergency audio'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    PrimaryActionButton(
                      label: 'I am handling this',
                      icon: Icons.task_alt,
                      onPressed: viewModel.acknowledgeHandling,
                    ),
                  ],
                ),
              );
            },
      ),
    );
  }
}
