import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_tone.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_toggle_tile.dart';
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
      builder: (BuildContext context, NotificationSettingsViewModel viewModel, Widget? child) {
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
              const AppInfoBanner(
                title: 'Choose what reaches you instantly',
                message:
                    'These preferences are stored in Firestore and enforced before Guardian push notifications are sent.',
                icon: Icons.notifications_active_outlined,
                tone: AppTone.info,
              ),
              if (viewModel.errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                AppInfoBanner(
                  title: 'Notification setting issue',
                  message: viewModel.errorMessage!,
                  icon: Icons.error_outline,
                  tone: AppTone.danger,
                ),
              ],
              if (viewModel.infoMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                AppInfoBanner(
                  title: 'Notification settings saved',
                  message: viewModel.infoMessage!,
                  icon: Icons.check_circle_outline,
                  tone: AppTone.safe,
                ),
              ],
              const SizedBox(height: 16),
              SectionCard(
                title: 'Guardian alert preferences',
                subtitle:
                    'Keep high-priority alerts on, and quiet the categories you do not need.',
                child: Column(
                  children: <Widget>[
                    AppToggleTile(
                      icon: Icons.sos_rounded,
                      title: 'SOS alerts',
                      subtitle:
                          'Highest-priority emergency notifications when immediate help may be needed.',
                      value: settings.sosNotificationsEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(sosNotificationsEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.battery_alert_outlined,
                      title: 'Battery alerts',
                      subtitle:
                          'Warnings when a Safemate may soon lose contact due to low power.',
                      value: settings.batteryNotificationsEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(batteryNotificationsEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.gpp_bad_outlined,
                      title: 'Geofence and route alerts',
                      subtitle:
                          'Unsafe-zone entries and route deviation warnings.',
                      value: settings.geofenceNotificationsEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(geofenceNotificationsEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.schedule_send_outlined,
                      title: 'Check-in alerts',
                      subtitle:
                          'Missed check-ins and reassurance check-in updates.',
                      value: settings.checkInNotificationsEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(checkInNotificationsEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Device session',
                subtitle:
                    'Manage this Guardian session without affecting linked Safemates.',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Sign out',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Return to the login screen on this device.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.logout),
                  ),
                  trailing: viewModel.isSigningOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: viewModel.signOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
