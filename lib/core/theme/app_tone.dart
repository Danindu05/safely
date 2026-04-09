import 'package:flutter/material.dart';

import 'app_colors.dart';

enum AppTone { neutral, info, safe, warning, danger }

class AppTonePalette {
  const AppTonePalette._();

  static Color background(AppTone tone) {
    return switch (tone) {
      AppTone.neutral => AppColors.surfaceMuted,
      AppTone.info => AppColors.infoSoft,
      AppTone.safe => AppColors.tealSoft,
      AppTone.warning => AppColors.warningSoft,
      AppTone.danger => AppColors.emergencySoft,
    };
  }

  static Color foreground(AppTone tone) {
    return switch (tone) {
      AppTone.neutral => AppColors.navyDeep,
      AppTone.info => AppColors.info,
      AppTone.safe => AppColors.safe,
      AppTone.warning => AppColors.warning,
      AppTone.danger => AppColors.emergency,
    };
  }

  static Color border(AppTone tone) {
    return foreground(tone).withValues(alpha: 0.16);
  }
}
