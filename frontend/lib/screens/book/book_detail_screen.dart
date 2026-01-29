/// BookDetailScreen - Chi tiết sách
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../models/book.dart';
import '../../services/user_book_service.dart';
import '../../services/reading_progress_service.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final UserBookService _userBookService = UserBookService();
  final ReadingProgressService _progressService = ReadingProgressService();
  
  Map<String, dynamic>? _book;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadBook();
  }
  
  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final book = await _userBookService.getUserBookById(widget.bookId);
      if (book != null) {
        // Parse status from API
        final statusStr = book['status'] as String? ?? 'WANT_TO_READ';
        ReadingStatus status;
        switch (statusStr.toUpperCase()) {
          case 'READING':
            status = ReadingStatus.reading;
            break;
          case 'READ':
          case 'COMPLETED':
            status = ReadingStatus.read;
            break;
          default:
            status = ReadingStatus.wantToRead;
        }
        
        final currentPage = book['currentPage'] as int? ?? 0;
        final totalPages = book['totalPages'] as int? ?? 1;
        final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
        
        setState(() {
          _book = {
            ...book,
            'status': status,
            'progress': progress,
            'startDate': book['startDate'] ?? 'N/A',
            'lastReadDate': book['lastReadDate'] ?? 'N/A',
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không tìm thấy sách';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
    
    if (_error != null || _book == null) {
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
              Text(_error ?? 'Không tìm thấy sách'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBook,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBook,
        color: AppColors.primaryStart,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, isDark),
            SliverToBoxAdapter(
              child: _buildContent(context, isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, isDark),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    final book = _book!;
    final progress = book['progress'] as double? ?? 0.0;
    
    return SliverAppBar(
      expandedHeight: 280,
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
          icon: Icon(Icons.edit, 
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            size: 20),
          onPressed: () => context.push('/book/${widget.bookId}/edit'),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, 
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            size: 20),
          onPressed: () => _showMoreOptions(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Book cover
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.primaryStart.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      size: 60,
                      color: AppColors.primaryStart,
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Book info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _book!['title'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _book!['author'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress
                        Text(
                          '${(_book!['currentPage'])}/${_book!['totalPages']} trang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.primaryStart.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryStart),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}% hoàn thành',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryStart,
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
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge and rating
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_book!['status']).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (_book!['status'] as ReadingStatus).label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_book!['status']),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${_book!['rating']}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action cards
          _buildQuickActions(context, isDark),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Mô tả',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _book!['description'],
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Book info
          _buildInfoSection(isDark),
          
          const SizedBox(height: 24),
          
          // Friends who read this book
          _buildFriendsWhoRead(context, isDark),
          
          const SizedBox(height: 24),
          
          // Reading stats
          _buildReadingStats(isDark),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.note_alt_outlined,
            label: 'Ghi chú',
            value: '${_book!['notesCount']}',
            color: AppColors.info,
            isDark: isDark,
            onTap: () => context.push('/book/${widget.bookId}/notes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.style_outlined,
            label: 'Flashcard',
            value: '${_book!['flashcardsCount']}',
            color: AppColors.success,
            isDark: isDark,
            onTap: () => context.push('/flashcard/session?bookId=${widget.bookId}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.location_on_outlined,
            label: 'Vị trí',
            value: _book!['location'],
            color: AppColors.warning,
            isDark: isDark,
            onTap: () => _showLocationInfo(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark) {
    final infoItems = [
      {'icon': Icons.category, 'label': 'Thể loại', 'value': _book!['category']},
      {'icon': Icons.business, 'label': 'NXB', 'value': _book!['publisher']},
      {'icon': Icons.calendar_today, 'label': 'Năm', 'value': '${_book!['publishedYear']}'},
      {'icon': Icons.qr_code, 'label': 'ISBN', 'value': _book!['isbn']},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin sách',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          ...infoItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 12),
                Text(
                  '${item['label']}:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['value'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReadingStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê đọc',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.play_arrow,
                  label: 'Bắt đầu',
                  value: _book!['startDate'],
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.update,
                  label: 'Đọc gần nhất',
                  value: _book!['lastReadDate'],
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryStart),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFriendsWhoRead(BuildContext context, bool isDark) {
    // Mock data - will be replaced with API data
    final friends = [
      {'id': '1', 'name': 'Minh Anh', 'avatar': null, 'rating': 5},
      {'id': '2', 'name': 'Hà My', 'avatar': null, 'rating': 4},
      {'id': '3', 'name': 'Tuấn', 'avatar': null, 'rating': 5},
      {'id': '4', 'name': 'Linh', 'avatar': null, 'rating': 4},
    ];
    
    if (friends.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                size: 20,
                color: AppColors.primaryStart,
              ),
              const SizedBox(width: 8),
              Text(
                '${friends.length} bạn bè đã đọc sách này',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Avatar grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: friends.map((friend) {
              return GestureDetector(
                onTap: () => context.push('/friend/${friend['id']}'),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (friend['name'] as String).substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: AppColors.warning),
                        Text(
                          '${friend['rating']}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // View all button
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Show all friends who read this book
              },
              child: Text(
                'Xem tất cả đánh giá',
                style: GoogleFonts.inter(
                  color: AppColors.primaryStart,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateProgress(context),
                icon: const Icon(Icons.update),
                label: const Text('Cập nhật'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primaryStart),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/note/create?bookId=${widget.bookId}'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Ghi chú',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.reading:
        return AppColors.reading;
      case ReadingStatus.read:
        return AppColors.completed;
      case ReadingStatus.wantToRead:
        return AppColors.wantToRead;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ sách'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Thêm vào danh sách'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Xóa sách', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLocationInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vị trí: ${_book!['location']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateProgress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpdateProgressSheet(
        currentPage: _book!['currentPage'],
        totalPages: _book!['totalPages'],
        onUpdate: (newPage) {
          setState(() {
            _book!['currentPage'] = newPage;
            _book!['progress'] = newPage / _book!['totalPages'];
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sách'),
        content: const Text('Bạn có chắc muốn xóa sách này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressSheet extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onUpdate;
  
  const _UpdateProgressSheet({
    required this.currentPage,
    required this.totalPages,
    required this.onUpdate,
  });

  @override
  State<_UpdateProgressSheet> createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<_UpdateProgressSheet> {
  late TextEditingController _controller;
  late int _selectedPage;
  
  @override
  void initState() {
    super.initState();
    _selectedPage = widget.currentPage;
    _controller = TextEditingController(text: '$_selectedPage');
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cập nhật tiến độ',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedPage > 0
                    ? () {
                        setState(() {
                          _selectedPage--;
                          _controller.text = '$_selectedPage';
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    final page = int.tryParse(value);
                    if (page != null && page >= 0 && page <= widget.totalPages) {
                      setState(() {
                        _selectedPage = page;
                      });
                    }
                  },
                ),
              ),
              Text(
                ' / ${widget.totalPages}',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _selectedPage < widget.totalPages
                    ? () {
                        setState(() {
                          _selectedPage++;
                          _controller.text = '$_selectedPage';
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedPage.toDouble(),
            min: 0,
            max: widget.totalPages.toDouble(),
            onChanged: (value) {
              setState(() {
                _selectedPage = value.toInt();
                _controller.text = '$_selectedPage';
              });
            },
            activeColor: AppColors.primaryStart,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onUpdate(_selectedPage);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cập nhật',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
