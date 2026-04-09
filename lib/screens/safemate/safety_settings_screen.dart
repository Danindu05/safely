import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_tone.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_toggle_tile.dart';
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
              const AppInfoBanner(
                title: 'Quiet protection, tuned to you',
                message:
                    'These controls shape how Safely watches, records, and escalates when something feels wrong.',
                icon: Icons.shield_outlined,
                tone: AppTone.info,
              ),
              if (viewModel.errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                AppInfoBanner(
                  title: 'Settings issue',
                  message: viewModel.errorMessage!,
                  icon: Icons.error_outline,
                  tone: AppTone.danger,
                ),
              ],
              if (viewModel.infoMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                AppInfoBanner(
                  title: 'Settings saved',
                  message: viewModel.infoMessage!,
                  icon: Icons.check_circle_outline,
                  tone: AppTone.safe,
                ),
              ],
              const SizedBox(height: 16),
              SectionCard(
                title: 'Emergency response',
                subtitle:
                    'Control what Safely does the moment an emergency starts.',
                child: Column(
                  children: <Widget>[
                    AppToggleTile(
                      icon: Icons.share_location_outlined,
                      title: 'Live location sharing',
                      subtitle:
                          'Allow Safely to share location during emergencies and manual live sessions.',
                      value: settings.liveLocationEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(liveLocationEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.mic_none_rounded,
                      title: 'Emergency audio recording',
                      subtitle:
                          'Record audio only during emergencies and upload it after the session ends.',
                      value: settings.audioRecordingEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(audioRecordingEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Smart monitoring',
                subtitle:
                    'Choose which protective systems stay active while you use the app.',
                child: Column(
                  children: <Widget>[
                    AppToggleTile(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Emergency detection',
                      subtitle:
                          'Use phone motion sensors while the app is active and always ask before sending SOS.',
                      value: settings.emergencyDetectionEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(emergencyDetectionEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.personal_injury_outlined,
                      title: 'Fall and impact detection',
                      subtitle:
                          'Look for impact plus stillness patterns that could suggest a fall.',
                      value: settings.fallDetectionEnabled,
                      enabled: settings.emergencyDetectionEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(fallDetectionEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.directions_run_outlined,
                      title: 'Abnormal movement detection',
                      subtitle:
                          'Watch for erratic movement or abrupt stop patterns before showing a confirmation prompt.',
                      value: settings.movementDetectionEnabled,
                      enabled: settings.emergencyDetectionEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(movementDetectionEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.place_outlined,
                      title: 'Geofencing',
                      subtitle:
                          'Check safe and unsafe zones and alert you when a location feels risky.',
                      value: settings.geofencingEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(geofencingEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.watch_later_outlined,
                      title: 'Check-in reminders',
                      subtitle:
                          'Ask “Are you safe?” at regular intervals and escalate when there is no response.',
                      value: settings.checkInEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(checkInEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Context-aware behavior',
                subtitle:
                    'Reduce noise in familiar places and add extra care at night.',
                child: Column(
                  children: <Widget>[
                    AppToggleTile(
                      icon: Icons.home_work_outlined,
                      title: 'Trusted place mode',
                      subtitle:
                          'Use your safe zones to lower concern when you are somewhere familiar.',
                      value: settings.trustedPlaceModeEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(trustedPlaceModeEnabled: value),
                      ),
                    ),
                    const Divider(height: 20),
                    AppToggleTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Night mode monitoring',
                      subtitle:
                          'Between 10 PM and 6 AM, guardians are alerted if check-ins go quiet outside a trusted place.',
                      value: settings.nightModeMonitoringEnabled,
                      onChanged: (bool value) => viewModel.save(
                        settings.copyWith(nightModeMonitoringEnabled: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Battery protection',
                subtitle:
                    'Decide when Guardians should hear about low power and when Safely should escalate.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SliderSetting(
                      title: 'Low battery warning',
                      valueLabel: '${settings.lowBatteryWarningPercent}%',
                      helper:
                          'Send a low-battery alert when charge drops below this point.',
                      slider: Slider(
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
                    ),
                    const SizedBox(height: 18),
                    _SliderSetting(
                      title: 'Critical battery escalation',
                      valueLabel: '${settings.lowBatteryCriticalPercent}%',
                      helper:
                          'When charge falls this low, Safely can start emergency sharing automatically.',
                      slider: Slider(
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'More setup',
                subtitle:
                    'Keep emergency details current and manage related safety tools.',
                child: Column(
                  children: <Widget>[
                    _ActionTile(
                      icon: Icons.map_outlined,
                      title: 'Geofence setup',
                      subtitle: 'Add or review safe and unsafe zones.',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GeofenceSetupScreen(userId: userId),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 20),
                    _ActionTile(
                      icon: Icons.medical_information_outlined,
                      title: 'Medical information',
                      subtitle:
                          'Update allergies, conditions, and emergency contacts.',
                      onTap: onOpenMedical,
                    ),
                    const Divider(height: 20),
                    _ActionTile(
                      icon: Icons.logout,
                      title: 'Sign out',
                      subtitle: 'Return to the login screen on this device.',
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

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.valueLabel,
    required this.helper,
    required this.slider,
  });

  final String title;
  final String valueLabel;
  final String helper;
  final Widget slider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppInfoPill(label: valueLabel),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        slider,
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class AppInfoPill extends StatelessWidget {
  const AppInfoPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
