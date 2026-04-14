import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/emergency_button.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/safely_map.dart';
import '../../core/widgets/section_title.dart';
import '../../models/route_tracking_session.dart';
import '../../models/safety_timer_state.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/location_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SafemateHomeViewModel>(
      create: (_) => SafemateHomeViewModel(
        alertRepository: context.read<AlertRepository>(),
        locationRepository: context.read<LocationRepository>(),
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
              if (profile.id.trim().isEmpty) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final SafemateShellViewModel shellViewModel = context
                  .watch<SafemateShellViewModel>();
              final SafetyRuntimeState runtimeState = viewModel.runtimeState;
              final RouteTrackingSession? activeRoute =
                  shellViewModel.runtimeState.activeRouteTracking;
              final SafetyTimerState? activeTimer =
                  shellViewModel.runtimeState.safetyTimer;
              final _HomeStatePresentation presentation = _presentationFor(
                profile: profile,
                runtimeState: runtimeState,
                activeTimer: activeTimer,
                activeRoute: activeRoute,
              );
              final List<Widget> activeChips = <Widget>[
                if (runtimeState.isLiveSharingActive)
                  const AppStatusChip(
                    label: 'Live sharing',
                    tone: AppTone.info,
                    compact: true,
                  ),
                if (activeTimer != null)
                  const AppStatusChip(
                    label: 'Timer active',
                    tone: AppTone.warning,
                    compact: true,
                  ),
                if (runtimeState.isRecordingActive)
                  const AppStatusChip(
                    label: 'Recording',
                    tone: AppTone.danger,
                    compact: true,
                  ),
                if (activeRoute != null)
                  const AppStatusChip(
                    label: 'Route active',
                    tone: AppTone.info,
                    compact: true,
                  ),
              ];
              final String? message =
                  viewModel.errorMessage ?? shellViewModel.errorMessage;
              final bool isMessageError =
                  viewModel.errorMessage != null ||
                  shellViewModel.errorMessage != null;

              return Scaffold(
                appBar: AppBar(title: const Text('Safemate')),
                body: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _TopStatusCard(
                        title: presentation.title,
                        subtitle: presentation.subtitle,
                        tone: presentation.tone,
                        batteryLevel: batteryLevel,
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: EmergencyButton(
                          label: viewModel.isBusy ? '...' : 'SOS',
                          isBusy: viewModel.isBusy,
                          onPressed: viewModel.triggerSos,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'One tap sends help.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const SectionTitle(title: 'Quick actions'),
                      const SizedBox(height: 16),
                      _QuickActionsGrid(
                        isBusy: viewModel.isBusy || shellViewModel.isBusy,
                        runtimeState: runtimeState,
                        activeTimer: activeTimer,
                        activeRoute: activeRoute,
                        onCheckIn: () => viewModel.sendCheckIn(batteryLevel),
                        onToggleLiveSharing: viewModel.toggleManualLiveSharing,
                        onTimerPressed: () => _showTimerSheet(
                          context,
                          shellViewModel,
                          activeTimer,
                        ),
                        onRoutePressed: () => _handleRouteAction(
                          context,
                          viewModel,
                          shellViewModel,
                          activeRoute,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: activeChips.isEmpty
                            ? const SizedBox(height: 16)
                            : Padding(
                                key: ValueKey<int>(activeChips.length),
                                padding: const EdgeInsets.only(top: 18),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: activeChips,
                                ),
                              ),
                      ),
                      if (message != null) ...<Widget>[
                        const SizedBox(height: 16),
                        AppInfoBanner(
                          title: isMessageError ? 'Needs attention' : 'Update',
                          message: message,
                          icon: isMessageError
                              ? Icons.error_outline
                              : Icons.info_outline,
                          tone: isMessageError ? AppTone.danger : AppTone.info,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Future<void> _showTimerSheet(
    BuildContext context,
    SafemateShellViewModel shellViewModel,
    SafetyTimerState? activeTimer,
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
                SectionTitle(
                  title: activeTimer == null ? 'Start timer' : 'Timer active',
                  subtitle: activeTimer == null
                      ? 'Choose how long Safely should wait before starting SOS automatically.'
                      : 'Current countdown: ${_formatDuration(activeTimer.remainingAt(DateTime.now()))}',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _TimerOptionButton(
                      label: '15 min',
                      enabled: activeTimer == null,
                      onTap: () {
                        Navigator.of(context).pop();
                        shellViewModel.startSafetyTimer(
                          const Duration(minutes: 15),
                        );
                      },
                    ),
                    _TimerOptionButton(
                      label: '30 min',
                      enabled: activeTimer == null,
                      onTap: () {
                        Navigator.of(context).pop();
                        shellViewModel.startSafetyTimer(
                          const Duration(minutes: 30),
                        );
                      },
                    ),
                    _TimerOptionButton(
                      label: '1 hour',
                      enabled: activeTimer == null,
                      onTap: () {
                        Navigator.of(context).pop();
                        shellViewModel.startSafetyTimer(
                          const Duration(hours: 1),
                        );
                      },
                    ),
                  ],
                ),
                if (activeTimer != null) ...<Widget>[
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

  Future<void> _handleRouteAction(
    BuildContext context,
    SafemateHomeViewModel viewModel,
    SafemateShellViewModel shellViewModel,
    RouteTrackingSession? activeRoute,
  ) async {
    if (activeRoute != null) {
      await shellViewModel.stopRouteTracking();
      return;
    }

    final (double lat, double lng)? destination =
        await showModalBottomSheet<(double lat, double lng)>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.82,
              child: _RoutePickerSheet(viewModel: viewModel),
            );
          },
        );

    if (destination == null) {
      return;
    }

    await shellViewModel.startRouteTracking(
      destinationLat: destination.$1,
      destinationLng: destination.$2,
    );
  }
}

class _TopStatusCard extends StatelessWidget {
  const _TopStatusCard({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.batteryLevel,
  });

  final String title;
  final String subtitle;
  final AppTone tone;
  final int? batteryLevel;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      backgroundColor: AppTonePalette.background(tone).withValues(alpha: 0.72),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppTonePalette.foreground(tone),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${batteryLevel ?? '--'}%',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text('Battery', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.isBusy,
    required this.runtimeState,
    required this.activeTimer,
    required this.activeRoute,
    required this.onCheckIn,
    required this.onTimerPressed,
    required this.onToggleLiveSharing,
    required this.onRoutePressed,
  });

  final bool isBusy;
  final SafetyRuntimeState runtimeState;
  final SafetyTimerState? activeTimer;
  final RouteTrackingSession? activeRoute;
  final VoidCallback onCheckIn;
  final VoidCallback onTimerPressed;
  final VoidCallback onToggleLiveSharing;
  final VoidCallback onRoutePressed;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.22,
      children: <Widget>[
        _QuickActionButton(
          icon: Icons.check_circle_outline,
          label: "I'm Safe",
          onTap: isBusy ? null : onCheckIn,
        ),
        _QuickActionButton(
          icon: activeTimer == null
              ? Icons.timer_outlined
              : Icons.timer_off_outlined,
          label: activeTimer == null ? 'Start Timer' : 'Cancel Timer',
          onTap: isBusy ? null : onTimerPressed,
        ),
        _QuickActionButton(
          icon: runtimeState.isLiveSharingActive
              ? Icons.location_off_outlined
              : Icons.share_location_outlined,
          label: runtimeState.isLiveSharingActive
              ? 'Stop Sharing'
              : 'Share Location',
          onTap: isBusy ? null : onToggleLiveSharing,
        ),
        _QuickActionButton(
          icon: activeRoute == null
              ? Icons.alt_route
              : Icons.stop_circle_outlined,
          label: activeRoute == null ? 'Start Route' : 'Stop Route',
          onTap: isBusy ? null : onRoutePressed,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: InfoCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: AppColors.navy, size: 28),
              const SizedBox(height: 14),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerOptionButton extends StatelessWidget {
  const _TimerOptionButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      child: Text(label),
    );
  }
}

class _RoutePickerSheet extends StatefulWidget {
  const _RoutePickerSheet({required this.viewModel});

  final SafemateHomeViewModel viewModel;

  @override
  State<_RoutePickerSheet> createState() => _RoutePickerSheetState();
}

class _RoutePickerSheetState extends State<_RoutePickerSheet> {
  LatLng _center = const LatLng(6.9271, 79.8612);
  LatLng? _selectedPoint;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final (double lat, double lng) result = await widget.viewModel
          .loadRoutePickerInitialPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _center = LatLng(result.$1, result.$2);
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionTitle(
              title: 'Choose destination',
              subtitle: 'Long press the map to mark where you are heading.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: _loading
                    ? const ColoredBox(
                        color: Colors.white,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Stack(
                        children: <Widget>[
                          SafelyMap(
                            center: _selectedPoint ?? _center,
                            zoom: 14,
                            onLongPress: (LatLng point) {
                              setState(() {
                                _selectedPoint = point;
                              });
                            },
                            markers: _selectedPoint == null
                                ? const <Marker>[]
                                : <Marker>[
                                    Marker(
                                      point: _selectedPoint!,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(
                                        Icons.place,
                                        color: AppColors.emergency,
                                        size: 34,
                                      ),
                                    ),
                                  ],
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: AppInfoBanner(
                              title: _selectedPoint == null
                                  ? 'No destination selected'
                                  : 'Destination selected',
                              message: _selectedPoint == null
                                  ? 'Long press once to drop a destination pin.'
                                  : '${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                              icon: Icons.place_outlined,
                              tone: _selectedPoint == null
                                  ? AppTone.info
                                  : AppTone.safe,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _selectedPoint == null
                  ? null
                  : () => Navigator.of(context).pop((
                      _selectedPoint!.latitude,
                      _selectedPoint!.longitude,
                    )),
              icon: const Icon(Icons.alt_route),
              label: const Text('Start route monitoring'),
            ),
          ],
        ),
      ),
    );
  }
}

_HomeStatePresentation _presentationFor({
  required UserProfile profile,
  required SafetyRuntimeState runtimeState,
  required SafetyTimerState? activeTimer,
  required RouteTrackingSession? activeRoute,
}) {
  if (profile.isEmergencyActive) {
    return const _HomeStatePresentation(
      title: 'Emergency Active',
      subtitle: 'Help is being shared now.',
      tone: AppTone.danger,
    );
  }
  if (runtimeState.isLiveSharingActive) {
    return const _HomeStatePresentation(
      title: 'You are Monitoring',
      subtitle: 'Live location is currently being shared.',
      tone: AppTone.info,
    );
  }
  if (activeTimer != null) {
    return const _HomeStatePresentation(
      title: 'Timer Running',
      subtitle: 'Safely is waiting for your timer to finish.',
      tone: AppTone.warning,
    );
  }
  if (activeRoute != null) {
    return const _HomeStatePresentation(
      title: 'Journey Active',
      subtitle: 'Route monitoring is quietly watching your trip.',
      tone: AppTone.info,
    );
  }
  return const _HomeStatePresentation(
    title: 'You are Safe',
    subtitle: 'Everything looks calm right now.',
    tone: AppTone.safe,
  );
}

class _HomeStatePresentation {
  const _HomeStatePresentation({
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final AppTone tone;
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
