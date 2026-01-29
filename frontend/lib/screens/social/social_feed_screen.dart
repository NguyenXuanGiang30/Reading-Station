/// SocialFeedScreen - Hoạt động bạn bè with API Integration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/activity_service.dart';
import '../../services/friend_service.dart';

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
    });

    try {
      // Load friends and activities in parallel
      final results = await Future.wait([
        _friendService.getFriends(),
        _activityService.getFeed(page: 0, size: 20),
      ]);

      final friendsData = results[0] as List<dynamic>;
      final feedData = results[1] as Map<String, dynamic>;
      final content = feedData['content'] as List<dynamic>? ?? [];
      final totalPages = feedData['totalPages'] as int? ?? 1;

      setState(() {
        _friends = friendsData.map((e) => e as Map<String, dynamic>).toList();
        _activities = content.map((e) => e as Map<String, dynamic>).toList();
        _hasMore = _currentPage < totalPages - 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore) {
      _loadMoreActivities();
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final feedData = await _activityService.getFeed(page: _currentPage, size: 20);
      final content = feedData['content'] as List<dynamic>? ?? [];
      final totalPages = feedData['totalPages'] as int? ?? 1;

      setState(() {
        _activities.addAll(content.map((e) => e as Map<String, dynamic>));
        _hasMore = _currentPage < totalPages - 1;
        _isLoadingMore = false;
      });
    } catch (e) {
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
      // Update local state
      final index = _activities.indexWhere((a) => a['id'] == activityId);
      if (index != -1) {
        setState(() {
          _activities[index]['liked'] = !isLiked;
          _activities[index]['likesCount'] = 
              ((_activities[index]['likesCount'] as int? ?? 0) + (isLiked ? -1 : 1));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cộng đồng',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/find-friend'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildContent(isDark),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryStart),
            SizedBox(height: 16),
            Text('Đang tải...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error ?? 'Đã xảy ra lỗi'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryStart,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Online friends
          SliverToBoxAdapter(
            child: _buildOnlineFriends(isDark),
          ),

          // Activities header
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Hoạt động gần đây',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
          ),

          // Activities list
          if (_activities.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _activities.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppColors.primaryStart),
                        ),
                      );
                    }
                    return _buildActivityCard(_activities[index], isDark);
                  },
                  childCount: _activities.length + (_isLoadingMore ? 1 : 0),
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có hoạt động nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kết bạn để xem hoạt động của họ!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineFriends(bool isDark) {
    if (_friends.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _friends.length + 1,
        itemBuilder: (context, index) {
          if (index == _friends.length) {
            return _buildFindFriendsButton(isDark);
          }
          return _buildFriendAvatar(_friends[index], isDark);
        },
      ),
    );
  }

  Widget _buildFriendAvatar(Map<String, dynamic> friend, bool isDark) {
    final isOnline = friend['online'] as bool? ?? false;
    final name = friend['displayName'] ?? friend['name'] ?? '?';
    final friendId = friend['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => context.push('/friend/$friendId'),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryStart.withValues(alpha: 0.2),
                  backgroundImage: friend['avatarUrl'] != null
                      ? NetworkImage(friend['avatarUrl'])
                      : null,
                  child: friend['avatarUrl'] == null
                      ? Text(
                          name.toString().isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryStart,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
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
            const SizedBox(height: 4),
            Text(
              name.toString().split(' ').first,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindFriendsButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(Icons.add, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isDark) {
    final userName = activity['userName'] ?? activity['user'] ?? 'Người dùng';
    final action = activity['action'] ?? activity['type'] ?? '';
    final time = activity['createdAt'] ?? activity['time'] ?? '';
    final activityId = activity['id']?.toString() ?? '';
    final isLiked = activity['liked'] as bool? ?? false;
    final likesCount = activity['likesCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: _getActivityColor(action).withValues(alpha: 0.2),
                child: Text(
                  userName.toString().isNotEmpty ? userName.split(' ').last[0] : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: _getActivityColor(action),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        children: [
                          TextSpan(
                            text: userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${_getActionText(action)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildActivityDetails(activity, isDark),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Action icon
              Icon(
                _getActivityIcon(action),
                color: _getActivityColor(action),
                size: 20,
              ),
            ],
          ),

          // Like/Comment row
          if (activityId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _likeActivity(activityId, isLiked),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? AppColors.error : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    // TODO: Show comments
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${activity['commentsCount'] ?? 0}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityDetails(Map<String, dynamic> activity, bool isDark) {
    final type = activity['type'] ?? '';
    final bookTitle = activity['bookTitle'] ?? activity['book'];
    final achievement = activity['achievement'];
    final flashcards = activity['flashcards'];

    if (achievement != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.warning, size: 14),
            const SizedBox(width: 4),
            Text(
              achievement,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'review' && flashcards != null) {
      return Text(
        '$flashcards flashcard',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.info,
        ),
      );
    }

    if (bookTitle != null) {
      return Text(
        '📚 $bookTitle',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryStart,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getActionText(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return 'đã hoàn thành cuốn sách';
      case 'note':
        return 'đã thêm ghi chú mới';
      case 'started':
        return 'đã bắt đầu đọc';
      case 'achievement':
        return 'đạt thành tích';
      case 'review':
        return 'đã ôn tập';
      default:
        return type;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'note':
        return AppColors.info;
      case 'started':
        return AppColors.primaryStart;
      case 'achievement':
        return AppColors.warning;
      case 'review':
        return AppColors.accent;
      default:
        return AppColors.primaryStart;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'note':
        return Icons.note_alt;
      case 'started':
        return Icons.play_arrow;
      case 'achievement':
        return Icons.emoji_events;
      case 'review':
        return Icons.style;
      default:
        return Icons.circle;
    }
  }
}
