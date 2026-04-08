import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/safety_repository.dart';
import '../../core/services/connectivity_service.dart';
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

            return Scaffold(
              body: Column(
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
                        child: _CheckInPromptCard(viewModel: shellViewModel),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
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
              ),
            );
          },
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

    return Card(
      color: AppColors.safe.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Are you safe?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap once to confirm. If there is no response, guardians are notified automatically.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: viewModel.isBusy
                        ? null
                        : viewModel.respondToCheckInPrompt,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("I'm Safe"),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${remaining.inSeconds}s',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
