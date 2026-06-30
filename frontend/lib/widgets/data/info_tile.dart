library;

import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(label, style: textTheme.bodySmall)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
