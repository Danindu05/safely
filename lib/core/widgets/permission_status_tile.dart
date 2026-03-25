import 'package:flutter/material.dart';

import '../../models/app_enums.dart';

class PermissionStatusTile extends StatelessWidget {
  const PermissionStatusTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String description;
  final AppPermissionState state;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String stateLabel = switch (state) {
      AppPermissionState.granted => 'Granted',
      AppPermissionState.denied => 'Needs action',
      AppPermissionState.permanentlyDenied => 'Open settings',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(description),
      trailing: TextButton(
        onPressed: onRequest,
        child: Text(stateLabel, style: theme.textTheme.labelLarge),
      ),
    );
  }
}
