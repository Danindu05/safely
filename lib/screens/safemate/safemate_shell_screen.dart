import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/emergency_detection_service.dart';
import '../../core/services/geofence_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../models/user_profile.dart';
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
                  Column(
                    children: <Widget>[
                      if (shellViewModel.shouldShowCheckInPrompt)
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppConstants.pagePadding,
                              12,
                              AppConstants.pagePadding,
                              0,
                            ),
                            child: _CheckInPromptCard(
                              viewModel: shellViewModel,
                            ),
                          ),
                        ),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
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
      color: AppColors.navyDeep.withValues(alpha: 0.96),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.emergency.withValues(alpha: 0.12),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x240A1730),
                    blurRadius: 36,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.emergencySoft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        size: 38,
                        color: AppColors.emergency,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Are you safe?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Unusual activity detected: ${confirmation.event.type.label.toLowerCase()}. If you do nothing, Safely will send help automatically.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: AppStatusChip(
                      label: 'Sending help in ${remainingSeconds}s',
                      tone: AppTone.danger,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: viewModel.isBusy
                        ? null
                        : viewModel.confirmEmergencyDetectionSafe,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("I'm Safe"),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: viewModel.isBusy
                        ? null
                        : viewModel.sendHelpFromEmergencyDetection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emergency,
                      side: BorderSide(
                        color: AppColors.emergency.withValues(alpha: 0.3),
                      ),
                    ),
                    icon: const Icon(Icons.sos_outlined),
                    label: const Text('Send Help'),
                  ),
                ],
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x100A1730),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppStatusChip(
                label: 'Check-in needed',
                tone: AppTone.warning,
                compact: true,
              ),
              const Spacer(),
              Text(
                '${remaining.inSeconds}s',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Are you safe?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap once to confirm. If there is no response, guardians are notified automatically.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: viewModel.isBusy
                ? null
                : viewModel.respondToCheckInPrompt,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("I'm Safe"),
          ),
        ],
      ),
    );
  }
}
