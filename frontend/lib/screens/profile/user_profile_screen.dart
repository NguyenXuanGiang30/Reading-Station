/// UserProfileScreen - Trang cá nhân & thống kê with API Integration
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/user_service.dart';
import '../../services/friend_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _userService = UserService();
  final FriendService _friendService = FriendService();
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _userService.getReadingStats(),
        _userService.getAchievements(),
        _friendService.getFriends(),
      ]);
      
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _achievements = (results[1] as List).map((e) => e as Map<String, dynamic>).toList();
          _friends = (results[2] as List).map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primaryStart,
        child: CustomScrollView(
          slivers: [
            // Profile header
            SliverToBoxAdapter(
              child: _buildProfileHeader(context, isDark),
            ),
            
            // Stats cards
            SliverToBoxAdapter(
              child: _buildStatsSection(isDark),
            ),
            
            // Reading DNA
            SliverToBoxAdapter(
              child: _buildReadingDNASection(isDark),
            ),
            
            // Achievements
            SliverToBoxAdapter(
              child: _buildAchievementsSection(isDark),
            ),
            
            // Friends
            SliverToBoxAdapter(
              child: _buildFriendsSection(context, isDark),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    'Hồ sơ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, 
                      color: isDark ? Colors.white70 : AppColors.textSecondaryLight),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Avatar
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                
                return Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryStart.withValues(alpha: 0.3), 
                          width: 2,
                        ),
                        color: AppColors.primaryStart.withValues(alpha: 0.1),
                      ),
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user!.avatarUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryStart,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Người dùng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.bio ?? 'Độc giả yêu sách',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Stats row - flat style
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        _buildProfileStat('${_stats['totalBooksRead'] ?? 0}', 'Sách đọc', isDark),
                        _buildVerticalDivider(isDark),
                        _buildProfileStat('${_stats['totalNotes'] ?? 0}', 'Ghi chú', isDark),
                        _buildVerticalDivider(isDark),
                        _buildProfileStat('${_stats['totalFlashcards'] ?? 0}', 'Flashcard', isDark),
                        _buildVerticalDivider(isDark),
                        _buildProfileStat('${_friends.length}', 'Bạn bè', isDark),
                      ],
                    ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      height: 32,
      width: 1,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.local_fire_department,
              value: '${_stats['currentStreak'] ?? 0}',
              label: 'Ngày streak',
              color: Colors.orange,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timer,
              value: '${_stats['totalReadingHours'] ?? 0}h',
              label: 'Thời gian đọc',
              color: AppColors.info,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
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
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingDNASection(bool isDark) {
    // Use API data or fallback to empty
    final categories = (_stats['readingDNA'] as List<dynamic>?)?.map((e) {
      final item = e as Map<String, dynamic>;
      return {
        'name': item['genre'] ?? 'Khác',
        'percent': (item['percentage'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList() ?? [];

    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading DNA 📊',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 48,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có dữ liệu đọc sách',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading DNA 📊',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ...categories.map((cat) => _buildDNABar(
              cat['name'] as String,
              cat['percent'] as double,
              cat['color'] as Color,
              isDark,
            )),
          ],
        ),
      ),
    );
  }
  
  Color _getColorForIndex(int index) {
    const colors = [
      AppColors.primaryStart,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }

  Widget _buildDNABar(String name, double percent, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(bool isDark) {
    // Use API data or fallback
    final achievementsList = _achievements;

    if (achievementsList.isEmpty) {
      return const SizedBox.shrink(); // Hide achievements section if empty
    }
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thành tựu 🏆',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievementsList.length,
            itemBuilder: (context, index) {
              final achievement = achievementsList[index];
              final unlocked = achievement['unlocked'] as bool? ?? false;
              final iconData = achievement['icon'] is IconData 
                  ? achievement['icon'] as IconData 
                  : Icons.emoji_events;
              
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: unlocked 
                      ? Border.all(color: AppColors.warning, width: 2)
                      : null,
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: unlocked ? 1 : 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconData,
                        size: 32,
                        color: unlocked ? AppColors.warning : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (achievement['name'] ?? '') as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsSection(BuildContext context, bool isDark) {
    final friendsList = _friends; // Use loaded friends
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vòng tròn tin cậy 🤝',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/social'),
                child: Text(
                  'Xem tất cả',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.primaryStart,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (friendsList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 40,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có ai trong vòng tròn',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/social'),
                      child: Text(
                        'Thêm bạn ngay',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryStart,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: friendsList.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  final booksCount = friend['booksRead'] as int? ?? 0;
                  
                  return GestureDetector(
                    onTap: () => context.push('/social/profile/${friend['id']}'),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryStart,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryStart.withValues(alpha: 0.1),
                            backgroundImage: friend['avatarUrl'] != null
                                ? NetworkImage(friend['avatarUrl'] as String)
                                : null,
                            child: friend['avatarUrl'] == null
                                ? Text(
                                    (friend['displayName'] ?? friend['name'] ?? '?')[0].toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryStart,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            friend['displayName'] ?? friend['name'] ?? 'Bạn bè',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
