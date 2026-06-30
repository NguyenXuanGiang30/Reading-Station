/// ReviewHubScreen - Trung tâm ôn tập flashcard
library;

import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';

class ReviewHubScreen extends StatefulWidget {
  const ReviewHubScreen({super.key});

  @override
  State<ReviewHubScreen> createState() => _ReviewHubScreenState();
}

class _ReviewHubScreenState extends State<ReviewHubScreen> {
  final FlashcardService _service = FlashcardService();

  bool _isLoading = true;
  String? _error;

  List<FlashcardDeck> _decks = [];
  Map<String, dynamic> _statistics = {};
  int _dueCardsCount = 0;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getDecks(),
        _service.getStatistics(),
        _service.getTodaySummary(),
      ]);

      if (!mounted) return;
      final decks = results[0] as List<FlashcardDeck>;
      final stats = results[1] as Map<String, dynamic>;
      final today = results[2] as Map<String, dynamic>;

      setState(() {
        _decks = decks;
        _statistics = stats;
        _dueCardsCount = today['due'] as int? ?? 0;
        _streakDays = stats['streak'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: LoadingWidget(
            fullScreen: true,
            message: S.of(context).t('review_loading'),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: ErrorStateWidget(
            message: _error!,
            onRetry: _loadData,
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOverviewSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildDeckSection(context),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _dueCardsCount > 0
              ? FloatingActionButton.extended(
                onPressed: () => context.push('/flashcard/session'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(S.of(context).t('review_start_btn')),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.warmHero),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      S.of(context).t('review_title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings/flashcard'),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      context.push('/flashcard/create').then((_) => _loadData());
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                S.of(context).t('review_desc'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _TopMetricChip(
                      icon: Icons.style_rounded,
                      value: '$_dueCardsCount',
                      label: S.of(context).t('review_due_cards'),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TopMetricChip(
                      icon: Icons.local_fire_department_rounded,
                      value: '$_streakDays',
                      label: S.of(context).t('review_streak'),
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              if (_dueCardsCount > 0) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: S.of(context).t('review_start'),
                  expand: false,
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => context.push('/flashcard/session'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context) {
    final totalCards =
        _statistics['totalCards'] as int? ??
        _decks.fold<int>(0, (sum, deck) => sum + deck.totalCards);
    final masteredCards = _statistics['masteredCards'] as int? ?? 0;
    final masteryPercent =
        totalCards > 0 ? (masteredCards / totalCards * 100).round() : 0;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('review_overview'),
            subtitle: S.of(context).t('review_overview_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  value: '$totalCards',
                  label: S.of(context).t('review_total_cards'),
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _OverviewMetric(
                  value: '$masteredCards',
                  label: S.of(context).t('review_mastered'),
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _OverviewMetric(
                  value: '$masteryPercent%',
                  label: S.of(context).t('review_mastery'),
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeckSection(BuildContext context) {
    if (_decks.isEmpty) {
      return EmptyStateWidget(
        title: S.of(context).t('review_no_deck'),
        message: S.of(context).t('review_no_deck_msg'),
        icon: Icons.style_outlined,
        actionLabel: S.of(context).t('review_create_fc'),
        onAction: () => context.push('/flashcard/create'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('review_your_decks'),
          subtitle: '${_decks.length} ${S.of(context).t('review_decks_subtitle')}',
          trailing: TextButton(
            onPressed: () => context.push('/flashcard/create'),
            child: Text(S.of(context).t('review_add_new')),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._decks.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _decks.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _DeckCard(
              deck: entry.value,
              index: entry.key,
            ),
          );
        }),
      ],
    );
  }
}

class _TopMetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _TopMetricChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
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

class _OverviewMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _OverviewMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  final FlashcardDeck deck;
  final int index;

  const _DeckCard({required this.deck, required this.index});

  @override
  Widget build(BuildContext context) {
    final total = deck.totalCards;
    final due = deck.dueCards;
    final mastered = deck.masteredCards;
    final masteryPercent = total > 0 ? mastered / total : 0.0;
    final gradient = AppColors.deckGradients[index % AppColors.deckGradients.length];

    return ModernCard(
      gradient: gradient,
      elevated: true,
      onTap:
          due > 0 ? () => context.push('/flashcard/session?deckId=${deck.userBookId}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.bookTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      due > 0
                          ? '$due ${S.of(context).t('review_due_msg')}'
                          : S.of(context).t('review_done_msg'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  due > 0 ? S.of(context).t('review_need') : S.of(context).t('review_done'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: masteryPercent,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.26),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _DeckStat(
                value: '$total',
                label: S.of(context).t('review_total_cards'),
              ),
              const SizedBox(width: AppSpacing.xl),
              _DeckStat(
                value: '$mastered',
                label: S.of(context).t('review_mastered'),
              ),
              const Spacer(),
              Text(
                '${(masteryPercent * 100).round()}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckStat extends StatelessWidget {
  final String value;
  final String label;

  const _DeckStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
