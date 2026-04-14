import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isBusy = false,
    this.backgroundColor,
    this.foregroundColor,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Widget button = FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(expanded ? AppConstants.buttonHeight : 52),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      icon: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: button,
    );
  }
}
