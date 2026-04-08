import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
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
    final Uri uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  Future<void> _messageContact(BuildContext context, String phone) async {
    final Uri uri = Uri.parse('sms:$phone');
    final bool launched = await launchUrl(uri);
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
              alert?.status.name == 'acknowledged';

          return Scaffold(
            appBar: AppBar(title: const Text('Alert detail')),
            body: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: <Widget>[
                if (alert != null)
                  SectionCard(
                    title: alert.title,
                    subtitle: DateTimeFormatter.formatShort(alert.timestamp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(alert.description),
                        const SizedBox(height: 8),
                        Text('Status: ${alert.status.label}'),
                        if (alert.acknowledgedAt != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.safe.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              alert.acknowledgedBy == widget.guardianId
                                  ? 'You marked this as handled at ${DateTimeFormatter.formatShort(alert.acknowledgedAt!)}.'
                                  : 'A guardian marked this as handled at ${DateTimeFormatter.formatShort(alert.acknowledgedAt!)}.',
                            ),
                          ),
                        ],
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
                if (alert?.locationLat != null && alert?.locationLng != null)
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
                if (alert?.locationLat != null && alert?.locationLng != null)
                  const SizedBox(height: 16),
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
                if ((alert?.audioUrl ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Emergency audio',
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
                            Text(
                              _audioDuration == Duration.zero
                                  ? 'Loading duration...'
                                  : '${_formatAudioDuration(_audioPosition)} / ${_formatAudioDuration(_audioDuration)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (viewModel.infoMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(viewModel.infoMessage!),
                ],
                const SizedBox(height: 16),
                PrimaryActionButton(
                  label: isHandling
                      ? "You're handling this"
                      : 'I am handling this',
                  icon: isHandling ? Icons.task_alt : Icons.task_alt,
                  onPressed: isHandling ? null : viewModel.acknowledgeHandling,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatAudioDuration(Duration duration) {
  final int minutes = duration.inMinutes;
  final int seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
