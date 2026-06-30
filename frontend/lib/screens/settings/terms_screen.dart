/// TermsScreen - Dieu khoan su dung
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Map<String, String>>[
      {
        'title': S.of(context).t('terms_s1_title'),
        'content':
            S.of(context).t('terms_s1_content'),
      },
      {
        'title': S.of(context).t('terms_s2_title'),
        'content':
            S.of(context).t('terms_s2_content'),
      },
      {
        'title': S.of(context).t('terms_s3_title'),
        'content':
            S.of(context).t('terms_s3_content'),
      },
      {
        'title': S.of(context).t('terms_s4_title'),
        'content':
            S.of(context).t('terms_s4_content'),
      },
      {
        'title': S.of(context).t('terms_s5_title'),
        'content':
            S.of(context).t('terms_s5_content'),
      },
      {
        'title': S.of(context).t('terms_s6_title'),
        'content':
            S.of(context).t('terms_s6_content'),
      },
      {
        'title': S.of(context).t('terms_s7_title'),
        'content':
            S.of(context).t('terms_s7_content'),
      },
      {
        'title': S.of(context).t('terms_s8_title'),
        'content':
            S.of(context).t('terms_s8_content'),
      },
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('terms_title'),
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
            ModernCard(
              gradient: AppGradients.warmHero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).t('terms_title'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    S.of(context).t('terms_updated'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    S.of(context).t('terms_intro'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section['title']!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        section['content']!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ModernCard(
              padding: const EdgeInsets.all(20),
              gradient: AppGradients.softGlassOverlay,
              child: SectionHeader(
                title: S.of(context).t('terms_need_help'),
                subtitle:
                    S.of(context).t('terms_need_help_desc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
