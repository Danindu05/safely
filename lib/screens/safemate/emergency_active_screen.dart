import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
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
                falseAlarm ? 'Cancel false alarm?' : 'Clear emergency?',
              ),
              content: Text(
                falseAlarm
                    ? 'Use this only if you sent SOS by mistake.'
                    : 'Stop live sharing and end the emergency session.',
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

            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Emergency active'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.emergency,
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 54,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Guardians have been alerted',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          viewModel.runtimeState.isAudioUploading
                              ? 'Live location is ${viewModel.runtimeState.isLiveSharingActive ? 'active' : 'stopped'} and the emergency recording is uploading.'
                              : 'Live location is ${viewModel.runtimeState.isLiveSharingActive ? 'active' : 'stopped'} and recording is ${viewModel.runtimeState.isRecordingActive ? 'running' : 'stopped'}.',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        if (viewModel.runtimeState.audioUploadError !=
                            null) ...<Widget>[
                          const SizedBox(height: 10),
                          Text(
                            viewModel.runtimeState.audioUploadError!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Emergency session details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(alert?.title ?? 'Preparing emergency alert...'),
                        if (alert != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(DateTimeFormatter.formatShort(alert.timestamp)),
                          const SizedBox(height: 6),
                          Text('Status: ${alert.status.label}'),
                          if (viewModel
                              .runtimeState
                              .isAudioUploading) ...<Widget>[
                            const SizedBox(height: 10),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            const Text('Uploading emergency audio...'),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: 'False alarm cancel',
                    icon: Icons.close,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.emergency,
                    onPressed: () =>
                        _confirmStop(context, viewModel, falseAlarm: true),
                  ),
                  const SizedBox(height: 12),
                  PrimaryActionButton(
                    label: 'Clear emergency',
                    icon: Icons.check_circle_outline,
                    onPressed: () =>
                        _confirmStop(context, viewModel, falseAlarm: false),
                  ),
                ],
              ),
            );
          },
    );
  }
}
