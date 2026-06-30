/// SessionSummaryScreen - Tong ket sau phien on tap flashcard
library;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../l10n/app_localizations.dart';

class SessionSummaryScreen extends StatefulWidget {
  final int totalCards;
  final int correctCards;
  final int incorrectCards;
  final int timeSpentSeconds;
  final String? deckName;

  const SessionSummaryScreen({
    super.key,
    required this.totalCards,
    required this.correctCards,
    required this.incorrectCards,
    this.timeSpentSeconds = 0,
    this.deckName,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  late final ConfettiController _confettiController;

  double get accuracy {
    if (widget.totalCards == 0) return 0;
    return widget.correctCards / widget.totalCards * 100;
  }

  String get headline {
    if (accuracy >= 90) return S.of(context).t('summary_excellent');
    if (accuracy >= 70) return S.of(context).t('summary_very_good');
    if (accuracy >= 50) return S.of(context).t('summary_good_progress');
    return S.of(context).t('summary_keep_going');
  }

  String get supportingCopy {
    if (accuracy >= 90) return S.of(context).t('summary_excellent_desc');
    if (accuracy >= 70) return S.of(context).t('summary_good_desc');
    if (accuracy >= 50) return S.of(context).t('summary_progress_desc');
    return S.of(context).t('summary_keep_going_desc');
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (accuracy >= 70) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds giay';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes phut $remainingSeconds giay';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.sunriseAccent,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.go('/review'),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    supportingCopy,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.deckName != null && widget.deckName!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.deckName!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.huge),
                  Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${accuracy.round()}%',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            S.of(context).t('summary_accuracy'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.huge),
                  ModernCard(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.96),
                        Colors.white.withValues(alpha: 0.88),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetric(
                                value: '${widget.totalCards}',
                                label: S.of(context).t('summary_total'),
                                color: AppColors.info,
                                icon: Icons.style_rounded,
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                value: '${widget.correctCards}',
                                label: S.of(context).t('summary_correct'),
                                color: AppColors.success,
                                icon: Icons.check_circle_rounded,
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                value: '${widget.incorrectCards}',
                                label: S.of(context).t('summary_wrong'),
                                color: AppColors.error,
                                icon: Icons.cancel_rounded,
                              ),
                            ),
                          ],
                        ),
                        if (widget.timeSpentSeconds > 0) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: scoreColor,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    '${S.of(context).t("summary_time")} ${_formatTime(widget.timeSpentSeconds)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(S.of(context).t('summary_continue')),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: Text(S.of(context).t('summary_back_to_review')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.white,
                Color(0xFFFFF3B0),
                Color(0xFFFFD6A5),
                Color(0xFFCDEAC0),
                Color(0xFFBDE0FE),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor() {
    if (accuracy >= 70) return AppColors.success;
    if (accuracy >= 50) return AppColors.warning;
    return AppColors.primary;
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
