import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../repositories/alert_repository.dart';
import '../../viewmodels/activity_history_viewmodel.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActivityHistoryViewModel>(
      create: (_) => ActivityHistoryViewModel(
        alertRepository: context.read<AlertRepository>(),
        userId: userId,
      ),
      child: const _ActivityHistoryScreenBody(),
    );
  }
}

class _ActivityHistoryScreenBody extends StatelessWidget {
  const _ActivityHistoryScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityHistoryViewModel>(
      builder:
          (
            BuildContext context,
            ActivityHistoryViewModel viewModel,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('Activity history')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    children: HistoryFilter.values
                        .map((HistoryFilter filter) {
                          return ChoiceChip(
                            label: Text(filter.name),
                            selected: viewModel.filter == filter,
                            onSelected: (_) => viewModel.setFilter(filter),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.filter == HistoryFilter.all ||
                      viewModel.filter == HistoryFilter.alerts)
                    ...viewModel.alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SectionCard(
                          title: alert.title,
                          subtitle: DateTimeFormatter.formatShort(
                            alert.timestamp,
                          ),
                          child: Text(alert.description),
                        ),
                      ),
                    ),
                  if (viewModel.filter == HistoryFilter.all ||
                      viewModel.filter == HistoryFilter.checkins)
                    ...viewModel.checkIns.map(
                      (checkIn) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SectionCard(
                          title: '${checkIn.type.label} check-in',
                          subtitle: DateTimeFormatter.formatShort(
                            checkIn.timestamp,
                          ),
                          child: Text(checkIn.status.value),
                        ),
                      ),
                    ),
                  if (viewModel.filter == HistoryFilter.all ||
                      viewModel.filter == HistoryFilter.logs)
                    ...viewModel.logs.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SectionCard(
                          title: log.eventType.label,
                          subtitle: DateTimeFormatter.formatShort(
                            log.timestamp,
                          ),
                          child: Text(log.message),
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
