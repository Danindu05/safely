import 'package:flutter/material.dart';

import '../theme/app_tone.dart';
import 'app_status_chip.dart';

class TimelineEventTile extends StatelessWidget {
  const TimelineEventTile({
    super.key,
    required this.icon,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.badge,
    this.statusLabel,
    this.tone = AppTone.neutral,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String timestamp;
  final String? subtitle;
  final Widget? badge;
  final String? statusLabel;
  final AppTone tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTonePalette.background(tone),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTonePalette.foreground(tone), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (trailing case final Widget trailingWidget)
                      trailingWidget,
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badge case final Widget badgeWidget) badgeWidget,
                    if (statusLabel != null)
                      AppStatusChip(
                        label: statusLabel!,
                        tone: tone,
                        compact: true,
                      ),
                  ],
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: child,
    );
  }
}
