import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/alert_type_badge.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_stat_card.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/emergency_header_card.dart';
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
  final List<StreamSubscription<dynamic>> _audioSubscriptions =
      <StreamSubscription<dynamic>>[];

  PlayerState _playerState = PlayerState.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String? _loadedAudioUrl;

  @override
  void initState() {
    super.initState();
    _audioSubscriptions.addAll(<StreamSubscription<dynamic>>[
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _playerState = state;
        });
      }),
      _audioPlayer.onDurationChanged.listen((Duration duration) {
        if (!mounted) {
          return;
        }
        setState(() {
          _audioDuration = duration;
        });
      }),
      _audioPlayer.onPositionChanged.listen((Duration position) {
        if (!mounted) {
          return;
        }
        setState(() {
          _audioPosition = position;
        });
      }),
    ]);
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> subscription
        in _audioSubscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

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

  Future<void> _toggleAudioPlayback(String url) async {
    if (_loadedAudioUrl != url) {
      _loadedAudioUrl = url;
      setState(() {
        _audioDuration = Duration.zero;
        _audioPosition = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(url));
      return;
    }

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      return;
    }

    if (_audioDuration > Duration.zero && _audioPosition >= _audioDuration) {
      await _audioPlayer.seek(Duration.zero);
    }
    await _audioPlayer.resume();
  }

  Future<void> _seekAudio(double milliseconds) async {
    await _audioPlayer.seek(Duration(milliseconds: milliseconds.round()));
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
        builder: (BuildContext context, AlertDetailViewModel viewModel, Widget? child) {
          final alert = viewModel.alert;
          final profile = viewModel.profile;
          final medical = viewModel.medicalProfile;
          final String phone = profile?.emergencyContactPhone ?? '';
          final bool isHandling =
              alert?.acknowledgedBy == widget.guardianId ||
              alert?.status == AlertStatus.acknowledged;

          if (alert == null && viewModel.errorMessage == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Alert detail')),
            body: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: <Widget>[
                if (alert != null)
                  EmergencyHeaderCard(
                    title: alert.title,
                    subtitle:
                        '${profile?.name ?? 'Safemate'} • ${DateTimeFormatter.formatShort(alert.timestamp)}',
                    badge: AlertTypeBadge(type: alert.type),
                    statusLabel: alert.status.label,
                    statusTone: _toneForAlertStatus(alert.status),
                    isEmergency:
                        alert.status == AlertStatus.active ||
                        (profile?.isEmergencyActive ?? false),
                    trailing:
                        (alert.status == AlertStatus.active ||
                            (profile?.isEmergencyActive ?? false))
                        ? const AppStatusChip(
                            label: 'Emergency',
                            tone: AppTone.danger,
                            compact: true,
                          )
                        : null,
                  ),
                if (alert != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      AppStatCard(
                        label: 'Battery',
                        value: alert.batteryLevel == null
                            ? '--'
                            : '${alert.batteryLevel}%',
                        icon: Icons.battery_5_bar_rounded,
                        tone: _batteryTone(alert.batteryLevel),
                        expanded: true,
                      ),
                      const SizedBox(width: 12),
                      AppStatCard(
                        label: 'Location',
                        value:
                            alert.locationLat == null ||
                                alert.locationLng == null
                            ? 'Unavailable'
                            : 'Shared',
                        icon: Icons.location_on_outlined,
                        tone:
                            alert.locationLat == null ||
                                alert.locationLng == null
                            ? AppTone.neutral
                            : AppTone.info,
                        helper:
                            alert.locationLat == null ||
                                alert.locationLng == null
                            ? 'No coordinates were attached'
                            : '${alert.locationLat!.toStringAsFixed(5)}, ${alert.locationLng!.toStringAsFixed(5)}',
                        expanded: true,
                      ),
                      const SizedBox(width: 12),
                      AppStatCard(
                        label: 'Response',
                        value: isHandling ? 'Handled' : alert.status.label,
                        icon: isHandling
                            ? Icons.task_alt
                            : Icons.priority_high_rounded,
                        tone: isHandling
                            ? AppTone.info
                            : _toneForAlertStatus(alert.status),
                        helper: _alertContextLabel(alert.type),
                        expanded: true,
                      ),
                    ],
                  ),
                ],
                if (profile != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Safemate',
                    subtitle: profile.email,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _InfoValue(
                                label: 'Name',
                                value: profile.name,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoValue(
                                label: 'Emergency contact',
                                value: profile.emergencyContactName.isEmpty
                                    ? 'Not added'
                                    : profile.emergencyContactName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoValue(
                          label: 'Contact number',
                          value: phone.isEmpty ? 'Not added' : phone,
                        ),
                      ],
                    ),
                  ),
                ],
                if (alert != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Response actions',
                    subtitle:
                        'Use the fastest path to reach the Safemate or coordinate with others.',
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: phone.isEmpty
                                    ? null
                                    : () => _callContact(phone),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Call'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: phone.isEmpty
                                    ? null
                                    : () => _messageContact(context, phone),
                                icon: const Icon(Icons.message_outlined),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryActionButton(
                          label: isHandling
                              ? "You're handling this"
                              : 'I am handling this',
                          icon: Icons.task_alt,
                          onPressed: isHandling
                              ? null
                              : viewModel.acknowledgeHandling,
                        ),
                      ],
                    ),
                  ),
                ],
                if (alert?.locationLat != null &&
                    alert?.locationLng != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Location',
                    subtitle: 'Shared with this alert',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 240,
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
                                    color: AppColors.emergency,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Coordinates: ${alert.locationLat!.toStringAsFixed(5)}, ${alert.locationLng!.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (medical != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Medical information',
                    subtitle:
                        'Key emergency details Guardians may need quickly.',
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _InfoValue(
                                label: 'Blood group',
                                value: medical.bloodGroup.isEmpty
                                    ? 'Not added'
                                    : medical.bloodGroup,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoValue(
                                label: 'Emergency contact',
                                value: medical.emergencyContactName.isEmpty
                                    ? 'Not added'
                                    : medical.emergencyContactName,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoValue(
                          label: 'Allergies',
                          value: medical.allergies.isEmpty
                              ? 'No allergies listed'
                              : medical.allergies,
                        ),
                        const SizedBox(height: 12),
                        _InfoValue(
                          label: 'Medical conditions',
                          value: medical.medicalConditions.isEmpty
                              ? 'No conditions listed'
                              : medical.medicalConditions,
                        ),
                        const SizedBox(height: 12),
                        _InfoValue(
                          label: 'Emergency notes',
                          value: medical.emergencyNotes.isEmpty
                              ? 'No emergency notes'
                              : medical.emergencyNotes,
                        ),
                      ],
                    ),
                  ),
                ],
                if ((alert?.audioUrl ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Emergency audio',
                    subtitle: _audioDuration == Duration.zero
                        ? 'Preparing playback'
                        : 'Ready to review',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  _toggleAudioPlayback(alert!.audioUrl!),
                              icon: Icon(
                                _playerState == PlayerState.playing
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                _playerState == PlayerState.playing
                                    ? 'Pause'
                                    : 'Play',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _audioDuration == Duration.zero
                                    ? 'Loading duration...'
                                    : '${_formatAudioDuration(_audioPosition)} / ${_formatAudioDuration(_audioDuration)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Slider(
                          value: _audioDuration.inMilliseconds == 0
                              ? 0
                              : _audioPosition.inMilliseconds
                                    .clamp(0, _audioDuration.inMilliseconds)
                                    .toDouble(),
                          max: _audioDuration.inMilliseconds == 0
                              ? 1
                              : _audioDuration.inMilliseconds.toDouble(),
                          onChanged: _audioDuration.inMilliseconds == 0
                              ? null
                              : _seekAudio,
                        ),
                      ],
                    ),
                  ),
                ],
                if (alert != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Timeline',
                    subtitle: 'How this alert has progressed so far',
                    child: Column(
                      children: <Widget>[
                        _TimelineInfoRow(
                          icon: Icons.fiber_manual_record,
                          title: 'Created',
                          value: DateTimeFormatter.formatShort(alert.timestamp),
                        ),
                        if (alert.acknowledgedAt != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _TimelineInfoRow(
                            icon: Icons.task_alt,
                            title: 'Acknowledged',
                            value:
                                '${DateTimeFormatter.formatShort(alert.acknowledgedAt!)}${alert.acknowledgedBy == widget.guardianId ? ' by you' : ''}',
                          ),
                        ],
                        if (alert.resolvedAt != null) ...<Widget>[
                          const SizedBox(height: 12),
                          _TimelineInfoRow(
                            icon: alert.canceledByUser
                                ? Icons.undo
                                : Icons.check_circle_outline,
                            title: alert.canceledByUser
                                ? 'Canceled'
                                : 'Resolved',
                            value: DateTimeFormatter.formatShort(
                              alert.resolvedAt!,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (viewModel.errorMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AppInfoBanner(
                    title: 'Alert detail status',
                    message: viewModel.errorMessage!,
                    icon: Icons.error_outline,
                    tone: AppTone.danger,
                  ),
                ],
                if (viewModel.infoMessage != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AppInfoBanner(
                    title: 'Alert detail update',
                    message: viewModel.infoMessage!,
                    icon: Icons.info_outline,
                    tone: AppTone.info,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoValue extends StatelessWidget {
  const _InfoValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TimelineInfoRow extends StatelessWidget {
  const _TimelineInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

AppTone _toneForAlertStatus(AlertStatus status) {
  return switch (status) {
    AlertStatus.active => AppTone.danger,
    AlertStatus.acknowledged => AppTone.info,
    AlertStatus.canceled => AppTone.neutral,
    AlertStatus.resolved => AppTone.safe,
  };
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
  return AppTone.safe;
}

String _alertContextLabel(AlertType type) {
  return switch (type) {
    AlertType.sos => 'Immediate emergency',
    AlertType.lowBattery => 'Battery concern',
    AlertType.geofence => 'Zone-based alert',
    AlertType.missedCheckin => 'No response',
    AlertType.manualCheckin => 'Check-in update',
    AlertType.routeDeviation => 'Route concern',
  };
}

String _formatAudioDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
