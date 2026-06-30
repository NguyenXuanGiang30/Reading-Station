/// AboutScreen - Thong tin ve ung dung
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('about_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: AppSpacing.xl),
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: SectionHeader(
                title: S.of(context).t('about_spirit'),
                subtitle:
                    S.of(context).t('about_desc'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('about_features'),
              subtitle:
                  S.of(context).t('about_features_desc'),
              children: [
                _FeatureRow(
                  icon: Icons.library_books_outlined,
                  text: S.of(context).t('about_f1'),
                ),
                _FeatureRow(
                  icon: Icons.edit_note_outlined,
                  text: S.of(context).t('about_f2'),
                ),
                _FeatureRow(
                  icon: Icons.style_rounded,
                  text: S.of(context).t('about_f3'),
                ),
                _FeatureRow(
                  icon: Icons.timer_outlined,
                  text: S.of(context).t('about_f4'),
                ),
                _FeatureRow(
                  icon: Icons.camera_alt_outlined,
                  text: S.of(context).t('about_f5'),
                ),
                _FeatureRow(
                  icon: Icons.groups_2_outlined,
                  text: S.of(context).t('about_f6'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('about_tech'),
              subtitle:
                  S.of(context).t('about_tech_desc'),
              children: [
                _TechWrap(
                  labels: [
                    'Flutter',
                    'Material 3',
                    'Spring Boot',
                    'PostgreSQL',
                    'Google ML Kit',
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ModernCard(
              padding: const EdgeInsets.all(20),
              gradient: AppGradients.softGlassOverlay,
              child: Column(
                children: [
                  Text(
                    S.of(context).t('about_team'),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    S.of(context).t('about_made_in'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    S.of(context).t('about_version_label'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '© $currentYear ${S.of(context).t("about_brand")}. ${S.of(context).t("about_rights")}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return ModernCard(
      gradient: AppGradients.sunriseAccent,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            S.of(context).t('about_app_name'),
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            S.of(context).t('about_tagline'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(text, style: Theme.of(context).textTheme.titleMedium),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

class _TechWrap extends StatelessWidget {
  final List<String> labels;

  _TechWrap({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: labels
            .map(
              (label) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
