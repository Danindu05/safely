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
import '../../core/widgets/app_action_button.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_title.dart';
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
        builder:
            (
              BuildContext context,
              AlertDetailViewModel viewModel,
              Widget? child,
            ) {
              final alert = viewModel.alert;
              final profile = viewModel.profile;
              final medical = viewModel.medicalProfile;
              final bool isHandling =
                  alert?.acknowledgedBy == widget.guardianId ||
                  alert?.status == AlertStatus.acknowledged;
              final String phone = profile?.emergencyContactPhone ?? '';

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
                      InfoCard(
                        backgroundColor:
                            alert.status == AlertStatus.active ||
                                (profile?.isEmergencyActive ?? false)
                            ? AppColors.emergencySoft
                            : Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                AlertTypeBadge(type: alert.type, compact: true),
                                AppStatusChip(
                                  label: alert.status.label,
                                  tone: _toneForStatus(alert.status),
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              alert.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              DateTimeFormatter.formatShort(alert.timestamp),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    if (alert?.locationLat != null &&
                        alert?.locationLng != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(title: 'Location'),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.cardRadius - 4,
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
                          ],
                        ),
                      ),
                    ],
                    if (alert != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(title: 'Actions'),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: AppActionButton(
                                    onPressed: phone.trim().isEmpty
                                        ? null
                                        : () => _callContact(phone),
                                    icon: Icons.call_outlined,
                                    label: 'Call',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppActionButton(
                                    onPressed: phone.trim().isEmpty
                                        ? null
                                        : () => _messageContact(context, phone),
                                    icon: Icons.message_outlined,
                                    label: 'Message',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
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
                    if (medical != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              'Medical information',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              'Tap to expand',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            children: <Widget>[
                              const SizedBox(height: 12),
                              _MedicalRow(
                                label: 'Blood group',
                                value: medical.bloodGroup,
                              ),
                              _MedicalRow(
                                label: 'Allergies',
                                value: medical.allergies,
                              ),
                              _MedicalRow(
                                label: 'Conditions',
                                value: medical.medicalConditions,
                              ),
                              _MedicalRow(
                                label: 'Notes',
                                value: medical.emergencyNotes,
                              ),
                              _MedicalRow(
                                label: 'Emergency contact',
                                value: medical.emergencyContactPhone,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if ((alert?.audioUrl ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SectionTitle(title: 'Audio'),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: _playerState == PlayerState.playing
                                  ? 'Pause'
                                  : 'Play',
                              icon: _playerState == PlayerState.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              onPressed: () =>
                                  _toggleAudioPlayback(alert!.audioUrl!),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _audioDuration == Duration.zero
                                  ? 'Preparing audio...'
                                  : '${_formatAudioDuration(_audioPosition)} / ${_formatAudioDuration(_audioDuration)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
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
                    if (viewModel.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Text(
                          viewModel.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.emergency,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                    if (viewModel.infoMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Text(
                          viewModel.infoMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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

class _MedicalRow extends StatelessWidget {
  const _MedicalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String display = value.trim().isEmpty ? 'Not added' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(display, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

AppTone _toneForStatus(AlertStatus status) {
  return switch (status) {
    AlertStatus.active => AppTone.danger,
    AlertStatus.acknowledged => AppTone.info,
    AlertStatus.canceled => AppTone.neutral,
    AlertStatus.resolved => AppTone.safe,
  };
}

String _formatAudioDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
