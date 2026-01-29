/// FriendProfileScreen - Profile bạn bè with API Integration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/friend_service.dart';
import '../../services/user_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;

  const FriendProfileScreen({super.key, required this.friendId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final FriendService _friendService = FriendService();
  final UserService _userService = UserService();

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
        _userService.getUserProfile(widget.friendId),
        _userService.getUserStats(widget.friendId),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final stats = results[1] as Map<String, dynamic>;

      setState(() {
        _friend = {
          ...profile,
          'booksRead': stats['totalBooksRead'] ?? 0,
          'flashcards': stats['totalFlashcards'] ?? 0,
          'streak': stats['currentStreak'] ?? 0,
        };
        _recentBooks = (stats['recentBooks'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _isFollowing = profile['isFollowing'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_isFollowing) {
        await _friendService.unfollowUser(widget.friendId);
      } else {
        await _friendService.sendFriendRequest(widget.friendId);
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryStart),
              SizedBox(height: 16),
              Text('Đang tải...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _friend == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error ?? 'Không tìm thấy người dùng'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFriendProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final friend = _friend!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadFriendProfile,
        color: AppColors.primaryStart,
        child: CustomScrollView(
          slivers: [
            // Header with avatar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight, 
                    size: 18),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, 
                    color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                    size: 20),
                  onPressed: () {
                    // TODO: More options
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.primaryStart.withValues(alpha: 0.1),
                          backgroundImage: friend['avatarUrl'] != null
                              ? NetworkImage(friend['avatarUrl'])
                              : null,
                          child: friend['avatarUrl'] == null
                              ? Text(
                                  (friend['displayName'] ?? friend['name'] ?? '?')
                                      .toString()
                                      .isNotEmpty
                                      ? (friend['displayName'] ??
                                              friend['name'] ??
                                              '?')[0]
                                          .toUpperCase()
                                      : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryStart,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          friend['displayName'] ?? friend['name'] ?? 'Người dùng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio
                    if (friend['bio'] != null && friend['bio'].toString().isNotEmpty)
                      Text(
                        friend['bio'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 16),

                    // Stats
                    _buildStats(friend, isDark),

                    const SizedBox(height: 16),

                    // Action buttons
                    _buildActionButtons(context),

                    const SizedBox(height: 24),

                    // Recent books
                    if (_recentBooks.isNotEmpty) ...[
                      Text(
                        'Sách đã đọc gần đây',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._recentBooks.map((book) => _buildBookItem(book, isDark)),
                    ],

                    const SizedBox(height: 24),

                    // Joined date
                    if (friend['joinedDate'] != null)
                      Center(
                        child: Text(
                          'Tham gia: ${friend['joinedDate']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> friend, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: '${friend['booksRead'] ?? 0}',
            label: 'Sách đã đọc',
            icon: Icons.menu_book,
            color: AppColors.primaryStart,
            isDark: isDark,
          ),
          _buildStatItem(
            value: '${friend['flashcards'] ?? 0}',
            label: 'Flashcard',
            icon: Icons.style,
            color: AppColors.success,
            isDark: isDark,
          ),
          _buildStatItem(
            value: '${friend['streak'] ?? 0}',
            label: 'Ngày streak',
            icon: Icons.local_fire_department,
            color: AppColors.warning,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(
              _isFollowing ? Icons.person_remove : Icons.person_add,
              color: _isFollowing ? AppColors.primaryStart : Colors.white,
            ),
            label: Text(
              _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: _isFollowing ? AppColors.primaryStart : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isFollowing ? Colors.white : AppColors.primaryStart,
              side: _isFollowing
                  ? const BorderSide(color: AppColors.primaryStart)
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Send message
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              'Nhắn tin',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookItem(Map<String, dynamic> book, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              image: book['coverUrl'] != null
                  ? DecorationImage(
                      image: NetworkImage(book['coverUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: book['coverUrl'] == null
                ? const Icon(Icons.menu_book, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Không có tiêu đề',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book['author'] ?? 'Không rõ tác giả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}
