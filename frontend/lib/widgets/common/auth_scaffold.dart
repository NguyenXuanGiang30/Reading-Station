library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? footer;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.footer,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.editorialSurface,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Icon(icon, color: Colors.white, size: 36),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(title, style: textTheme.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxxl),
                child,
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
