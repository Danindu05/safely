import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/notification_settings_viewmodel.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationSettingsViewModel>(
      create: (_) =>
          NotificationSettingsViewModel(context.read<AuthRepository>()),
      child: const _NotificationSettingsScreenBody(),
    );
  }
}

class _NotificationSettingsScreenBody extends StatelessWidget {
  const _NotificationSettingsScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSettingsViewModel>(
      builder:
          (
            BuildContext context,
            NotificationSettingsViewModel viewModel,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('Notification settings')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  SectionCard(
                    title: 'Guardian alert preferences',
                    subtitle:
                        'These controls are app-side preferences prepared for repeated alert behavior and escalation work later.',
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          value: viewModel.soundEnabled,
                          onChanged: viewModel.toggleSound,
                          title: const Text('Sound'),
                        ),
                        SwitchListTile(
                          value: viewModel.vibrationEnabled,
                          onChanged: viewModel.toggleVibration,
                          title: const Text('Vibrate'),
                        ),
                        SwitchListTile(
                          value: viewModel.repeatedAlertsEnabled,
                          onChanged: viewModel.toggleRepeatedAlerts,
                          title: const Text('Repeated alert behavior'),
                        ),
                        SwitchListTile(
                          value: viewModel.highPriorityOnly,
                          onChanged: viewModel.toggleHighPriorityOnly,
                          title: const Text('High priority alerts only'),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Sign out'),
                          subtitle: const Text(
                            'Return to the login screen on this guardian device.',
                          ),
                          trailing: viewModel.isSigningOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.logout),
                          onTap: viewModel.signOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
