/// FriendProfileScreen - Profile ban doc
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/friend_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final FriendService _friendService = FriendService();

  Map<String, dynamic>? _friend;
  List<Map<String, dynamic>> _recentBooks = [];
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadFriendProfile();
  }

  Future<void> _loadFriendProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _friendService.getFriendProfile(widget.friendId),
        _friendService.getFriendBooks(widget.friendId),
      ]);

      final profile = results[0] as Map<String, dynamic>? ?? {};
      final friendBooks = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _friend = {
          ...profile,
          'booksRead': friendBooks.length,
          'flashcards': 0,
          'streak': 0,
        };
        _recentBooks = friendBooks;
        _isFollowing = profile['friendshipId'] != null;
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

  Future<void> _toggleFollow() async {
    try {
      final friendshipId = _friend?['friendshipId']?.toString() ?? widget.friendId;
      if (_isFollowing) {
        await _friendService.unfollowUser(friendshipId);
      } else {
        await _friendService.sendFriendRequest(widget.friendId);
      }

      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: LoadingWidget(
            fullScreen: true,
            message: S.of(context).t('friend_loading'),
          ),
        ),
      );
    }

    if (_error != null || _friend == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: S.of(context).t('friend_profile'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SafeArea(
          child: ErrorStateWidget(
            message: _error ?? S.of(context).t('friend_not_found'),
            onRetry: _loadFriendProfile,
          ),
        ),
      );
    }

    final friend = _friend!;
    final name = '${friend['fullName'] ?? friend['name'] ?? S.of(context).t("find_friend_user")}';
    final avatarUrl = friend['avatarUrl'] as String?;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFriendProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
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
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _showMoreOptions,
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withValues(alpha: 0.88),
                              backgroundImage:
                                  avatarUrl != null && avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                              child:
                                  avatarUrl == null || avatarUrl.isEmpty
                                      ? Text(
                                        name.substring(0, 1).toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(color: AppColors.primary),
                                      )
                                      : null,
                            ),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: Theme.of(context).textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    (friend['bio']?.toString().trim().isNotEmpty ?? false)
                                        ? '${friend['bio']}'
                                        : S.of(context).t('friend_default_bio'),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ModernCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: _FriendMetric(
                                  value: '${friend['booksRead'] ?? 0}',
                                  label: S.of(context).t('friend_books_read'),
                                  icon: Icons.menu_book_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              Expanded(
                                child: _FriendMetric(
                                  value: '${friend['flashcards'] ?? 0}',
                                  label: S.of(context).t('search_flashcards'),
                                  icon: Icons.style_rounded,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Expanded(
                                child: _FriendMetric(
                                  value: '${friend['streak'] ?? 0}',
                                  label: S.of(context).t('friend_days_streak'),
                                  icon: Icons.local_fire_department_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isFollowing ? S.of(context).t('friend_following') : S.of(context).t('friend_follow'),
                          icon: Icon(
                            _isFollowing
                                ? Icons.person_remove_alt_1_rounded
                                : Icons.person_add_alt_1_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFollow,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(S.of(context).t('friend_message_soon')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: Text(S.of(context).t('friend_message')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_recentBooks.isNotEmpty) ...[
                    SectionHeader(
                      title: S.of(context).t('friend_recent_books'),
                      subtitle: '${_recentBooks.length} ${S.of(context).t("friend_shared_desc")}',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ..._recentBooks.asMap().entries.map((entry) {
                      final book = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == _recentBooks.length - 1
                              ? 0
                              : AppSpacing.md,
                        ),
                        child: _FriendBookCard(book: book),
                      );
                    }),
                  ] else
                    ModernCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 42,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            S.of(context).t('friend_no_books'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  if (friend['createdAt'] != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Text(
                        '${S.of(context).t("friend_joined")} ${friend['createdAt']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (bottomSheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileActionTile(
                  icon: Icons.person_remove_alt_1_rounded,
                  title: S.of(context).t('friend_unfriend'),
                  color: AppColors.textPrimary,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      final friendshipId =
                          _friend?['friendshipId']?.toString() ?? widget.friendId;
                      await _friendService.removeFriend(friendshipId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).t('friend_unfriended'))),
                      );
                      context.pop();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Loi: $e')),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionTile(
                  icon: Icons.block_rounded,
                  title: S.of(context).t('friend_block'),
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.of(context).t('friend_block_soon')),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionTile(
                  icon: Icons.flag_rounded,
                  title: S.of(context).t('friend_report'),
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.of(context).t('friend_report_soon')),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _FriendMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FriendMetric({
    required this.value,
    required this.label,
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

class _FriendBookCard extends StatelessWidget {
  final Map<String, dynamic> book;

  const _FriendBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final nestedBook = Map<String, dynamic>.from(
      (book['book'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final coverUrl =
        (nestedBook['coverUrl'] ?? nestedBook['coverImageUrl'] ?? book['coverUrl'])
            as String?;
    final title = nestedBook['title'] ?? book['title'] ?? S.of(context).t('friend_no_title');
    final author =
        nestedBook['author'] ?? book['author'] ?? S.of(context).t('friend_no_author');

    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 50,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              image:
                  coverUrl != null && coverUrl.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                coverUrl == null || coverUrl.isEmpty
                    ? const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                    )
                    : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$author',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
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
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    );
  }
}
