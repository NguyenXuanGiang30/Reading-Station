/// FlashcardSettingsScreen - Cai dat Flashcard
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

class FlashcardSettingsScreen extends StatefulWidget {
  const FlashcardSettingsScreen({super.key});

  @override
  State<FlashcardSettingsScreen> createState() =>
      _FlashcardSettingsScreenState();
}

class _FlashcardSettingsScreenState extends State<FlashcardSettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  int _cardsPerSession = 20;
  bool _reviewReminderEnabled = true;
  TimeOfDay _reviewTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  final List<int> _cardOptions = [5, 10, 15, 20, 25, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cards = await _settingsService.getCardsPerSession();
    final reminderEnabled = await _settingsService.isReviewReminderEnabled();
    final timeMap = await _settingsService.getReviewReminderTime();

    if (!mounted) return;
    setState(() {
      _cardsPerSession = cards;
      _reviewReminderEnabled = reminderEnabled;
      _reviewTime = TimeOfDay(
        hour: timeMap['hour']!,
        minute: timeMap['minute']!,
      );
      _isLoading = false;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reviewTime,
    );
    if (time == null || !mounted) return;

    setState(() => _reviewTime = time);
    await _settingsService.setReviewReminderTime(time.hour, time.minute);
  }

  Future<void> _save() async {
    await _settingsService.setCardsPerSession(_cardsPerSession);
    await _settingsService.setReviewReminderEnabled(_reviewReminderEnabled);
    await _settingsService.setReviewReminderTime(
      _reviewTime.hour,
      _reviewTime.minute,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).t('fc_settings_saved'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('fc_settings_title'),
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
                          title: S.of(context).t('fc_settings_cards_section'),
                          subtitle:
                              S.of(context).t('fc_settings_cards_desc'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.sunriseAccent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.style_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          '$_cardsPerSession the',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: _cardOptions.map((value) {
                                      final isSelected =
                                          _cardsPerSession == value;
                                      return ChoiceChip(
                                        label: Text('$value'),
                                        selected: isSelected,
                                        selectedColor: AppColors.primarySoft,
                                        onSelected: (_) => setState(
                                          () => _cardsPerSession = value,
                                        ),
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: isSelected
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
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SettingsSectionCard(
                          title: S.of(context).t('fc_settings_reminder'),
                          subtitle:
                              S.of(context).t('fc_settings_reminder_desc'),
                          children: [
                            SettingsSwitchTile(
                              icon: Icons.notifications_active_outlined,
                              title: S.of(context).t('fc_settings_enable_reminder'),
                              subtitle:
                                  S.of(context).t('fc_settings_notify_desc'),
                              value: _reviewReminderEnabled,
                              onChanged: (value) => setState(
                                () => _reviewReminderEnabled = value,
                              ),
                            ),
                            if (_reviewReminderEnabled)
                              SettingsTile(
                                icon: Icons.schedule_rounded,
                                title: S.of(context).t('fc_settings_review_time'),
                                subtitle:
                                    '${S.of(context).t("notif_at")} ${_reviewTime.format(context)}',
                                onTap: _selectTime,
                                trailing: _ReviewTimeChip(
                                  label: _reviewTime.format(context),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: SectionHeader(
                            title: S.of(context).t('fc_settings_tips'),
                            subtitle:
                                S.of(context).t('fc_settings_tips_desc'),
                          ),
                        ),
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
    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.style_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('fc_settings_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('fc_settings_hero_desc'),
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

class _ReviewTimeChip extends StatelessWidget {
  final String label;

  const _ReviewTimeChip({required this.label});

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
