import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tone.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/event_ui_mapper.dart';
import '../../core/widgets/alert_type_badge.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/app_status_chip.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/timeline_event_tile.dart';
import '../../models/app_enums.dart';
import '../../models/activity_log.dart';
import '../../models/safety_alert.dart';
import '../../models/safety_checkin.dart';
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
            final List<_HistoryEntry> entries = _entriesFor(viewModel);
            final Map<String, List<_HistoryEntry>> groupedEntries =
                <String, List<_HistoryEntry>>{};
            for (final _HistoryEntry entry in entries) {
              final String label = DateTimeFormatter.formatSectionLabel(
                entry.timestamp,
              );
              groupedEntries
                  .putIfAbsent(label, () => <_HistoryEntry>[])
                  .add(entry);
            }

            return Scaffold(
              appBar: AppBar(title: const Text('Activity history')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  const SectionCard(
                    child: AppSectionHeader(
                      title: 'Recent activity',
                      subtitle:
                          'Review alerts, check-ins, and monitoring events in one place.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: HistoryFilter.values
                          .map((HistoryFilter filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  _filterLabel(filter),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: viewModel.filter == filter,
                                showCheckmark: false,
                                selectedColor: AppColors.navy,
                                backgroundColor: AppColors.surfaceMuted,
                                side: BorderSide(
                                  color: viewModel.filter == filter
                                      ? AppColors.navy
                                      : AppColors.line,
                                ),
                                labelStyle: TextStyle(
                                  color: viewModel.filter == filter
                                      ? Colors.white
                                      : AppColors.navyDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                onSelected: (_) => viewModel.setFilter(filter),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.history_toggle_off_outlined,
                      title: 'No history yet',
                      message:
                          'Alerts, check-ins, battery warnings, and route events will appear here over time.',
                    )
                  else
                    ...groupedEntries.entries.map((
                      MapEntry<String, List<_HistoryEntry>> group,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                group.key,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            ...group.value.map(
                              (_HistoryEntry entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TimelineEventTile(
                                  icon: entry.icon,
                                  title: entry.title,
                                  subtitle: entry.subtitle,
                                  timestamp: DateTimeFormatter.formatShort(
                                    entry.timestamp,
                                  ),
                                  badge: entry.badge,
                                  statusLabel: entry.statusLabel,
                                  tone: entry.tone,
                                ),
                              ),
                            ),
                          ],
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

List<_HistoryEntry> _entriesFor(ActivityHistoryViewModel viewModel) {
  final List<_HistoryEntry> allEntries = <_HistoryEntry>[
    ...viewModel.alerts.map(_HistoryEntry.fromAlert),
    ...viewModel.checkIns.map(_HistoryEntry.fromCheckIn),
    ...viewModel.logs.map(_HistoryEntry.fromLog),
  ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return switch (viewModel.filter) {
    HistoryFilter.all => allEntries,
    HistoryFilter.alerts =>
      allEntries
          .where(
            (_HistoryEntry entry) => entry.category == _HistoryCategory.alert,
          )
          .toList(growable: false),
    HistoryFilter.checkins =>
      allEntries
          .where((entry) => entry.category == _HistoryCategory.checkIn)
          .toList(growable: false),
    HistoryFilter.battery =>
      allEntries
          .where((entry) => entry.category == _HistoryCategory.battery)
          .toList(growable: false),
    HistoryFilter.route =>
      allEntries
          .where((entry) => entry.category == _HistoryCategory.route)
          .toList(growable: false),
    HistoryFilter.geofence =>
      allEntries
          .where((entry) => entry.category == _HistoryCategory.geofence)
          .toList(growable: false),
    HistoryFilter.events =>
      allEntries
          .where((entry) => entry.category == _HistoryCategory.event)
          .toList(growable: false),
  };
}

String _filterLabel(HistoryFilter filter) {
  return switch (filter) {
    HistoryFilter.all => 'All',
    HistoryFilter.alerts => 'Alerts',
    HistoryFilter.checkins => 'Check-ins',
    HistoryFilter.battery => 'Battery',
    HistoryFilter.route => 'Route',
    HistoryFilter.geofence => 'Geofence',
    HistoryFilter.events => 'Events',
  };
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.category,
    this.badge,
    this.statusLabel,
  });

  final DateTime timestamp;
  final String title;
  final String subtitle;
  final IconData icon;
  final AppTone tone;
  final _HistoryCategory category;
  final Widget? badge;
  final String? statusLabel;

  factory _HistoryEntry.fromAlert(SafetyAlert alert) {
    return _HistoryEntry(
      timestamp: alert.timestamp,
      title: alert.title,
      subtitle: alert.description,
      icon: EventUiMapper.iconForAlertType(alert.type),
      tone: EventUiMapper.toneForAlertType(alert.type),
      category: switch (alert.type) {
        AlertType.lowBattery => _HistoryCategory.battery,
        AlertType.routeDeviation => _HistoryCategory.route,
        AlertType.geofence => _HistoryCategory.geofence,
        AlertType.manualCheckin ||
        AlertType.missedCheckin => _HistoryCategory.checkIn,
        AlertType.sos => _HistoryCategory.alert,
      },
      badge: AlertTypeBadge(type: alert.type, compact: true),
      statusLabel: alert.status.label,
    );
  }

  factory _HistoryEntry.fromCheckIn(SafetyCheckIn checkIn) {
    return _HistoryEntry(
      timestamp: checkIn.timestamp,
      title: '${checkIn.type.label} check-in',
      subtitle: checkIn.locationLat == null || checkIn.locationLng == null
          ? 'No location attached'
          : 'Location shared • ${checkIn.locationLat!.toStringAsFixed(5)}, ${checkIn.locationLng!.toStringAsFixed(5)}',
      icon: EventUiMapper.iconForCheckInType(checkIn.type),
      tone: EventUiMapper.toneForCheckInType(checkIn.type),
      category: _HistoryCategory.checkIn,
      badge: AppStatusChip(
        label: checkIn.type.label,
        tone: EventUiMapper.toneForCheckInType(checkIn.type),
        compact: true,
      ),
      statusLabel: checkIn.status.value,
    );
  }

  factory _HistoryEntry.fromLog(ActivityLog log) {
    return _HistoryEntry(
      timestamp: log.timestamp,
      title: log.eventType.label,
      subtitle: log.message,
      icon: EventUiMapper.iconForLogEvent(log.eventType),
      tone: EventUiMapper.toneForLogEvent(log.eventType),
      category: switch (log.eventType) {
        LogEventType.lowBatteryTriggered ||
        LogEventType.batteryEmergencyStarted => _HistoryCategory.battery,
        LogEventType.routeDeviation => _HistoryCategory.route,
        LogEventType.geofenceEntered => _HistoryCategory.geofence,
        LogEventType.checkIn ||
        LogEventType.missedCheckIn => _HistoryCategory.checkIn,
        _ => _HistoryCategory.event,
      },
    );
  }
}

enum _HistoryCategory { alert, checkIn, battery, route, geofence, event }
