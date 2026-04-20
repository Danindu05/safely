import 'package:flutter/material.dart';

import 'app_section_header.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null || subtitle != null || trailing != null)
              AppSectionHeader(
                title: title ?? '',
                subtitle: subtitle,
                trailing: trailing,
                compact: true,
              ),
            if (title != null || subtitle != null || trailing != null)
              const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
