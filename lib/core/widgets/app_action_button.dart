import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

enum AppActionButtonTone { outlined, tonal, filled }

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = AppActionButtonTone.outlined,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppActionButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final ButtonStyle sharedStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size.fromHeight(AppConstants.buttonHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      alignment: Alignment.center,
    );

    return switch (tone) {
      AppActionButtonTone.outlined => OutlinedButton(
        onPressed: onPressed,
        style: sharedStyle,
        child: child,
      ),
      AppActionButtonTone.tonal => FilledButton.tonal(
        onPressed: onPressed,
        style: sharedStyle.copyWith(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.infoSoft,
          ),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.navyDeep,
          ),
        ),
        child: child,
      ),
      AppActionButtonTone.filled => FilledButton(
        onPressed: onPressed,
        style: sharedStyle,
        child: child,
      ),
    };
  }
}
