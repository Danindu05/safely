import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusChip.safe(String label) {
    return const StatusChip(label: 'Safe', color: AppColors.safe);
  }

  factory StatusChip.monitoring(String label) {
    return const StatusChip(label: 'Monitoring', color: AppColors.warning);
  }

  factory StatusChip.emergency(String label) {
    return const StatusChip(
      label: 'Emergency active',
      color: AppColors.emergency,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      label: Text(label),
    );
  }
}
