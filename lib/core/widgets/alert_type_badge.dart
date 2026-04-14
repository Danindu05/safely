import 'package:flutter/material.dart';

import '../../models/app_enums.dart';
import '../utils/event_ui_mapper.dart';
import 'app_status_chip.dart';

class AlertTypeBadge extends StatelessWidget {
  const AlertTypeBadge({super.key, required this.type, this.compact = false});

  final AlertType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(
      label: type.label,
      tone: EventUiMapper.toneForAlertType(type),
      icon: EventUiMapper.iconForAlertType(type),
      compact: compact,
    );
  }
}
