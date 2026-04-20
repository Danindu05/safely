import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_title.dart';
import '../../models/app_enums.dart';
import '../../models/user_profile.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../viewmodels/emergency_active_viewmodel.dart';

class EmergencyActiveScreen extends StatelessWidget {
  const EmergencyActiveScreen({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EmergencyActiveViewModel>(
      create: (_) => EmergencyActiveViewModel(
        alertRepository: context.read<AlertRepository>(),
        safetyRepository: context.read<SafetyRepository>(),
        profile: userProfile,
      ),
      child: const _EmergencyActiveScreenBody(),
    );
  }
}

class _EmergencyActiveScreenBody extends StatelessWidget {
  const _EmergencyActiveScreenBody();

  Future<void> _confirmStop(
    BuildContext context,
    EmergencyActiveViewModel viewModel, {
    required bool falseAlarm,
  }) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(
                falseAlarm ? 'Mark as false alarm?' : 'End emergency?',
              ),
              content: Text(
                falseAlarm
                    ? 'Use this only if SOS was sent by mistake.'
                    : 'This will stop live sharing and close the emergency session.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Keep active'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    if (falseAlarm) {
      await viewModel.cancelFalseAlarm();
    } else {
      await viewModel.resolveEmergency();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyActiveViewModel>(
      builder:
          (
            BuildContext context,
            EmergencyActiveViewModel viewModel,
            Widget? child,
          ) {
            final alert = viewModel.alert;
            final SafetyRuntimeState runtimeState = viewModel.runtimeState;

            return Scaffold(
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.emergency,
                          borderRadius: BorderRadius.circular(
                            AppConstants.cardRadius,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const AppStatusChip(
                              label: 'Help is being shared',
                              tone: AppTone.danger,
                              compact: true,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Emergency Active',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Guardians have been alerted.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const SectionTitle(title: 'Emergency status'),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _ElapsedChip(startedAt: alert?.timestamp),
                                      AppStatusChip(
                                        label: runtimeState.isLiveSharingActive
                                            ? 'Live sharing on'
                                            : 'Live sharing off',
                                        tone: runtimeState.isLiveSharingActive
                                            ? AppTone.info
                                            : AppTone.neutral,
                                        compact: true,
                                      ),
                                      AppStatusChip(
                                        label: runtimeState.isRecordingActive
                                            ? 'Recording on'
                                            : 'Recording off',
                                        tone: runtimeState.isRecordingActive
                                            ? AppTone.danger
                                            : AppTone.neutral,
                                        compact: true,
                                      ),
                                      AppStatusChip(
                                        label: runtimeState.isAudioUploading
                                            ? 'Uploading audio'
                                            : 'Audio idle',
                                        tone: runtimeState.isAudioUploading
                                            ? AppTone.warning
                                            : AppTone.neutral,
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    alert == null
                                        ? 'Preparing emergency details...'
                                        : DateTimeFormatter.formatShort(
                                            alert.timestamp,
                                          ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            InfoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SectionTitle(title: 'Current details'),
                                  const SizedBox(height: 16),
                                  _StatusRow(
                                    label: 'Alert',
                                    value: alert?.title ?? 'Preparing alert',
                                  ),
                                  const SizedBox(height: 12),
                                  _StatusRow(
                                    label: 'Status',
                                    value: alert?.status.label ?? 'Starting',
                                  ),
                                  const SizedBox(height: 12),
                                  _StatusRow(
                                    label: 'Location',
                                    value: runtimeState.isLiveSharingActive
                                        ? 'Sharing live location'
                                        : 'Location not shared yet',
                                  ),
                                ],
                              ),
                            ),
                            if (runtimeState.audioUploadError !=
                                null) ...<Widget>[
                              const SizedBox(height: 16),
                              AppInfoBanner(
                                title: 'Audio upload issue',
                                message: runtimeState.audioUploadError!,
                                icon: Icons.error_outline,
                                tone: AppTone.warning,
                              ),
                            ],
                            if (viewModel.errorMessage != null) ...<Widget>[
                              const SizedBox(height: 16),
                              AppInfoBanner(
                                title: 'Emergency update',
                                message: viewModel.errorMessage!,
                                icon: Icons.error_outline,
                                tone: AppTone.danger,
                              ),
                            ],
                            if (viewModel.infoMessage != null) ...<Widget>[
                              const SizedBox(height: 16),
                              AppInfoBanner(
                                title: 'Emergency info',
                                message: viewModel.infoMessage!,
                                icon: Icons.info_outline,
                                tone: AppTone.info,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.pagePadding,
                        0,
                        AppConstants.pagePadding,
                        AppConstants.pagePadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          PrimaryButton(
                            label: 'End Emergency',
                            icon: Icons.check_circle_outline,
                            onPressed: () => _confirmStop(
                              context,
                              viewModel,
                              falseAlarm: false,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _confirmStop(
                              context,
                              viewModel,
                              falseAlarm: true,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emergency,
                              side: BorderSide(
                                color: AppColors.emergency.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('False Alarm'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ElapsedChip extends StatelessWidget {
  const _ElapsedChip({required this.startedAt});

  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    if (startedAt == null) {
      return const AppStatusChip(
        label: 'Starting',
        tone: AppTone.warning,
        compact: true,
      );
    }

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (int x) => x),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final Duration elapsed = DateTime.now().difference(startedAt!);
        return AppStatusChip(
          label: 'Elapsed ${_formatElapsed(elapsed)}',
          tone: AppTone.danger,
          compact: true,
        );
      },
    );
  }
}

String _formatElapsed(Duration duration) {
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
