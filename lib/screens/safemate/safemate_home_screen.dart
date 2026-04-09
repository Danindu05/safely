import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/alert_type_badge.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_stat_card.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Add the destination coordinates and Safely will watch the route quietly in the background.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
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
                        fontWeight: FontWeight.w600,
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
                  child: const Text('Start route'),
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
        builder:
            (
              BuildContext context,
              SafemateHomeViewModel viewModel,
              Widget? child,
            ) {
              final SafemateShellViewModel shellViewModel = context
                  .watch<SafemateShellViewModel>();
              final SafetyRuntimeState runtimeState = viewModel.runtimeState;
              final RouteTrackingSession? activeRoute =
                  shellViewModel.runtimeState.activeRouteTracking;
              final SafetyTimerState? activeSafetyTimer =
                  shellViewModel.runtimeState.safetyTimer;
              final String? errorMessage =
                  viewModel.errorMessage ?? shellViewModel.errorMessage;
              final String? infoMessage =
                  viewModel.infoMessage ?? shellViewModel.infoMessage;

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Safemate'),
                  actions: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Center(
                        child: AppStatusChip(
                          label: profile.lastLocationSyncAt == null
                              ? 'Idle'
                              : 'Synced',
                          tone: profile.lastLocationSyncAt == null
                              ? AppTone.neutral
                              : AppTone.safe,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  children: <Widget>[
                    _TopSummaryCard(
                      profile: profile,
                      batteryLevel: batteryLevel,
                      isOnline: isOnline,
                      runtimeState: runtimeState,
                      activeRoute: activeRoute,
                      activeSafetyTimer: activeSafetyTimer,
                    ),
                    if (errorMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      AppInfoBanner(
                        title: 'Something needs attention',
                        message: errorMessage,
                        icon: Icons.error_outline,
                        tone: AppTone.danger,
                      ),
                    ],
                    if (infoMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      AppInfoBanner(
                        title: 'Status update',
                        message: infoMessage,
                        icon: Icons.info_outline,
                        tone: AppTone.info,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SosHeroCard(
                      isBusy: viewModel.isBusy,
                      runtimeState: runtimeState,
                      onPressed: viewModel.triggerSos,
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Quick actions',
                      subtitle:
                          'The most useful actions stay close and easy to reach.',
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _QuickActionTile(
                                  icon: Icons.check_circle_outline,
                                  title: "I'm Safe",
                                  subtitle: 'Send a quick check-in',
                                  tone: AppTone.safe,
                                  onTap: () =>
                                      viewModel.sendCheckIn(batteryLevel),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionTile(
                                  icon: runtimeState.isLiveSharingActive
                                      ? Icons.location_off_outlined
                                      : Icons.share_location_outlined,
                                  title: runtimeState.isLiveSharingActive
                                      ? 'Stop live'
                                      : 'Start live',
                                  subtitle: runtimeState.isLiveSharingActive
                                      ? 'End current sharing session'
                                      : 'Share your live location',
                                  tone: runtimeState.isLiveSharingActive
                                      ? AppTone.warning
                                      : AppTone.info,
                                  onTap: viewModel.toggleManualLiveSharing,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _QuickActionTile(
                                  icon: Icons.timer_outlined,
                                  title: activeSafetyTimer == null
                                      ? 'Safety timer'
                                      : _formatDuration(
                                          activeSafetyTimer.remainingAt(
                                            DateTime.now(),
                                          ),
                                        ),
                                  subtitle: activeSafetyTimer == null
                                      ? 'Start a quiet countdown'
                                      : 'Tap to manage active timer',
                                  tone: activeSafetyTimer == null
                                      ? AppTone.neutral
                                      : AppTone.warning,
                                  onTap: () => _showSafetyTimerSheet(
                                    context,
                                    shellViewModel,
                                    activeSafetyTimer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionTile(
                                  icon: Icons.alt_route,
                                  title: activeRoute == null
                                      ? 'Route watch'
                                      : 'Journey active',
                                  subtitle: activeRoute == null
                                      ? 'Track your journey'
                                      : activeRoute.routeSource == 'osrm'
                                      ? 'Navigation-aware route'
                                      : 'Straight-line fallback',
                                  tone: activeRoute == null
                                      ? AppTone.neutral
                                      : activeRoute.deviationAlertSent
                                      ? AppTone.danger
                                      : AppTone.info,
                                  onTap: () async {
                                    if (activeRoute != null) {
                                      await shellViewModel.stopRouteTracking();
                                      return;
                                    }
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
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SafetyToolsCard(
                      runtimeState: runtimeState,
                      shellViewModel: shellViewModel,
                      activeRoute: activeRoute,
                      activeSafetyTimer: activeSafetyTimer,
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.latestAlert == null)
                      const EmptyStateCard(
                        icon: Icons.notifications_none,
                        title: 'No recent alerts',
                        message:
                            'SOS, battery, route, geofence, and check-in activity will appear here when something needs your attention.',
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

  Future<void> _showSafetyTimerSheet(
    BuildContext context,
    SafemateShellViewModel shellViewModel,
    SafetyTimerState? activeSafetyTimer,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Safety timer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  activeSafetyTimer == null
                      ? 'If the timer expires without a cancel, Safely will start SOS for you.'
                      : 'Current countdown: ${_formatDuration(activeSafetyTimer.remainingAt(DateTime.now()))}',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: activeSafetyTimer != null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              shellViewModel.startSafetyTimer(
                                const Duration(minutes: 15),
                              );
                            },
                      child: const Text('15 min'),
                    ),
                    OutlinedButton(
                      onPressed: activeSafetyTimer != null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              shellViewModel.startSafetyTimer(
                                const Duration(minutes: 30),
                              );
                            },
                      child: const Text('30 min'),
                    ),
                    OutlinedButton(
                      onPressed: activeSafetyTimer != null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              shellViewModel.startSafetyTimer(
                                const Duration(hours: 1),
                              );
                            },
                      child: const Text('1 hour'),
                    ),
                  ],
                ),
                if (activeSafetyTimer != null) ...<Widget>[
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      shellViewModel.cancelSafetyTimer();
                    },
                    icon: const Icon(Icons.timer_off_outlined),
                    label: const Text('Cancel timer'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  const _TopSummaryCard({
    required this.profile,
    required this.batteryLevel,
    required this.isOnline,
    required this.runtimeState,
    required this.activeRoute,
    required this.activeSafetyTimer,
  });

  final UserProfile profile;
  final int? batteryLevel;
  final bool isOnline;
  final SafetyRuntimeState runtimeState;
  final RouteTrackingSession? activeRoute;
  final SafetyTimerState? activeSafetyTimer;

  @override
  Widget build(BuildContext context) {
    final SafetyTimerState? timer = activeSafetyTimer;
    final RouteTrackingSession? route = activeRoute;
    final _StatusPresentation status = _statusPresentation(
      profile: profile,
      runtimeState: runtimeState,
      activeRoute: activeRoute,
      activeSafetyTimer: activeSafetyTimer,
    );
    final List<Widget> chips = <Widget>[
      if (runtimeState.isTrustedPlaceActive)
        const AppStatusChip(
          label: 'Trusted place',
          tone: AppTone.safe,
          compact: true,
        ),
      if (runtimeState.isNightMonitoringActive)
        const AppStatusChip(
          label: 'Night monitoring',
          tone: AppTone.warning,
          compact: true,
        ),
      if (runtimeState.isLiveSharingActive)
        const AppStatusChip(
          label: 'Live sharing',
          tone: AppTone.info,
          compact: true,
        ),
      if (runtimeState.isRecordingActive)
        const AppStatusChip(
          label: 'Recording',
          tone: AppTone.danger,
          compact: true,
        ),
      if (runtimeState.isAudioUploading)
        const AppStatusChip(
          label: 'Uploading audio',
          tone: AppTone.warning,
          compact: true,
        ),
      if (timer != null)
        AppStatusChip(
          label: 'Timer ${_formatDuration(timer.remainingAt(DateTime.now()))}',
          tone: AppTone.warning,
          compact: true,
        ),
      if (route != null)
        AppStatusChip(
          label: route.deviationAlertSent ? 'Deviation shared' : 'Route active',
          tone: route.deviationAlertSent ? AppTone.danger : AppTone.info,
          compact: true,
        ),
    ];

    return SectionCard(
      backgroundColor: status.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSectionHeader(
            title: 'Current safety status',
            subtitle: status.message,
            trailing: AppStatusChip(
              label: status.label,
              tone: status.tone,
              icon: status.icon,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              AppStatCard(
                label: 'Battery',
                value: '${batteryLevel ?? '--'}%',
                icon: Icons.battery_5_bar_rounded,
                tone: _batteryTone(batteryLevel),
                expanded: true,
              ),
              const SizedBox(width: 12),
              AppStatCard(
                label: 'Guardians',
                value: '${profile.guardianIds.length}',
                icon: Icons.groups_2_outlined,
                tone: profile.guardianIds.isEmpty
                    ? AppTone.warning
                    : AppTone.info,
                expanded: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              AppStatCard(
                label: 'Live status',
                value: isOnline ? 'Connected' : 'Offline',
                icon: isOnline ? Icons.wifi_tethering : Icons.wifi_off,
                tone: isOnline ? AppTone.safe : AppTone.warning,
                helper: profile.lastSeenAt == null
                    ? 'No recent heartbeat'
                    : 'Seen ${DateTimeFormatter.formatRelative(profile.lastSeenAt!)}',
                expanded: true,
              ),
              const SizedBox(width: 12),
              AppStatCard(
                label: 'Last sync',
                value: profile.lastLocationSyncAt == null
                    ? 'Waiting'
                    : DateTimeFormatter.formatRelative(
                        profile.lastLocationSyncAt!,
                      ),
                icon: Icons.location_on_outlined,
                tone: profile.lastLocationSyncAt == null
                    ? AppTone.neutral
                    : AppTone.info,
                helper: profile.lastLocationSyncAt == null
                    ? 'Location has not synced yet'
                    : DateTimeFormatter.formatShort(
                        profile.lastLocationSyncAt!,
                      ),
                expanded: true,
              ),
            ],
          ),
          if (chips.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );
  }
}

class _SosHeroCard extends StatelessWidget {
  const _SosHeroCard({
    required this.isBusy,
    required this.runtimeState,
    required this.onPressed,
  });

  final bool isBusy;
  final SafetyRuntimeState runtimeState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool showRecordingState =
        runtimeState.isRecordingActive ||
        runtimeState.isAudioUploading ||
        runtimeState.audioUploadError != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF4F4), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.emergency.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: <Widget>[
          AppSectionHeader(
            title: 'Emergency SOS',
            subtitle:
                'One tap alerts guardians, starts live sharing, and keeps emergency evidence together.',
            trailing: const AppStatusChip(
              label: 'Emergency action',
              tone: AppTone.danger,
              compact: true,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: AppConstants.sosButtonSize,
              height: AppConstants.sosButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFE45858), Color(0xFFD63D3D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.emergency.withValues(alpha: 0.26),
                    blurRadius: 40,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: isBusy ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.sos_rounded, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      isBusy ? 'Sending...' : 'SOS',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Use this when you need help right now.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRecordingState) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                if (runtimeState.isRecordingActive)
                  const AppStatusChip(
                    label: 'Recording active',
                    tone: AppTone.danger,
                    compact: true,
                  ),
                if (runtimeState.isAudioUploading)
                  const AppStatusChip(
                    label: 'Uploading audio',
                    tone: AppTone.warning,
                    compact: true,
                  ),
                if (runtimeState.audioUploadError != null)
                  const AppStatusChip(
                    label: 'Audio upload failed',
                    tone: AppTone.warning,
                    compact: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyToolsCard extends StatelessWidget {
  const _SafetyToolsCard({
    required this.runtimeState,
    required this.shellViewModel,
    required this.activeRoute,
    required this.activeSafetyTimer,
  });

  final SafetyRuntimeState runtimeState;
  final SafemateShellViewModel shellViewModel;
  final RouteTrackingSession? activeRoute;
  final SafetyTimerState? activeSafetyTimer;

  @override
  Widget build(BuildContext context) {
    final RouteTrackingSession? route = activeRoute;
    final SafetyTimerState? timer = activeSafetyTimer;
    return SectionCard(
      title: 'Monitoring details',
      subtitle:
          'These tools add quiet protection around your routine without getting in the way.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (route != null) ...<Widget>[
            _DetailRow(
              icon: Icons.alt_route,
              title: 'Journey monitoring',
              subtitle:
                  'Destination ${route.destinationLat.toStringAsFixed(5)}, ${route.destinationLng.toStringAsFixed(5)} • threshold ${route.deviationThresholdMeters.toStringAsFixed(0)}m',
            ),
            const SizedBox(height: 12),
            _RoutePreviewMap(
              session: route,
              currentPosition: runtimeState.currentRoutePosition,
            ),
            const SizedBox(height: 14),
          ],
          _DetailRow(
            icon: Icons.timer_outlined,
            title: 'Safety timer',
            subtitle: timer == null
                ? 'No active timer. Start one when you want an automatic safety backstop.'
                : 'Timer ends in ${_formatDuration(timer.remainingAt(DateTime.now()))}.',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.watch_later_outlined,
            title: 'Next check-in',
            subtitle: shellViewModel.nextCheckInDueAt == null
                ? 'No timed check-in is scheduled right now.'
                : DateTimeFormatter.formatShort(
                    shellViewModel.nextCheckInDueAt!,
                  ),
          ),
        ],
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AlertTypeBadge(type: alert.type, compact: true),
              AppStatusChip(
                label: alert.status.label,
                tone: _toneForAlertStatus(alert.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            alert.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTonePalette.background(tone),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTonePalette.foreground(tone)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
        height: 230,
        child: Stack(
          children: <Widget>[
            SafelyMap(
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
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  session.routeSource == 'osrm'
                      ? 'Road-aware route'
                      : 'Straight-line route',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                  ),
                ),
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

_StatusPresentation _statusPresentation({
  required UserProfile profile,
  required SafetyRuntimeState runtimeState,
  required RouteTrackingSession? activeRoute,
  required SafetyTimerState? activeSafetyTimer,
}) {
  if (profile.isEmergencyActive) {
    return const _StatusPresentation(
      label: 'Emergency active',
      message:
          'Guardians have been alerted and live emergency systems are active.',
      tone: AppTone.danger,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Color(0xFFFFF4F4),
    );
  }
  if (runtimeState.isLiveSharingActive) {
    return const _StatusPresentation(
      label: 'Monitoring',
      message: 'Live sharing is on and Safely is watching quietly.',
      tone: AppTone.info,
      icon: Icons.share_location_rounded,
      backgroundColor: Colors.white,
    );
  }
  if (activeSafetyTimer != null) {
    return const _StatusPresentation(
      label: 'Timer active',
      message: 'A safety timer is running and will escalate if not canceled.',
      tone: AppTone.warning,
      icon: Icons.timer_outlined,
      backgroundColor: Colors.white,
    );
  }
  if (activeRoute != null) {
    return const _StatusPresentation(
      label: 'Journey active',
      message: 'Route tracking is active and watching for major deviations.',
      tone: AppTone.info,
      icon: Icons.alt_route,
      backgroundColor: Colors.white,
    );
  }
  if (runtimeState.isTrustedPlaceActive) {
    return const _StatusPresentation(
      label: 'Trusted place',
      message: 'You are inside a safe zone and Safely is staying light-touch.',
      tone: AppTone.safe,
      icon: Icons.home_work_outlined,
      backgroundColor: Color(0xFFF7FCFA),
    );
  }
  if (runtimeState.isNightMonitoringActive) {
    return const _StatusPresentation(
      label: 'Night monitoring',
      message: 'Overnight watch is enabled and ready if you go quiet.',
      tone: AppTone.warning,
      icon: Icons.dark_mode_outlined,
      backgroundColor: Colors.white,
    );
  }
  return const _StatusPresentation(
    label: 'Safe',
    message: 'Everything looks calm right now. Your guardians stay ready.',
    tone: AppTone.safe,
    icon: Icons.verified_user_outlined,
    backgroundColor: Color(0xFFF7FCFA),
  );
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

AppTone _toneForAlertStatus(AlertStatus status) {
  return switch (status) {
    AlertStatus.active => AppTone.danger,
    AlertStatus.acknowledged => AppTone.info,
    AlertStatus.canceled => AppTone.neutral,
    AlertStatus.resolved => AppTone.safe,
  };
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.message,
    required this.tone,
    required this.icon,
    required this.backgroundColor,
  });

  final String label;
  final String message;
  final AppTone tone;
  final IconData icon;
  final Color backgroundColor;
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
