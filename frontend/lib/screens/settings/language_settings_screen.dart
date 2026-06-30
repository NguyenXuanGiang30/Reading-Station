/// LanguageSettingsScreen - Cài đặt ngôn ngữ
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/locale_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentCode = localeProvider.locale.languageCode;

    final languages = [
      {
        'code': 'vi',
        'name': s.t('lang_vi_name'),
        'subtitle': s.t('lang_vi_desc'),
      },
      {
        'code': 'en',
        'name': s.t('lang_en_name'),
        'subtitle': s.t('lang_en_desc'),
      },
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: s.t('settings_language'),
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
            SettingsSectionCard(
              title: s.t('lang_display_title'),
              subtitle: s.t('lang_display_desc'),
              children: languages.map((language) {
                final selected = currentCode == language['code'];

                return ListTile(
                  onTap: () {
                    localeProvider.setLocale(Locale(language['code']!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          language['code'] == 'vi'
                              ? s.t('lang_switched_vi')
                              : s.t('lang_switched_en'),
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    language['name']!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected ? AppColors.primary : null,
                        ),
                  ),
                  subtitle: Text(
                    language['subtitle']!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: selected
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            ModernCard(
              padding: const EdgeInsets.all(20),
              gradient: AppGradients.softGlassOverlay,
              child: SectionHeader(
                title: s.t('lang_note_title'),
                subtitle: s.t('lang_note_desc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final s = S.of(context);
    final isVi = s.t('nav_home') == 'Trang chủ';

    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('lang_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.t('lang_hero_desc'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
