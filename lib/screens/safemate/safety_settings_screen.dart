import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/safety_settings_viewmodel.dart';
import 'geofence_setup_screen.dart';

class SafetySettingsScreen extends StatelessWidget {
  const SafetySettingsScreen({
    super.key,
    required this.userId,
    required this.onOpenMedical,
  });

  final String userId;
  final VoidCallback onOpenMedical;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SafetySettingsViewModel>(
      create: (_) => SafetySettingsViewModel(
        authRepository: context.read<AuthRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        userId: userId,
      ),
      child: _SafetySettingsScreenBody(
        userId: userId,
        onOpenMedical: onOpenMedical,
      ),
    );
  }
}

class _SafetySettingsScreenBody extends StatelessWidget {
  const _SafetySettingsScreenBody({
    required this.userId,
    required this.onOpenMedical,
  });

  final String userId;
  final VoidCallback onOpenMedical;

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetySettingsViewModel>(
      builder: (BuildContext context, SafetySettingsViewModel viewModel, Widget? child) {
        final settings = viewModel.settings;
        if (settings == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Safety settings')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              SectionCard(
                title: 'Thresholds and behavior',
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      value: settings.liveLocationEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(liveLocationEnabled: value),
                      ),
                      title: const Text('Enable live location sharing'),
                    ),
                    SwitchListTile(
                      value: settings.audioRecordingEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(audioRecordingEnabled: value),
                      ),
                      title: const Text('Record emergency audio'),
                    ),
                    SwitchListTile(
                      value: settings.geofencingEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(geofencingEnabled: value),
                      ),
                      title: const Text('Enable geofencing'),
                    ),
                    SwitchListTile(
                      value: settings.checkInEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(checkInEnabled: value),
                      ),
                      title: const Text('Enable check-ins'),
                    ),
                    SwitchListTile(
                      value: settings.trustedPlaceModeEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(trustedPlaceModeEnabled: value),
                      ),
                      title: const Text('Trusted place mode'),
                      subtitle: const Text(
                        'Uses your safe zones to reduce overnight concern when you are somewhere trusted.',
                      ),
                    ),
                    SwitchListTile(
                      value: settings.nightModeMonitoringEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(nightModeMonitoringEnabled: value),
                      ),
                      title: const Text('Night mode monitoring'),
                      subtitle: const Text(
                        'Between 10 PM and 6 AM, guardians are alerted if check-ins go quiet outside a trusted place.',
                      ),
                    ),
                    ListTile(
                      title: const Text('Low battery warning'),
                      subtitle: Text('${settings.lowBatteryWarningPercent}%'),
                    ),
                    Slider(
                      value: settings.lowBatteryWarningPercent.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '${settings.lowBatteryWarningPercent}%',
                      onChanged: (double value) => viewModel.save(
                        settings.copyWith(
                          lowBatteryWarningPercent: value.round(),
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text('Critical battery alert'),
                      subtitle: Text('${settings.lowBatteryCriticalPercent}%'),
                    ),
                    Slider(
                      value: settings.lowBatteryCriticalPercent.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '${settings.lowBatteryCriticalPercent}%',
                      onChanged: (double value) => viewModel.save(
                        settings.copyWith(
                          lowBatteryCriticalPercent: value.round(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'More safety setup',
                child: Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Geofence setup'),
                      subtitle: const Text(
                        'Add safe and unsafe zones on a map.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GeofenceSetupScreen(userId: userId),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Medical information'),
                      subtitle: const Text(
                        'Keep allergies, conditions, and emergency contact details current.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onOpenMedical,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Trusted place guidance'),
                      subtitle: const Text(
                        'Mark home, campus, or any familiar stop as a safe zone. Trusted place mode becomes active when you are inside one.',
                      ),
                      trailing: const Icon(Icons.home_work_outlined),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sign out'),
                      subtitle: const Text(
                        'Return to the login screen on this device.',
                      ),
                      trailing: const Icon(Icons.logout),
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
