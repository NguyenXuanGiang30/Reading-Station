/// FlashcardSessionScreen - Phien on tap flashcard
library;

import 'package:flip_card/flip_card.dart';
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
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class FlashcardSessionScreen extends StatefulWidget {
  final String? deckId;

  const FlashcardSessionScreen({super.key, this.deckId});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  final FlashcardService _service = FlashcardService();
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();

  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _sessionComplete = false;
  bool _isLoading = true;
  String? _error;

  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalCards = 0;

  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cards = await _service.getDueCards(deckId: widget.deckId, limit: 20);
      if (!mounted) return;
      setState(() {
        _flashcards = cards;
        _totalCards = cards.length;
        _isLoading = false;
        if (cards.isEmpty) {
          _sessionComplete = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextCard() {
    if (_cardKey.currentState?.isFront == false) {
      _cardKey.currentState?.toggleCard();
    }

    setState(() {
      _showAnswer = false;
      if (_currentIndex < _flashcards.length - 1) {
        _currentIndex++;
      } else {
        _sessionComplete = true;
      }
    });
  }

  Future<void> _rateCard(int quality) async {
    if (quality >= 2) {
      _correctCount++;
    } else {
      _incorrectCount++;
    }

    try {
      final card = _flashcards[_currentIndex];
      await _service.submitReview(card.id, quality);
    } catch (_) {
      // Keep session smooth even if review persistence fails temporarily.
    }

    _nextCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/review'),
          ),
        ),
        body: SafeArea(
          child: LoadingWidget(
            fullScreen: true,
            message: S.of(context).t('fc_session_loading'),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go('/review'),
          ),
        ),
        body: SafeArea(
          child: ErrorStateWidget(
            message: _error!,
            onRetry: _loadFlashcards,
          ),
        ),
      );
    }

    if (_sessionComplete) {
      return _buildCompletionScreen(context);
    }

    final currentCard = _flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(),
        ),
        centerTitle: true,
        title: Text('${_currentIndex + 1} / ${_flashcards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSessionSettings(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ModernCard(
                gradient: AppGradients.warmHero,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SessionBadge(
                            icon: Icons.check_circle_rounded,
                            value: '$_correctCount',
                            label: S.of(context).t('summary_correct'),
                            color: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _SessionBadge(
                            icon: Icons.cancel_rounded,
                            value: '$_incorrectCount',
                            label: S.of(context).t('summary_wrong'),
                            color: AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _SessionBadge(
                            icon: Icons.menu_book_rounded,
                            value: '${currentCard.interval}',
                            label: S.of(context).t('fc_cycle'),
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / _flashcards.length,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _buildFlashcard(currentCard),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child:
                  _showAnswer
                      ? _buildRatingButtons()
                      : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: PrimaryButton(
                          label: S.of(context).t('fc_session_flip'),
                          icon: const Icon(
                            Icons.flip_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _cardKey.currentState?.toggleCard(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcard(Flashcard card) {
    return FlipCard(
      key: _cardKey,
      direction: FlipDirection.HORIZONTAL,
      flipOnTouch: true,
      onFlip: () {
        setState(() {
          _showAnswer = true;
        });
      },
      front: _buildCardSide(
        label: S.of(context).t('fc_session_front'),
        content: card.question,
        gradient: AppColors.primaryGradient,
        footer:
            card.bookTitle == null || card.bookTitle!.isEmpty
                ? S.of(context).t('fc_tap_flip')
                : '${S.of(context).t("fc_from_book")}: ${card.bookTitle}',
      ),
      back: _buildCardSide(
        label: S.of(context).t('fc_session_back'),
        content: card.answer,
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8F83), Color(0xFF67C5B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        footer: S.of(context).t('fc_rate_below'),
      ),
    );
  }

  Widget _buildCardSide({
    required String label,
    required String content,
    required Gradient gradient,
    required String footer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Text(
              footer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Padding(
      key: const ValueKey('rating-buttons'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Text(
            S.of(context).t('fc_how_well'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: S.of(context).t('fc_forgot'),
                  color: AppColors.error,
                  onTap: () => _rateCard(0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RatingButton(
                  label: S.of(context).t('fc_session_hard'),
                  color: AppColors.warning,
                  onTap: () => _rateCard(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RatingButton(
                  label: S.of(context).t('fc_session_good'),
                  color: AppColors.info,
                  onTap: () => _rateCard(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RatingButton(
                  label: S.of(context).t('fc_session_easy'),
                  color: AppColors.success,
                  onTap: () => _rateCard(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen(BuildContext context) {
    final accuracy =
        _totalCards > 0 ? (_correctCount / _totalCards * 100).round() : 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.sunriseAccent),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => context.go('/review'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                Text(
                  S.of(context).t('fc_session_complete'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${S.of(context).t("fc_session_done_desc")}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  textAlign: TextAlign.center,
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
                            child: _SummaryBadge(
                              label: S.of(context).t('summary_correct'),
                              value: '$_correctCount',
                              color: AppColors.success,
                            ),
                          ),
                          Expanded(
                            child: _SummaryBadge(
                              label: S.of(context).t('summary_wrong'),
                              value: '$_incorrectCount',
                              color: AppColors.error,
                            ),
                          ),
                          Expanded(
                            child: _SummaryBadge(
                              label: S.of(context).t('summary_accuracy'),
                              value: '$accuracy%',
                              color: accuracy >= 70 ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: accuracy / 100,
                          minHeight: 10,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accuracy >= 70 ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _restartSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: Text(S.of(context).t('fc_session_again')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.go('/review'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(S.of(context).t('fc_finish')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _incorrectCount = 0;
      _sessionComplete = false;
      _showAnswer = false;
    });
  }

  void _showExitConfirmation() {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(S.of(context).t('fc_exit_title')),
            content: Text(S.of(context).t('fc_exit_msg')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.of(context).t('focus_resume')),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/review');
                },
                child: Text(S.of(context).t('focus_stop')),
              ),
            ],
          ),
    );
  }

  void _showSessionSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('fc_settings_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('fc_settings_desc'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SheetActionTile(
                  icon: Icons.format_list_numbered_rounded,
                  title: S.of(context).t('fc_max_cards'),
                  subtitle: S.of(context).t('fc_max_cards_desc'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SheetActionTile(
                  icon: Icons.shuffle_rounded,
                  title: S.of(context).t('fc_shuffle'),
                  subtitle: S.of(context).t('fc_shuffle_desc'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SheetActionTile(
                  icon: Icons.schedule_rounded,
                  title: S.of(context).t('fc_auto_flip'),
                  subtitle: S.of(context).t('fc_auto_flip_desc'),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      this.context.push('/settings/flashcard');
                    },
                    child: Text(S.of(context).t('fc_open_settings')),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SessionBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
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

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
