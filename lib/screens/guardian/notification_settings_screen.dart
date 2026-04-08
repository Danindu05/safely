import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/section_card.dart';
import '../../models/user_settings.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/notification_settings_viewmodel.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationSettingsViewModel>(
      create: (_) => NotificationSettingsViewModel(
        authRepository: context.read<AuthRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        guardianId: guardianId,
      ),
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
            final UserSettings? settings = viewModel.settings;
            if (settings == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              appBar: AppBar(title: const Text('Notification settings')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  SectionCard(
                    title: 'Guardian alert preferences',
                    subtitle:
                        'These settings are saved to Firestore and enforced before guardian push notifications are sent.',
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          value: settings.sosNotificationsEnabled,
                          onChanged: (bool value) => viewModel.save(
                            settings.copyWith(sosNotificationsEnabled: value),
                          ),
                          title: const Text('SOS alerts'),
                          subtitle: const Text(
                            'Highest priority emergency notifications.',
                          ),
                        ),
                        SwitchListTile(
                          value: settings.batteryNotificationsEnabled,
                          onChanged: (bool value) => viewModel.save(
                            settings.copyWith(
                              batteryNotificationsEnabled: value,
                            ),
                          ),
                          title: const Text('Battery alerts'),
                        ),
                        SwitchListTile(
                          value: settings.geofenceNotificationsEnabled,
                          onChanged: (bool value) => viewModel.save(
                            settings.copyWith(
                              geofenceNotificationsEnabled: value,
                            ),
                          ),
                          title: const Text('Geofence and route alerts'),
                        ),
                        SwitchListTile(
                          value: settings.checkInNotificationsEnabled,
                          onChanged: (bool value) => viewModel.save(
                            settings.copyWith(
                              checkInNotificationsEnabled: value,
                            ),
                          ),
                          title: const Text('Check-in alerts'),
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
                        const Divider(height: 24),
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
