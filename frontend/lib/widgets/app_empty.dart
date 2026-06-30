import 'package:flutter/material.dart';

import 'states/empty_state_widget.dart';

class AppEmpty extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const AppEmpty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }
}
