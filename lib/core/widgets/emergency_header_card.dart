import 'package:flutter/material.dart';

import '../theme/app_tone.dart';
import 'app_status_chip.dart';

class EmergencyHeaderCard extends StatelessWidget {
  const EmergencyHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.statusLabel,
    required this.statusTone,
    this.trailing,
    this.isEmergency = false,
  });

  final String title;
  final String subtitle;
  final Widget badge;
  final String statusLabel;
  final AppTone statusTone;
  final Widget? trailing;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEmergency
              ? <Color>[const Color(0xFFFCE9EB), Colors.white]
              : <Color>[const Color(0xFFEAF0F8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isEmergency
              ? AppTonePalette.border(AppTone.danger)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    badge,
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppStatusChip(label: statusLabel, tone: statusTone),
        ],
      ),
    );
  }
}
