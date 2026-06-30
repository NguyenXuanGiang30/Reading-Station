library;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../common/modern_card.dart';
import '../common/section_header.dart';

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.lg),
        ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
