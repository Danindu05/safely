import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import 'guardian_alerts_screen.dart';
import 'guardian_dashboard_screen.dart';
import 'guardian_live_map_screen.dart';
import 'notification_settings_screen.dart';

class GuardianShellScreen extends StatefulWidget {
  const GuardianShellScreen({super.key, required this.userProfile});

  final UserProfile userProfile;

  @override
  State<GuardianShellScreen> createState() => _GuardianShellScreenState();
}

class _GuardianShellScreenState extends State<GuardianShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      GuardianDashboardScreen(guardianId: widget.userProfile.id),
      GuardianAlertsScreen(guardianId: widget.userProfile.id),
      GuardianLiveMapScreen(guardianId: widget.userProfile.id),
      NotificationSettingsScreen(guardianId: widget.userProfile.id),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Live map',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
