import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../repositories/alert_repository.dart';
import '../../viewmodels/guardian_alerts_viewmodel.dart';
import 'alert_detail_screen.dart';

class GuardianAlertsScreen extends StatelessWidget {
  const GuardianAlertsScreen({super.key, required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardianAlertsViewModel>(
      create: (_) => GuardianAlertsViewModel(
        alertRepository: context.read<AlertRepository>(),
        guardianId: guardianId,
      ),
      child: _GuardianAlertsScreenBody(guardianId: guardianId),
    );
  }
}

class _GuardianAlertsScreenBody extends StatelessWidget {
  const _GuardianAlertsScreenBody({required this.guardianId});

  final String guardianId;

  @override
  Widget build(BuildContext context) {
    return Consumer<GuardianAlertsViewModel>(
      builder:
          (
            BuildContext context,
            GuardianAlertsViewModel viewModel,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('Guardian alerts')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  if (viewModel.alerts.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.notifications_off_outlined,
                      title: 'No alerts yet',
                      message:
                          'SOS, battery, geofence, and check-in alerts will appear here.',
                    )
                  else
                    ...viewModel.alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppConstants.cardRadius,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AlertDetailScreen(
                                  alertId: alert.id,
                                  guardianId: guardianId,
                                ),
                              ),
                            );
                          },
                          child: SectionCard(
                            title: alert.title,
                            subtitle: DateTimeFormatter.formatShort(
                              alert.timestamp,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${alert.type.label} • ${alert.status.label}',
                                ),
                                const SizedBox(height: 8),
                                Text(alert.description),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
    );
  }
}
