import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tone.dart';
import 'app_status_chip.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  factory StatusChip.safe(String label) {
    return StatusChip(label: label, color: AppColors.safe);
  }

  factory StatusChip.monitoring(String label) {
    return StatusChip(label: label, color: AppColors.warning);
  }

  factory StatusChip.emergency(String label) {
    return StatusChip(label: label, color: AppColors.emergency);
  }

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(label: label, tone: _toneForColor(color));
  }

  AppTone _toneForColor(Color value) {
    if (value == AppColors.emergency) {
      return AppTone.danger;
    }
    if (value == AppColors.warning) {
      return AppTone.warning;
    }
    if (value == AppColors.safe || value == AppColors.green) {
      return AppTone.safe;
    }
    return AppTone.neutral;
  }
}
