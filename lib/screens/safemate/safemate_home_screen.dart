import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../models/safety_alert.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../viewmodels/safemate_home_viewmodel.dart';

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
              final bool emergencyActive = profile.isEmergencyActive;
              final StatusChip statusChip = emergencyActive
                  ? const StatusChip(
                      label: 'Emergency active',
                      color: AppColors.emergency,
                    )
                  : viewModel.runtimeState.isLiveSharingActive
                  ? const StatusChip(
                      label: 'Monitoring',
                      color: AppColors.warning,
                    )
                  : viewModel.runtimeState.isNightMonitoringActive
                  ? const StatusChip(
                      label: 'Night monitoring',
                      color: AppColors.warning,
                    )
                  : viewModel.runtimeState.isTrustedPlaceActive
                  ? const StatusChip(
                      label: 'Trusted place',
                      color: AppColors.safe,
                    )
                  : const StatusChip(label: 'Safe', color: AppColors.safe);

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Safemate'),
                  actions: <Widget>[
                    TextButton.icon(
                      onPressed: null,
                      icon: Icon(
                        Icons.cloud_done_outlined,
                        color: profile.lastLocationSyncAt == null
                            ? AppColors.muted
                            : AppColors.safe,
                      ),
                      label: Text(
                        profile.lastLocationSyncAt == null ? 'Idle' : 'Synced',
                      ),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  children: <Widget>[
                    SectionCard(
                      title: 'Current safety status',
                      trailing: statusChip,
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              MetricTile(
                                label: 'Battery',
                                value: '${batteryLevel ?? '--'}%',
                                icon: Icons.battery_5_bar_outlined,
                                emphasisColor: (batteryLevel ?? 100) <= 15
                                    ? AppColors.emergency
                                    : AppColors.safe,
                              ),
                              const SizedBox(width: 12),
                              MetricTile(
                                label: 'Guardians',
                                value: '${profile.guardianIds.length}',
                                icon: Icons.groups_2_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              MetricTile(
                                label: 'Last sync',
                                value: profile.lastLocationSyncAt == null
                                    ? 'Not yet'
                                    : DateTimeFormatter.formatShort(
                                        profile.lastLocationSyncAt!,
                                      ),
                                icon: Icons.location_on_outlined,
                              ),
                              const SizedBox(width: 12),
                              MetricTile(
                                label: 'Connection',
                                value: isOnline ? 'Online' : 'Offline',
                                icon: isOnline
                                    ? Icons.wifi_tethering
                                    : Icons.wifi_off,
                                emphasisColor: isOnline
                                    ? AppColors.safe
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                          if (viewModel.runtimeState.isTrustedPlaceActive ||
                              viewModel
                                  .runtimeState
                                  .isNightMonitoringActive) ...<Widget>[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                if (viewModel.runtimeState.isTrustedPlaceActive)
                                  const StatusChip(
                                    label: 'Safe zone active',
                                    color: AppColors.safe,
                                  ),
                                if (viewModel
                                    .runtimeState
                                    .isNightMonitoringActive)
                                  const StatusChip(
                                    label: 'Overnight watch on',
                                    color: AppColors.warning,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'Emergency SOS',
                      subtitle:
                          'One tap starts alerts, live sharing, and emergency recording.',
                      child: Column(
                        children: <Widget>[
                          Center(
                            child: SizedBox(
                              width: AppConstants.sosButtonSize,
                              height: AppConstants.sosButtonSize,
                              child: FilledButton(
                                onPressed: viewModel.isBusy
                                    ? null
                                    : viewModel.triggerSos,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.emergency,
                                  foregroundColor: Colors.white,
                                  shape: const CircleBorder(),
                                ),
                                child: Text(
                                  viewModel.isBusy ? 'Sending...' : 'SOS',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      viewModel.sendCheckIn(batteryLevel),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Quick check-in'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: viewModel.toggleManualLiveSharing,
                                  icon: Icon(
                                    viewModel.runtimeState.isLiveSharingActive
                                        ? Icons.location_off
                                        : Icons.share_location_outlined,
                                  ),
                                  label: Text(
                                    viewModel.runtimeState.isLiveSharingActive
                                        ? 'Stop live'
                                        : 'Start live',
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.latestAlert == null)
                      const EmptyStateCard(
                        icon: Icons.notifications_none,
                        title: 'No recent alerts',
                        message:
                            'Your latest SOS, battery, geofence, and check-in activity will appear here.',
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
          Text(alert.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(alert.description),
        ],
      ),
    );
  }
}
