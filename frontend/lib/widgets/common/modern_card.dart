library;

import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool elevated;
  final Border? border;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    this.elevated = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: gradient == null ? Theme.of(context).colorScheme.surface : null,
        gradient: gradient,
        borderRadius: AppRadius.card,
        border: border,
        boxShadow: elevated ? AppShadows.elevated : AppShadows.soft,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: AppRadius.card, child: card),
    );
  }
}
