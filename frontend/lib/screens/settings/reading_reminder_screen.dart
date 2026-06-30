/// ReadingReminderScreen - Cai dat nhac nho doc sach
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../l10n/app_localizations.dart';

class ReadingReminderScreen extends StatefulWidget {
  const ReadingReminderScreen({super.key});

  @override
  State<ReadingReminderScreen> createState() => _ReadingReminderScreenState();
}

class _ReadingReminderScreenState extends State<ReadingReminderScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsService.isReadingReminderEnabled();
    final timeMap = await _settingsService.getReadingReminderTime();

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _time = TimeOfDay(hour: timeMap['hour']!, minute: timeMap['minute']!);
      _isLoading = false;
    });
  }

  Future<void> _updateEnabled(bool value) async {
    setState(() => _enabled = value);
    await _settingsService.setReadingReminderEnabled(value);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time == null || !mounted) return;
    setState(() => _time = time);
    await _settingsService.setReadingReminderTime(time.hour, time.minute);
  }

  Future<void> _save() async {
    await _settingsService.setReadingReminderEnabled(_enabled);
    await _settingsService.setReadingReminderTime(_time.hour, _time.minute);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _enabled
              ? '${S.of(context).t("reminder_enabled_at")} ${_time.format(context)}'
              : S.of(context).t('reminder_disabled_msg'),
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('reminder_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: AppSpacing.xl),
                        SettingsSectionCard(
                          title: S.of(context).t('reminder_schedule'),
                          subtitle:
                              S.of(context).t('reminder_schedule_desc'),
                          children: [
                            SettingsSwitchTile(
                              icon: Icons.notifications_active_outlined,
                              title: S.of(context).t('reminder_enable'),
                              subtitle:
                                  S.of(context).t('reminder_enable_desc'),
                              value: _enabled,
                              onChanged: _updateEnabled,
                            ),
                            if (_enabled)
                              SettingsTile(
                                icon: Icons.schedule_rounded,
                                title: S.of(context).t('reminder_time'),
                                subtitle:
                                    '${S.of(context).t('reminder_time')}: ${_time.format(context)}',
                                onTap: _selectTime,
                                trailing: _ReminderTimeChip(
                                  label: _time.format(context),
                                ),
                              ),
                          ],
                        ),
                        if (_enabled) ...[
                          const SizedBox(height: AppSpacing.xl),
                          ModernCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: S.of(context).t('reminder_suggest'),
                                  subtitle:
                                      S.of(context).t('reminder_suggest_desc'),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children:
                                      [
                                        {
                                          'label': S.of(context).t('reminder_morning'),
                                          'hour': 6,
                                          'minute': 30,
                                        },
                                        {
                                          'label': S.of(context).t('reminder_noon'),
                                          'hour': 12,
                                          'minute': 0,
                                        },
                                        {
                                          'label': S.of(context).t('reminder_evening'),
                                          'hour': 20,
                                          'minute': 0,
                                        },
                                        {
                                          'label': S.of(context).t('reminder_night'),
                                          'hour': 22,
                                          'minute': 0,
                                        },
                                      ].map((option) {
                                        final selected =
                                            _time.hour == option['hour'] &&
                                            _time.minute == option['minute'];
                                        return ChoiceChip(
                                          label: Text('${option['label']}'),
                                          selected: selected,
                                          selectedColor: AppColors.primarySoft,
                                          onSelected: (_) async {
                                            final newTime = TimeOfDay(
                                              hour: option['hour']! as int,
                                              minute: option['minute']! as int,
                                            );
                                            setState(() => _time = newTime);
                                            await _settingsService
                                                .setReadingReminderTime(
                                                  newTime.hour,
                                                  newTime.minute,
                                                );
                                          },
                                          labelStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: selected
                                                    ? AppColors.primary
                                                    : null,
                                              ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: PrimaryButton(
                      label: S.of(context).t('fc_settings_save'),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    final colors = _enabled
        ? AppGradients.warmHero.colors
        : const [Color(0xFFE5E7EB), Color(0xFFD1D5DB)];

    return ModernCard(
      gradient: LinearGradient(colors: colors),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _enabled ? AppColors.primary : AppColors.textSecondary,
              size: 38,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _enabled ? _time.format(context) : S.of(context).t('reminder_off'),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _enabled ? S.of(context).t('reminder_daily') : S.of(context).t('reminder_none'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReminderTimeChip extends StatelessWidget {
  final String label;

  const _ReminderTimeChip({required this.label});

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
