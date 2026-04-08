import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/permission_status_tile.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/notification_repository.dart';
import '../../core/services/permissions_service.dart';
import '../../viewmodels/permission_setup_viewmodel.dart';

class PermissionSetupScreen extends StatelessWidget {
  const PermissionSetupScreen({super.key, required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PermissionSetupViewModel>(
      create: (_) => PermissionSetupViewModel(
        permissionsService: context.read<PermissionsService>(),
        notificationRepository: context.read<NotificationRepository>(),
      ),
      child: _PermissionSetupScreenBody(onContinue: onContinue),
    );
  }
}

class _PermissionSetupScreenBody extends StatelessWidget {
  const _PermissionSetupScreenBody({required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionSetupViewModel>(
      builder: (BuildContext context, PermissionSetupViewModel viewModel, Widget? child) {
        final permissionHealth = viewModel.permissionHealth;

        return Scaffold(
          appBar: AppBar(title: const Text('Permission setup')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              SectionCard(
                title: 'Set up emergency permissions',
                subtitle:
                    'Safely asks only for what is needed to send alerts, share live location, and record emergency audio when you start an SOS.',
                child: permissionHealth == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: <Widget>[
                          PermissionStatusTile(
                            icon: Icons.location_on_outlined,
                            title: 'Location',
                            description:
                                'Needed for SOS, live sharing, geofences, and check-ins. Background access improves OS geofence reliability.',
                            state: permissionHealth.location,
                            onRequest: viewModel.requestLocation,
                          ),
                          PermissionStatusTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            description:
                                'Needed so guardians receive urgent updates fast.',
                            state: permissionHealth.notifications,
                            onRequest: viewModel.requestNotifications,
                          ),
                          PermissionStatusTile(
                            icon: Icons.mic_none,
                            title: 'Microphone',
                            description:
                                'Used only during emergency recording when enabled.',
                            state: permissionHealth.microphone,
                            onRequest: viewModel.requestMicrophone,
                          ),
                          const Divider(height: 24),
                          TextButton.icon(
                            onPressed: viewModel.openSettings,
                            icon: const Icon(Icons.settings),
                            label: const Text('Open app settings'),
                          ),
                          const SizedBox(height: 12),
                          PrimaryActionButton(
                            label: 'Continue to app',
                            icon: Icons.check_circle_outline,
                            onPressed: onContinue,
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
