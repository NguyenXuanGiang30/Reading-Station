/// NotificationSettingsScreen - Cai dat thong bao
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  static const String _goalProgressKey = 'notification_goal_progress';
  static const String _friendActivityKey = 'notification_friend_activity';
  static const String _achievementsKey = 'notification_achievements';
  static const String _appUpdatesKey = 'notification_app_updates';

  bool _readingReminder = true;
  bool _reviewReminder = true;
  bool _goalProgress = true;
  bool _friendActivity = false;
  bool _achievements = true;
  bool _appUpdates = false;

  TimeOfDay _readingTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _reviewTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final readingReminder = await _settingsService.isReadingReminderEnabled();
    final reviewReminder = await _settingsService.isReviewReminderEnabled();
    final readingTime = await _settingsService.getReadingReminderTime();
    final reviewTime = await _settingsService.getReviewReminderTime();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _readingReminder = readingReminder;
      _reviewReminder = reviewReminder;
      _readingTime = TimeOfDay(
        hour: readingTime['hour'] ?? 20,
        minute: readingTime['minute'] ?? 0,
      );
      _reviewTime = TimeOfDay(
        hour: reviewTime['hour'] ?? 9,
        minute: reviewTime['minute'] ?? 0,
      );
      _goalProgress = prefs.getBool(_goalProgressKey) ?? _goalProgress;
      _friendActivity = prefs.getBool(_friendActivityKey) ?? _friendActivity;
      _achievements = prefs.getBool(_achievementsKey) ?? _achievements;
      _appUpdates = prefs.getBool(_appUpdatesKey) ?? _appUpdates;
      _isLoading = false;
    });
  }

  Future<void> _saveLocalToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _updateReadingReminder(bool value) async {
    setState(() => _readingReminder = value);
    await _settingsService.setReadingReminderEnabled(value);
  }

  Future<void> _updateReviewReminder(bool value) async {
    setState(() => _reviewReminder = value);
    await _settingsService.setReviewReminderEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('notif_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSectionCard(
                    title: S.of(context).t('notif_reading_section'),
                    subtitle:
                        S.of(context).t('notif_reading_desc'),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.menu_book_rounded,
                        title: S.of(context).t('notif_reading_daily'),
                        subtitle:
                            S.of(context).t('notif_reading_daily_desc'),
                        value: _readingReminder,
                        onChanged: _updateReadingReminder,
                      ),
                      if (_readingReminder)
                        SettingsTile(
                          icon: Icons.schedule_rounded,
                          title: S.of(context).t('notif_reading_time'),
                          subtitle: '${S.of(context).t("notif_at")} ${_readingTime.format(context)}',
                          onTap: () => _selectTime(context, true),
                          trailing: _TimeBadge(label: _readingTime.format(context)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSectionCard(
                    title: S.of(context).t('notif_review_section'),
                    subtitle: S.of(context).t('notif_review_desc'),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.style_rounded,
                        title: S.of(context).t('notif_review_reminder'),
                        subtitle: S.of(context).t('notif_review_daily_desc'),
                        value: _reviewReminder,
                        onChanged: _updateReviewReminder,
                      ),
                      if (_reviewReminder)
                        SettingsTile(
                          icon: Icons.alarm_rounded,
                          title: S.of(context).t('notif_review_time'),
                          subtitle: '${S.of(context).t("notif_at")} ${_reviewTime.format(context)}',
                          onTap: () => _selectTime(context, false),
                          trailing: _TimeBadge(label: _reviewTime.format(context)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSectionCard(
                    title: S.of(context).t('notif_progress_section'),
                    subtitle:
                        S.of(context).t('notif_progress_desc'),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.flag_rounded,
                        title: S.of(context).t('notif_goal_progress'),
                        subtitle: S.of(context).t('notif_goal_progress_desc'),
                        value: _goalProgress,
                        onChanged: (value) async {
                          setState(() => _goalProgress = value);
                          await _saveLocalToggle(_goalProgressKey, value);
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.workspace_premium_rounded,
                        title: S.of(context).t('notif_achievements'),
                        subtitle: S.of(context).t('notif_achievements_desc'),
                        value: _achievements,
                        onChanged: (value) async {
                          setState(() => _achievements = value);
                          await _saveLocalToggle(_achievementsKey, value);
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.groups_2_rounded,
                        title: S.of(context).t('notif_friend_activity'),
                        subtitle: S.of(context).t('notif_friend_activity_desc'),
                        value: _friendActivity,
                        onChanged: (value) async {
                          setState(() => _friendActivity = value);
                          await _saveLocalToggle(_friendActivityKey, value);
                        },
                      ),
                      SettingsSwitchTile(
                        icon: Icons.system_update_alt_rounded,
                        title: S.of(context).t('notif_app_updates'),
                        subtitle: S.of(context).t('notif_app_updates_desc'),
                        value: _appUpdates,
                        onChanged: (value) async {
                          setState(() => _appUpdates = value);
                          await _saveLocalToggle(_appUpdatesKey, value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: S.of(context).t('notif_test_title'),
                          subtitle:
                              S.of(context).t('notif_test_desc'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: Text(S.of(context).t('notif_test_btn')),
                          ),
                        ),
                      ],
                    ),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('notif_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('notif_hero_desc'),
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

  Future<void> _selectTime(BuildContext context, bool isReading) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isReading ? _readingTime : _reviewTime,
    );

    if (time == null || !mounted) return;

    setState(() {
      if (isReading) {
        _readingTime = time;
      } else {
        _reviewTime = time;
      }
    });

    if (isReading) {
      await _settingsService.setReadingReminderTime(time.hour, time.minute);
    } else {
      await _settingsService.setReviewReminderTime(time.hour, time.minute);
    }
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).t('notif_test_msg'))),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final String label;

  const _TimeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}
