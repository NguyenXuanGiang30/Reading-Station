/// ReadingGoalScreen - Cai dat muc tieu doc sach
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../l10n/app_localizations.dart';

class ReadingGoalScreen extends StatefulWidget {
  const ReadingGoalScreen({super.key});

  @override
  State<ReadingGoalScreen> createState() => _ReadingGoalScreenState();
}

class _ReadingGoalScreenState extends State<ReadingGoalScreen> {
  final SettingsService _settingsService = SettingsService();

  int _goal = 24;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await _settingsService.getReadingGoal();
    if (!mounted) return;
    setState(() {
      _goal = goal;
      _isLoading = false;
    });
  }

  Future<void> _saveGoal() async {
    await _settingsService.setReadingGoal(_goal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).t('goal_saved'))),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('goal_title'),
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
                        ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: S.of(context).t('goal_adjust'),
                                subtitle:
                                    S.of(context).t('goal_adjust_desc'),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Slider(
                                value: _goal.toDouble(),
                                min: 1,
                                max: 100,
                                divisions: 99,
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.primarySoft,
                                onChanged: (value) =>
                                    setState(() => _goal = value.round()),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    S.of(context).t('goal_min'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    S.of(context).t('goal_max'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ModernCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).t('goal_quick'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [6, 12, 24, 36, 52].map((value) {
                                  final isSelected = _goal == value;
                                  return ChoiceChip(
                                    label: Text('$value'),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        setState(() => _goal = value),
                                    selectedColor: AppColors.primarySoft,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: isSelected
                                              ? AppColors.primary
                                              : null,
                                        ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.tips_and_updates_outlined,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        S.of(context).t('goal_tip'),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: PrimaryButton(
                      label: S.of(context).t('goal_save'),
                      icon: const Icon(
                        Icons.flag_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _saveGoal,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return ModernCard(
      gradient: AppGradients.sunriseAccent,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_circle_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$_goal',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            S.of(context).t('goal_unit'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusChip(
                label: S.of(context).t('goal_current'),
                color: Colors.white,
                icon: Icons.auto_awesome_rounded,
              ),
              StatusChip(
                label: _goal >= 24 ? S.of(context).t('goal_ambitious') : S.of(context).t('goal_easy'),
                color: Colors.white,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
