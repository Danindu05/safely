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
    final Color resolvedForeground = foregroundColor ?? Colors.white;
    final Widget button = FilledButton(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(expanded ? AppConstants.buttonHeight : 52),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (isBusy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(resolvedForeground),
              ),
            )
          else
            Icon(icon ?? Icons.arrow_forward, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: button,
    );
  }
}
