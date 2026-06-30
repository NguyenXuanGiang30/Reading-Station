library;

import 'package:flutter/material.dart';

import 'modern_card.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(padding: padding, child: child);
  }
}
