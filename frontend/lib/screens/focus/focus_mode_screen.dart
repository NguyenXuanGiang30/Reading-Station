/// FocusModeScreen - Che do doc tap trung Pomodoro
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/animated_button.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../l10n/app_localizations.dart';

class FocusModeScreen extends StatefulWidget {
  final String? bookId;
  final String? bookTitle;

  const FocusModeScreen({super.key, this.bookId, this.bookTitle});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  int _selectedDuration = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  bool _isCompleted = false;
  Timer? _timer;

  final List<int> _durations = [15, 25, 45, 60];
  List<Map<String, dynamic>> _getSounds(BuildContext context) => [
    {'name': S.of(context).t('focus_sound_none'), 'icon': Icons.volume_off_rounded},
    {'name': S.of(context).t('focus_sound_rain'), 'icon': Icons.water_drop_rounded},
    {'name': S.of(context).t('focus_sound_cafe'), 'icon': Icons.coffee_rounded},
    {'name': S.of(context).t('focus_sound_forest'), 'icon': Icons.forest_rounded},
    {'name': S.of(context).t('focus_sound_ocean'), 'icon': Icons.waves_rounded},
  ];
  int _selectedSound = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _remainingSeconds = _selectedDuration * 60;
    });
    _runTicker();
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    setState(() => _isRunning = true);
    _runTicker();
  }

  void _runTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isCompleted = true;
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _remainingSeconds = _selectedDuration * 60;
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  double get _progress {
    final total = _selectedDuration * 60;
    return (total - _remainingSeconds) / total;
  }

  String get _sessionLabel {
    if (_isCompleted) return S.of(context).t('focus_completed');
    if (_isRunning) return S.of(context).t('focus_focusing');
    if (_remainingSeconds != _selectedDuration * 60) return S.of(context).t('focus_ready_resume');
    return S.of(context).t('focus_ready_start');
  }

  Future<bool> _handleExitRequest() async {
    if (!_isRunning) return true;
    _showExitDialog();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isRunning,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_isRunning) return;
        _showExitDialog();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF211A2E),
                    Color(0xFF17192B),
                    Color(0xFF11131D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -60,
              child: _GlowOrb(
                size: 220,
                color: AppColors.primary.withValues(alpha: 0.24),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 100,
              child: _GlowOrb(
                size: 180,
                color: AppColors.info.withValues(alpha: 0.18),
              ),
            ),
            SafeArea(
              child: AnimatedSwitcher(
                duration: AppDurations.page,
                switchInCurve: AppDurations.emphasized,
                switchOutCurve: Curves.easeInOut,
                child: _isCompleted ? _buildCompletedView() : _buildTimerView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView() {
    final hasProgress =
        _remainingSeconds != _selectedDuration * 60 || _isRunning;

    return Column(
      key: const ValueKey('timer_view'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  if (await _handleExitRequest() && mounted) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  S.of(context).t('focus_title'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: _resetTimer,
                color: Colors.white,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              children: [
                _buildSessionHero(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildTimerDial(),
                const SizedBox(height: AppSpacing.xxxl),
                if (!hasProgress) _buildDurationSection(),
                const SizedBox(height: AppSpacing.xxl),
                _buildSoundSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionHero() {
    return ModernCard(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _sessionLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.bookTitle ?? S.of(context).t('focus_pomodoro_space'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusChip(
                label: '$_selectedDuration ${S.of(context).t("focus_minutes")}',
                color: AppColors.accent,
                icon: Icons.timer_outlined,
              ),
              StatusChip(
                label: _getSounds(context)[_selectedSound]['name'] as String,
                color: AppColors.info,
                icon: _getSounds(context)[_selectedSound]['icon'] as IconData,
              ),
              if (widget.bookTitle != null && widget.bookTitle!.isNotEmpty)
                StatusChip(
                  label: S.of(context).t('takeaway_current_book'),
                  color: AppColors.secondary,
                  icon: Icons.menu_book_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDial() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _progress.clamp(0, 1)),
      duration: AppDurations.standard,
      curve: AppDurations.emphasized,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 292,
              height: 292,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
            ),
            SizedBox(
              width: 260,
              height: 260,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.11),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _sessionLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${(_progress * 100).round()}% ${S.of(context).t("focus_complete_pct")}',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationSection() {
    return ModernCard(
      gradient: AppGradients.softGlassOverlay,
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('focus_duration_section'),
            subtitle: S.of(context).t('focus_duration_desc'),
            titleStyle: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
            subtitleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _durations.map(_buildDurationChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSection() {
    return ModernCard(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('focus_sound_section'),
            subtitle: S.of(context).t('focus_sound_desc'),
            titleStyle: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
            subtitleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _getSounds(context).asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: entry.key == _getSounds(context).length - 1 ? 0 : AppSpacing.md,
                  ),
                  child: _buildSoundChip(entry.key, entry.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final canResume = _remainingSeconds != _selectedDuration * 60;

    return Column(
      children: [
        Row(
          children: [
            if (canResume || _isRunning)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetTimer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(S.of(context).t('focus_reset')),
                ),
              ),
            if (canResume || _isRunning) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: _isRunning
                    ? S.of(context).t('focus_pause')
                    : (canResume ? S.of(context).t('focus_resume') : S.of(context).t('focus_start')),
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: _isRunning
                    ? _pauseTimer
                    : (canResume ? _resumeTimer : _startTimer),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AnimatedButton(
          onPressed: () {
            if (_isRunning) {
              _showExitDialog();
            } else {
              context.pop();
            }
          },
          child: Text(
            _isRunning ? S.of(context).t('focus_stop_exit') : S.of(context).t('fc_session_back_btn'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(int duration) {
    final isSelected = _selectedDuration == duration;

    return AnimatedScale(
      scale: isSelected ? 1 : 0.98,
      duration: AppDurations.micro,
      curve: AppDurations.emphasized,
      child: ChoiceChip(
        label: Text('$duration phut'),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedDuration = duration;
            _remainingSeconds = duration * 60;
            _isCompleted = false;
          });
        },
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: isSelected
              ? const BorderSide(color: AppColors.primary)
              : BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildSoundChip(int index, Map<String, dynamic> sound) {
    final isSelected = _selectedSound == index;

    return ModernCard(
      onTap: () => setState(() => _selectedSound = index),
      gradient: LinearGradient(
        colors: isSelected
            ? [
                AppColors.primary.withValues(alpha: 0.26),
                AppColors.primary.withValues(alpha: 0.16),
              ]
            : [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
      ),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sound['icon'] as IconData, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            sound['name'] as String,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      key: const ValueKey('completed_view'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ModernCard(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                S.of(context).t('focus_complete_title'),
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${S.of(context).t("focus_complete_desc")}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusChip(
                    label: '$_selectedDuration phut',
                    color: AppColors.success,
                    icon: Icons.timer_rounded,
                  ),
                  StatusChip(
                    label: _getSounds(context)[_selectedSound]['name'] as String,
                    color: AppColors.info,
                    icon: _getSounds(context)[_selectedSound]['icon'] as IconData,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              PrimaryButton(
                label: S.of(context).t('focus_new_session'),
                icon: const Icon(
                  Icons.replay_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: _resetTimer,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(S.of(context).t('focus_stop')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).t('focus_exit_title')),
        content: Text(
          S.of(context).t('focus_exit_msg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(S.of(context).t('takeaway_cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: Text(S.of(context).t('focus_exit_btn')),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 24),
          ],
        ),
      ),
    );
  }
}
