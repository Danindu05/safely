import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/guardian_dashboard_viewmodel.dart';
import 'safemate_profile_screen.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardianDashboardViewModel>(
      create: (_) => GuardianDashboardViewModel(
        profileRepository: context.read<ProfileRepository>(),
        alertRepository: context.read<AlertRepository>(),
        guardianId: guardianId,
      ),
      child: _GuardianDashboardScreenBody(guardianId: guardianId),
    );
  }
}

class _GuardianDashboardScreenBody extends StatelessWidget {
  const _GuardianDashboardScreenBody({required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GuardianDashboardViewModel>(
      builder: (BuildContext context, GuardianDashboardViewModel viewModel, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Guardian dashboard')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              SectionCard(
                title: 'Linking ID',
                subtitle:
                    'Share this guardian ID with a Safemate to link accounts.',
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableText(
                        guardianId,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: guardianId),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Guardian ID copied.')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (viewModel.linkedSafemates.isEmpty)
                const EmptyStateCard(
                  icon: Icons.groups_outlined,
                  title: 'No linked Safemates yet',
                  message:
                      'Once a Safemate links this guardian ID, their status cards will appear here.',
                )
              else
                ...viewModel.linkedSafemates.map((user) {
                  final latestAlert = viewModel.latestAlertFor(user.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: user.name,
                      subtitle: user.email,
                      trailing: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SafemateProfileScreen(safemateId: user.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Emergency: ${user.isEmergencyActive ? 'Active' : 'Normal'}',
                          ),
                          const SizedBox(height: 6),
                          Text('Battery: ${user.batteryLevel ?? '--'}%'),
                          const SizedBox(height: 6),
                          Text(
                            'Last seen: ${user.lastSeenAt == null ? 'Unknown' : DateTimeFormatter.formatShort(user.lastSeenAt!)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Location freshness: ${user.lastLocationSyncAt == null ? 'No live data' : DateTimeFormatter.formatShort(user.lastLocationSyncAt!)}',
                          ),
                          if (latestAlert != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Text('Latest alert: ${latestAlert.title}'),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
