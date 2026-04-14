import 'package:flutter/material.dart';

import '../theme/app_tone.dart';
import 'app_stat_card.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.emphasisColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? emphasisColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppStatCard(
        label: label,
        value: value,
        icon: icon,
        tone: emphasisColor == null ? AppTone.neutral : AppTone.info,
      ),
    );
  }
}
