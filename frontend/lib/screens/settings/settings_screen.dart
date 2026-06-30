/// SettingsScreen - Cai dat ung dung
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  int _readingGoal = 24;
  int _cardsPerSession = 20;
  String _language = 'vi';
  TimeOfDay _readingTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _reviewTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final goal = await _settingsService.getReadingGoal();
    final cards = await _settingsService.getCardsPerSession();
    final language = await _settingsService.getLanguage();
    final readingTimeMap = await _settingsService.getReadingReminderTime();
    final reviewTimeMap = await _settingsService.getReviewReminderTime();

    if (!mounted) return;
    setState(() {
      _readingGoal = goal;
      _cardsPerSession = cards;
      _language = language;
      _readingTime = TimeOfDay(
        hour: readingTimeMap['hour']!,
        minute: readingTimeMap['minute']!,
      );
      _reviewTime = TimeOfDay(
        hour: reviewTimeMap['hour']!,
        minute: reviewTimeMap['minute']!,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDarkMode = themeCubit.state == ThemeMode.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('settings_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body:
          _isLoading
              ? SafeArea(
                child: LoadingWidget(
                  fullScreen: true,
                  message: S.of(context).t('settings_loading'),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ModernCard(
                    gradient: AppGradients.warmHero,
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: S.of(context).t('settings_hero_title'),
                          subtitle:
                              S.of(context).t('settings_hero_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            _TopStatChip(
                              icon: Icons.flag_outlined,
                              label: S.of(context).t('settings_chip_goal'),
                              value: '$_readingGoal sach',
                            ),
                            _TopStatChip(
                              icon: Icons.language_outlined,
                              label: S.of(context).t('settings_language'),
                              value: _language == 'vi' ? S.of(context).t('lang_vi') : S.of(context).t('lang_en'),
                            ),
                            _TopStatChip(
                              icon: Icons.style_outlined,
                              label: S.of(context).t('search_flashcards'),
                              value: '$_cardsPerSession the',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionCard(
                    title: S.of(context).t('settings_account'),
                    subtitle: S.of(context).t('settings_account_desc'),
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: S.of(context).t('profile_edit_profile'),
                        subtitle: S.of(context).t('profile_edit_subtitle'),
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        title: S.of(context).t('change_pw_title'),
                        subtitle: S.of(context).t('settings_change_pw_desc'),
                        onTap: () => context.push('/settings/change-password'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: S.of(context).t('privacy_title'),
                        subtitle: S.of(context).t('settings_privacy_desc'),
                        onTap: () => context.push('/settings/privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionCard(
                    title: S.of(context).t('settings_app'),
                    subtitle: S.of(context).t('settings_app_desc'),
                    children: [
                      _SettingsSwitchTile(
                        icon: Icons.dark_mode_outlined,
                        title: S.of(context).t('settings_dark_mode'),
                        subtitle: S.of(context).t('settings_dark_mode_desc'),
                        value: isDarkMode,
                        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: S.of(context).t('notif_title'),
                        subtitle: S.of(context).t('settings_notif_desc'),
                        onTap: () => context.push('/settings/notifications'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.language_outlined,
                        title: S.of(context).t('lang_title'),
                        subtitle: _language == 'vi' ? S.of(context).t('lang_vi') : S.of(context).t('lang_en'),
                        onTap: () async {
                          await context.push('/settings/language');
                          _loadSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionCard(
                    title: S.of(context).t('settings_reading_goal'),
                    subtitle: S.of(context).t('settings_goal_desc'),
                    children: [
                      _SettingsTile(
                        icon: Icons.flag_circle_outlined,
                        title: S.of(context).t('goal_yearly'),
                        subtitle: '$_readingGoal cuon sach',
                        onTap: () async {
                          await context.push('/settings/reading-goal');
                          _loadSettings();
                        },
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.schedule_outlined,
                        title: S.of(context).t('settings_reminder'),
                        subtitle: '${_readingTime.format(context)} moi ngay',
                        onTap: () async {
                          await context.push('/settings/reading-reminder');
                          _loadSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionCard(
                    title: S.of(context).t('settings_learning'),
                    subtitle: S.of(context).t('settings_learning_desc'),
                    children: [
                      _SettingsTile(
                        icon: Icons.style_outlined,
                        title: S.of(context).t('fc_settings_title'),
                        subtitle:
                            '$_cardsPerSession the moi phien • ${_reviewTime.format(context)}',
                        onTap: () async {
                          await context.push('/settings/flashcard');
                          _loadSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSectionCard(
                    title: S.of(context).t('settings_data_support'),
                    subtitle: S.of(context).t('settings_data_support_desc'),
                    children: [
                      _SettingsTile(
                        icon: Icons.folder_outlined,
                        title: S.of(context).t('data_title'),
                        subtitle: S.of(context).t('settings_data_desc'),
                        onTap: () => context.push('/settings/data'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: S.of(context).t('settings_about'),
                        onTap: () => context.push('/settings/about'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: S.of(context).t('terms_title'),
                        onTap: () => context.push('/settings/terms'),
                      ),
                      const Divider(height: 1, indent: 68),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: S.of(context).t('help_title'),
                        onTap: () => context.push('/settings/help'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    label: Text(
                      S.of(context).t('settings_logout'),
                      style: const TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Text(
                      S.of(context).t('about_version_label'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.lg),
        ModernCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(S.of(context).t('settings_logout')),
            content: Text(S.of(context).t('settings_logout_confirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.of(context).t('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                  context.go('/login');
                },
                child: Text(S.of(context).t('settings_logout')),
              ),
            ],
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle:
          subtitle == null
              ? null
              : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      secondary: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _TopStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TopStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
