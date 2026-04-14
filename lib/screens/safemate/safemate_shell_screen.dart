import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/emergency_detection_service.dart';
import '../../core/services/geofence_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_title.dart';
import '../../models/user_profile.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../viewmodels/safemate_shell_viewmodel.dart';
import 'activity_history_screen.dart';
import 'guardians_screen.dart';
import 'medical_information_screen.dart';
import 'safemate_home_screen.dart';
import 'safety_settings_screen.dart';

class SafemateShellScreen extends StatelessWidget {
  const SafemateShellScreen({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SafemateShellViewModel>(
      create: (_) => SafemateShellViewModel(
        profileRepository: context.read<ProfileRepository>(),
        alertRepository: context.read<AlertRepository>(),
        safetyRepository: context.read<SafetyRepository>(),
        connectivityService: context.read<ConnectivityService>(),
        geofenceRegistrationService: context
            .read<GeofenceRegistrationService>(),
        emergencyDetectionService: context.read<EmergencyDetectionService>(),
        initialUser: userProfile,
      ),
      child: const _SafemateShellBody(),
    );
  }
}

class _SafemateShellBody extends StatefulWidget {
  const _SafemateShellBody();

  @override
  State<_SafemateShellBody> createState() => _SafemateShellBodyState();
}

class _SafemateShellBodyState extends State<_SafemateShellBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SafemateShellViewModel>(
      builder:
          (
            BuildContext context,
            SafemateShellViewModel shellViewModel,
            Widget? child,
          ) {
            if (shellViewModel.currentUser.id.trim().isEmpty) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final List<Widget> pages = <Widget>[
              SafemateHomeScreen(
                profile: shellViewModel.currentUser,
                settings: shellViewModel.settings,
                batteryLevel: shellViewModel.currentUser.batteryLevel,
                isOnline: shellViewModel.isOnline,
              ),
              GuardiansScreen(safemateId: shellViewModel.currentUser.id),
              ActivityHistoryScreen(userId: shellViewModel.currentUser.id),
              SafetySettingsScreen(
                userId: shellViewModel.currentUser.id,
                onOpenMedical: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MedicalInformationScreen(
                        userId: shellViewModel.currentUser.id,
                        title: 'Medical information',
                        editable: true,
                        userProfile: shellViewModel.currentUser,
                      ),
                    ),
                  );
                },
              ),
            ];

            final EmergencyConfirmationState? emergencyConfirmation =
                shellViewModel.emergencyConfirmation;

            return Scaffold(
              body: Stack(
                children: <Widget>[
                  IndexedStack(index: _currentIndex, children: pages),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SafeArea(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: shellViewModel.registerPanicTap,
                        child: const SizedBox(width: 56, height: 56),
                      ),
                    ),
                  ),
                  if (emergencyConfirmation == null)
                    Positioned(
                      left: AppConstants.pagePadding,
                      right: AppConstants.pagePadding,
                      bottom: 96,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: shellViewModel.shouldShowCheckInPrompt
                            ? _CheckInPromptCard(viewModel: shellViewModel)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  if (emergencyConfirmation != null)
                    Positioned.fill(
                      child: _EmergencyDetectionDialog(
                        confirmation: emergencyConfirmation,
                        viewModel: shellViewModel,
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: emergencyConfirmation == null
                  ? NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      destinations: const <NavigationDestination>[
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.groups_outlined),
                          selectedIcon: Icon(Icons.groups),
                          label: 'Guardians',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.history_outlined),
                          selectedIcon: Icon(Icons.history),
                          label: 'History',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune),
                          label: 'Settings',
                        ),
                      ],
                    )
                  : null,
            );
          },
    );
  }
}

class _EmergencyDetectionDialog extends StatelessWidget {
  const _EmergencyDetectionDialog({
    required this.confirmation,
    required this.viewModel,
  });

  final EmergencyConfirmationState confirmation;
  final SafemateShellViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final int remainingSeconds = confirmation.remaining.inSeconds;

    return Material(
      color: AppColors.navyDeep.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: InfoCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Center(
                      child: AppStatusChip(
                        label: 'Safety check',
                        tone: AppTone.warning,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: 'Are you safe?',
                      subtitle:
                          'Unusual activity was detected. Safely will send help automatically if you do not respond.',
                      centered: true,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: AppStatusChip(
                        label: 'Sending help in ${remainingSeconds}s',
                        tone: AppTone.danger,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        confirmation.event.type.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: "I'm Safe",
                      icon: Icons.check_circle_outline,
                      onPressed: viewModel.isBusy
                          ? null
                          : viewModel.confirmEmergencyDetectionSafe,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: viewModel.isBusy
                          ? null
                          : viewModel.sendHelpFromEmergencyDetection,
                      icon: const Icon(Icons.sos_outlined),
                      label: const Text('Send Help'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emergency,
                        side: BorderSide(
                          color: AppColors.emergency.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckInPromptCard extends StatelessWidget {
  const _CheckInPromptCard({required this.viewModel});

  final SafemateShellViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final Duration remaining =
        viewModel.checkInPromptRemaining ?? Duration.zero;

    return InfoCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppStatusChip(
                  label: 'Check-in needed',
                  tone: AppTone.warning,
                  compact: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you safe?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${remaining.inSeconds}s left to respond.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 132,
            child: PrimaryButton(
              label: "I'm Safe",
              icon: Icons.check_circle_outline,
              onPressed: viewModel.isBusy
                  ? null
                  : viewModel.respondToCheckInPrompt,
            ),
          ),
        ],
      ),
    );
  }
}
