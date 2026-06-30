/// UserProfileScreen - Trang cá nhân và thống kê
library;

import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/friend_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/profile/profile_menu_tile.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final FriendService _friendService = FriendService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _userService.getReadingStats(),
        _userService.getAchievements(),
        _friendService.getFriends(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _achievements =
            (results[1] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
        _friends =
            (results[2] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stats.isEmpty && _friends.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: LoadingWidget(
            fullScreen: true,
            message: S.of(context).t('profile_loading'),
          ),
        ),
      );
    }

    if (_errorMessage != null && _stats.isEmpty && _friends.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorStateWidget(
            message: _errorMessage!,
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
            SliverToBoxAdapter(child: _buildHeroHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatHighlights(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildReadingDnaSection(context),
                  if (_achievements.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildAchievementsSection(context),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _buildFriendsSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(context),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

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
                          S.of(context).t('profile_title'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.9),
                            backgroundImage:
                                user?.avatarUrl != null
                                    ? NetworkImage(user!.avatarUrl!)
                                    : null,
                            child:
                                user?.avatarUrl == null
                                    ? Text(
                                      (user?.fullName.isNotEmpty ?? false)
                                          ? user!.fullName.substring(0, 1)
                                          : 'U',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(color: AppColors.primary),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? S.of(context).t('profile_user'),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              user?.bio?.trim().isNotEmpty == true
                                  ? user!.bio!
                                  : S.of(context).t('profile_bio_default'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      onPressed:
                                          () => context.push('/profile/edit'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        S.of(context).t('profile_edit'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: OutlinedButton(
                                      onPressed: () => context.push('/social'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        S.of(context).t('profile_readers'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            label: S.of(context).t('profile_books'),
                            value: '${_stats['totalBooksRead'] ?? 0}',
                            icon: Icons.menu_book_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: _ProfileStat(
                            label: S.of(context).t('profile_notes'),
                            value: '${_stats['totalNotes'] ?? 0}',
                            icon: Icons.sticky_note_2_outlined,
                            color: AppColors.secondary,
                          ),
                        ),
                        Expanded(
                          child: _ProfileStat(
                            label: S.of(context).t('profile_friends'),
                            value: '${_friends.length}',
                            icon: Icons.people_alt_outlined,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatHighlights(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ModernCard(
            child: _HighlightMetric(
              title: S.of(context).t('profile_streak_title'),
              value: '${_stats['currentStreak'] ?? 0}',
              subtitle: S.of(context).t('profile_streak_days'),
              icon: Icons.local_fire_department_rounded,
              color: AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ModernCard(
            child: _HighlightMetric(
              title: S.of(context).t('profile_reading_time'),
              value: '${_stats['totalReadingHours'] ?? 0}h',
              subtitle: S.of(context).t('profile_total_hours'),
              icon: Icons.schedule_rounded,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingDnaSection(BuildContext context) {
    final dna = ((_stats['readingDNA'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('profile_reading_dna'),
            subtitle: S.of(context).t('profile_dna_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (dna.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    S.of(context).t('profile_dna_empty'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...dna.asMap().entries.map((entry) {
              final item = entry.value;
              final percent = _normalizePercent(item['percentage']);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == dna.length - 1 ? 0 : AppSpacing.lg,
                ),
                child: _DnaProgressRow(
                  label: '${item['genre'] ?? S.of(context).t('note_type_other')}',
                  percent: percent,
                  color: _paletteByIndex(entry.key),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('profile_achievements'),
          subtitle: S.of(context).t('profile_achievements_desc'),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _achievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            final unlocked = achievement['unlocked'] as bool? ?? false;
            return ModernCard(
              child: Opacity(
                opacity: unlocked ? 1 : 0.45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color:
                            (unlocked ? AppColors.warning : AppColors.surfaceMuted)
                                .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        unlocked
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline_rounded,
                        color: unlocked ? AppColors.warning : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${achievement['name'] ?? 'Thanh tuu'}',
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFriendsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('profile_circle'),
          subtitle: S.of(context).t('profile_circle_desc'),
          trailing: TextButton(
            onPressed: () => context.push('/social'),
            child: Text(S.of(context).t('profile_view_all')),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_friends.isEmpty)
          ModernCard(
            child: Column(
              children: [
                const Icon(
                  Icons.group_off_outlined,
                  size: 42,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  S.of(context).t('profile_circle_empty'),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: S.of(context).t('profile_find_friends'),
                  expand: false,
                  onPressed: () => context.push('/find-friend'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _friends.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return _FriendCard(friend: friend);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          ProfileMenuTile(
            icon: Icons.edit_note_rounded,
            title: S.of(context).t('profile_edit_profile'),
            subtitle: S.of(context).t('profile_edit_subtitle'),
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(height: 1, indent: 68),
          ProfileMenuTile(
            icon: Icons.notifications_none_rounded,
            title: S.of(context).t('profile_notifications'),
            subtitle: S.of(context).t('profile_notifications_subtitle'),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 1, indent: 68),
          ProfileMenuTile(
            icon: Icons.settings_suggest_outlined,
            title: S.of(context).t('profile_settings'),
            subtitle: S.of(context).t('profile_settings_subtitle'),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  double _normalizePercent(dynamic raw) {
    final value = (raw as num?)?.toDouble() ?? 0;
    if (value > 1) return (value / 100).clamp(0, 1);
    return value.clamp(0, 1);
  }

  Color _paletteByIndex(int index) {
    const palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.info,
      AppColors.success,
    ];
    return palette[index % palette.length];
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
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
            color: color.withValues(alpha: 0.14),
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

class _HighlightMetric extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HighlightMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _DnaProgressRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _DnaProgressRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent),
      duration: AppDurations.page,
      curve: AppDurations.emphasized,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    final name = '${friend['fullName'] ?? friend['name'] ?? S.of(context).t('profile_reader')}';
    final avatarUrl = friend['avatarUrl'] as String?;

    return SizedBox(
      width: 96,
      child: ModernCard(
        onTap: () => context.push('/friend/${friend['id']}'),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySoft,
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child:
                  avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
