import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              body: IndexedStack(index: _currentIndex, children: pages),
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
