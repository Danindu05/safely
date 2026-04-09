import 'package:flutter/material.dart';

import '../theme/app_tone.dart';
import 'app_status_chip.dart';

class GuardianMapInfoCard extends StatelessWidget {
  const GuardianMapInfoCard({
    super.key,
    required this.name,
    required this.statusLabel,
    required this.connectionLabel,
    required this.connectionTone,
    required this.batteryLabel,
    required this.lastUpdatedLabel,
    required this.sourceLabel,
    required this.isEmergencyActive,
  });

  final String name;
  final String statusLabel;
  final String connectionLabel;
  final AppTone connectionTone;
  final String batteryLabel;
  final String lastUpdatedLabel;
  final String sourceLabel;
  final bool isEmergencyActive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEmergencyActive
              ? AppTonePalette.border(AppTone.danger)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140A1730),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppStatusChip(
                label: statusLabel,
                tone: isEmergencyActive ? AppTone.danger : AppTone.safe,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              AppStatusChip(
                label: connectionLabel,
                tone: connectionTone,
                compact: true,
              ),
              AppStatusChip(
                label: batteryLabel,
                tone:
                    batteryLabel.contains('critical') ||
                        batteryLabel.contains('low')
                    ? AppTone.warning
                    : AppTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lastUpdatedLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sourceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
