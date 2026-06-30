/// HelpSupportScreen - Tro giup va ho tro
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
import '../../widgets/settings/settings_tile.dart';
import '../../l10n/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<bool> _expanded = [false, false, false, false, false];

  List<Map<String, dynamic>> _buildFaqs(BuildContext context) {
    return [
      {
        'question': S.of(context).t('help_faq1_q'),
        'answer': S.of(context).t('help_faq1_a'),
        'expanded': _expanded[0],
      },
      {
        'question': S.of(context).t('help_faq2_q'),
        'answer': S.of(context).t('help_faq2_a'),
        'expanded': _expanded[1],
      },
      {
        'question': S.of(context).t('help_faq3_q'),
        'answer': S.of(context).t('help_faq3_a'),
        'expanded': _expanded[2],
      },
      {
        'question': S.of(context).t('help_faq4_q'),
        'answer': S.of(context).t('help_faq4_a'),
        'expanded': _expanded[3],
      },
      {
        'question': S.of(context).t('help_faq5_q'),
        'answer': S.of(context).t('help_faq5_a'),
        'expanded': _expanded[4],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final _faqs = _buildFaqs(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('help_title'),
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
            _buildHeroCard(),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('help_contact_section'),
              subtitle:
                  S.of(context).t('help_contact_desc'),
              children: [
                SettingsTile(
                  icon: Icons.email_outlined,
                  title: S.of(context).t('help_email'),
                  subtitle: 'support@tramdoc.app',
                  onTap: () => _showSupportMessage(
                    S.of(context).t('help_email_msg'),
                  ),
                ),
                SettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: S.of(context).t('help_chat'),
                  subtitle: S.of(context).t('help_chat_hours'),
                  onTap: () => _showSupportMessage(
                    S.of(context).t('help_chat_coming'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: S.of(context).t('help_faq'),
              subtitle:
                  S.of(context).t('help_faq_desc'),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ModernCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: faq['expanded'] as bool,
                      onExpansionChanged: (expanded) =>
                          setState(() => _expanded[index] = expanded),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ),
                      title: Text(
                        '${faq['question']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      children: [
                        Text(
                          '${faq['answer']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('help_docs'),
              subtitle:
                  S.of(context).t('help_docs_desc'),
              children: [
                SettingsTile(
                  icon: Icons.book_outlined,
                  title: S.of(context).t('help_guide'),
                  subtitle: S.of(context).t('help_guide_desc'),
                  onTap: () =>
                      _showSupportMessage(S.of(context).t('help_coming_soon')),
                ),
                SettingsTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: S.of(context).t('help_video'),
                  subtitle: S.of(context).t('help_video_desc'),
                  onTap: () =>
                      _showSupportMessage(S.of(context).t('help_coming_soon')),
                ),
                SettingsTile(
                  icon: Icons.update_rounded,
                  title: S.of(context).t('help_changelog'),
                  subtitle: S.of(context).t('help_changelog_desc'),
                  onTap: () =>
                      _showSupportMessage(S.of(context).t('help_coming_soon')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('help_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('help_hero_desc'),
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

  void _showSupportMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
