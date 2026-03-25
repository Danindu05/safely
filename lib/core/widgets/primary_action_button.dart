import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      icon: isBusy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
    );
  }
}
