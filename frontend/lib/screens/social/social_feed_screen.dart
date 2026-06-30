/// SocialFeedScreen - Hoạt động bạn bè
library;

import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/activity_service.dart';
import '../../services/friend_service.dart';
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

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final ActivityService _activityService = ActivityService();
  final FriendService _friendService = FriendService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 0;
    });

    try {
      final results = await Future.wait([
        _friendService.getFriends(),
        _activityService.getFeed(page: 0, size: 20),
      ]);

      final friendsData = results[0] as List<dynamic>;
      final feedData = results[1] as Map<String, dynamic>;
      final content = feedData['content'] as List<dynamic>? ?? [];
      final totalPages = feedData['totalPages'] as int? ?? 1;

      if (!mounted) return;
      setState(() {
        _friends = friendsData.map((e) => e as Map<String, dynamic>).toList();
        _activities = content.map((e) => e as Map<String, dynamic>).toList();
        _hasMore = _currentPage < totalPages - 1;
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreActivities();
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final feedData = await _activityService.getFeed(
        page: nextPage,
        size: 20,
      );
      final content = feedData['content'] as List<dynamic>? ?? [];
      final totalPages = feedData['totalPages'] as int? ?? 1;

      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        _activities.addAll(content.map((e) => e as Map<String, dynamic>));
        _hasMore = _currentPage < totalPages - 1;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _likeActivity(String activityId, bool isLiked) async {
    try {
      if (isLiked) {
        await _activityService.unlikeActivity(activityId);
      } else {
        await _activityService.likeActivity(activityId);
      }

      final index = _activities.indexWhere((activity) => activity['id'] == activityId);
      if (index != -1) {
        setState(() {
          _activities[index]['liked'] = !isLiked;
          _activities[index]['likesCount'] =
              ((_activities[index]['likesCount'] as int? ?? 0) +
                  (isLiked ? -1 : 1));
        });
      }
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
            message: S.of(context).t('social_loading'),
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
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroSection(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFriendStories(context),
                  const SizedBox(height: AppSpacing.xl),
                  _buildActivitiesSection(context),
                  if (_isLoadingMore) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
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
                      S.of(context).t('social_title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: () => context.push('/find-friend'),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                S.of(context).t('social_desc'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      icon: Icons.people_alt_outlined,
                      value: '${_friends.length}',
                      label: S.of(context).t('social_readers'),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _HeroMetric(
                      icon: Icons.dynamic_feed_outlined,
                      value: '${_activities.length}',
                      label: S.of(context).t('social_activities'),
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              if (_friends.isEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: S.of(context).t('social_find_friends'),
                  expand: false,
                  icon: const Icon(
                    Icons.group_add_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: () => context.push('/find-friend'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendStories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('social_your_circle'),
          subtitle: S.of(context).t('social_circle_desc'),
          trailing: TextButton(
            onPressed: () => context.push('/find-friend'),
            child: Text(S.of(context).t('social_add_friend')),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_friends.isEmpty)
          ModernCard(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_off_outlined,
                    size: 42,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    S.of(context).t('social_no_connection'),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _friends.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == _friends.length) {
                  return _AddFriendCard(
                    onTap: () => context.push('/find-friend'),
                  );
                }
                return _FriendStory(friend: _friends[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    if (_activities.isEmpty) {
      return EmptyStateWidget(
        title: S.of(context).t('social_empty_feed'),
        message: S.of(context).t('social_empty_feed_msg'),
        icon: Icons.dynamic_feed_outlined,
        actionLabel: S.of(context).t('social_connect_now'),
        onAction: () => context.push('/find-friend'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('social_recent_activity'),
          subtitle: S.of(context).t('social_recent_desc'),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._activities.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _activities.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _ActivityCard(
              activity: entry.value,
              onLike: _likeActivity,
              onComment: (activityId) => _showComments(activityId),
            ),
          );
        }),
      ],
    );
  }

  void _showComments(String activityId) {
    final commentController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (modalContext) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: S.of(context).t('social_comments'),
                    subtitle: S.of(context).t('social_comments_desc'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _activityService.getComments(activityId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return LoadingWidget(
                            fullScreen: true,
                            message: S.of(context).t('social_loading_comments'),
                          );
                        }

                        if (snapshot.hasError) {
                          return ErrorStateWidget(
                            message: '${snapshot.error}',
                            onRetry: () {
                              Navigator.pop(modalContext);
                              _showComments(activityId);
                            },
                          );
                        }

                        final comments = snapshot.data ?? [];
                        if (comments.isEmpty) {
                          return EmptyStateWidget(
                            title: S.of(context).t('social_no_comments'),
                            message: S.of(context).t('social_no_comments_msg'),
                            icon: Icons.chat_bubble_outline_rounded,
                          );
                        }

                        return ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final comment =
                                comments[index] as Map<String, dynamic>;
                            final userName =
                                '${comment['userName'] ?? comment['fullName'] ?? S.of(context).t('social_user')}';

                            return ModernCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primarySoft,
                                    child: Text(
                                      userName.substring(0, 1).toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${comment['content'] ?? ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: S.of(context).t('social_write_comment'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: () async {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;

                          try {
                            await _activityService.addComment(activityId, text);
                            commentController.clear();

                            final index = _activities.indexWhere(
                              (activity) => '${activity['id']}' == activityId,
                            );
                            if (index != -1) {
                              setState(() {
                                final key =
                                    _activities[index].containsKey('commentsCount')
                                        ? 'commentsCount'
                                        : 'commentCount';
                                _activities[index][key] =
                                    ((_activities[index][key] as int? ?? 0) + 1);
                              });
                            }

                            if (!mounted || !modalContext.mounted) return;
                            Navigator.pop(modalContext);
                            _showComments(activityId);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Loi: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroMetric({
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

class _FriendStory extends StatelessWidget {
  final Map<String, dynamic> friend;

  const _FriendStory({required this.friend});

  @override
  Widget build(BuildContext context) {
    final name =
        '${friend['fullName'] ?? friend['displayName'] ?? friend['name'] ?? '?'}';
    final avatarUrl = friend['avatarUrl'] as String?;
    final friendId = friend['id']?.toString() ?? '';
    final isOnline = friend['online'] as bool? ?? false;

    return InkWell(
      onTap: () => context.push('/friend/$friendId'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        isOnline
                            ? AppColors.primaryGradient
                            : const LinearGradient(
                              colors: [AppColors.border, AppColors.border],
                            ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surface,
                    backgroundImage:
                        avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                    child:
                        avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                              name.substring(0, 1).toUpperCase(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppColors.primary),
                            )
                            : null,
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name.split(' ').first,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFriendCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFriendCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
               S.of(context).t('social_add_new'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Future<void> Function(String activityId, bool isLiked) onLike;
  final ValueChanged<String> onComment;

  const _ActivityCard({
    required this.activity,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final userName =
        '${activity['userName'] ?? activity['user'] ?? S.of(context).t('social_user')}';
    final action =
        '${activity['action'] ?? activity['activityType'] ?? activity['type'] ?? ''}';
    final time = '${activity['createdAt'] ?? activity['time'] ?? ''}';
    final activityId = activity['id']?.toString() ?? '';
    final isLiked = activity['liked'] as bool? ?? false;
    final likesCount =
        activity['likesCount'] as int? ?? activity['likeCount'] as int? ?? 0;
    final commentsCount =
        activity['commentsCount'] as int? ?? activity['commentCount'] as int? ?? 0;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _getActivityColor(action).withValues(alpha: 0.14),
                child: Text(
                  userName.isNotEmpty ? userName.split(' ').last.substring(0, 1) : '?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getActivityColor(action),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: userName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextSpan(text: ' ${_getActionText(action, context)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActivityDetailChip(activity: activity, type: action),
                    const SizedBox(height: AppSpacing.sm),
                    Text(time, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                _getActivityIcon(action),
                size: 20,
                color: _getActivityColor(action),
              ),
            ],
          ),
          if (activityId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _ActivityActionButton(
                  icon:
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '$likesCount',
                  color: isLiked ? AppColors.error : AppColors.textSecondary,
                  onTap: () => onLike(activityId, isLiked),
                ),
                const SizedBox(width: AppSpacing.md),
                _ActivityActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '$commentsCount',
                  color: AppColors.textSecondary,
                  onTap: () => onComment(activityId),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActivityActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityDetailChip extends StatelessWidget {
  final Map<String, dynamic> activity;
  final String type;

  const _ActivityDetailChip({required this.activity, required this.type});

  @override
  Widget build(BuildContext context) {
    final achievement = activity['achievement'];
    final bookTitle = activity['bookTitle'] ?? activity['book'];
    final flashcards = activity['flashcards'];

    if (achievement != null) {
      return _InfoChip(
        icon: Icons.workspace_premium_rounded,
        label: '$achievement',
        color: AppColors.warning,
      );
    }

    if ((type.toUpperCase() == 'REVIEW_POSTED' || type.toUpperCase() == 'REVIEW') &&
        flashcards != null) {
      return _InfoChip(
        icon: Icons.style_rounded,
        label: '$flashcards flashcard',
        color: AppColors.info,
      );
    }

    if (bookTitle != null) {
      return _InfoChip(
        icon: Icons.menu_book_rounded,
        label: '$bookTitle',
        color: AppColors.primary,
      );
    }

    return const SizedBox.shrink();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _getActionText(String type, BuildContext context) {
  switch (type.toUpperCase()) {
    case 'BOOK_COMPLETED':
    case 'COMPLETED':
      return S.of(context).t('social_completed_book');
    case 'NOTE_CREATED':
    case 'NOTE':
      return S.of(context).t('social_default_activity');
    case 'BOOK_ADDED':
    case 'STARTED':
      return S.of(context).t('social_default_activity');
    case 'BOOK_STATUS_CHANGED':
      return S.of(context).t('social_updated_status');
    case 'REVIEW_POSTED':
    case 'REVIEW':
      return S.of(context).t('social_reviewed_fc');
    case 'PROGRESS_UPDATED':
      return S.of(context).t('social_updated_progress');
    default:
      return type;
  }
}

Color _getActivityColor(String type) {
  switch (type.toUpperCase()) {
    case 'BOOK_COMPLETED':
    case 'COMPLETED':
      return AppColors.success;
    case 'NOTE_CREATED':
    case 'NOTE':
      return AppColors.info;
    case 'BOOK_ADDED':
    case 'STARTED':
      return AppColors.primary;
    case 'BOOK_STATUS_CHANGED':
    case 'PROGRESS_UPDATED':
      return AppColors.warning;
    case 'REVIEW_POSTED':
    case 'REVIEW':
      return AppColors.secondary;
    default:
      return AppColors.primary;
  }
}

IconData _getActivityIcon(String type) {
  switch (type.toUpperCase()) {
    case 'BOOK_COMPLETED':
    case 'COMPLETED':
      return Icons.check_circle_rounded;
    case 'NOTE_CREATED':
    case 'NOTE':
      return Icons.note_alt_outlined;
    case 'BOOK_ADDED':
    case 'STARTED':
      return Icons.play_arrow_rounded;
    case 'BOOK_STATUS_CHANGED':
      return Icons.bookmark_added_rounded;
    case 'REVIEW_POSTED':
    case 'REVIEW':
      return Icons.style_rounded;
    case 'PROGRESS_UPDATED':
      return Icons.auto_graph_rounded;
    default:
      return Icons.circle_rounded;
  }
}
