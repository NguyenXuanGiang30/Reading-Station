/// MyLibraryScreen - Thư viện sách cá nhân with API Integration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../models/book.dart';
import '../../services/user_book_service.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() => _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserBookService _userBookService = UserBookService();
  final ScrollController _scrollController = ScrollController();
  
  ReadingStatus? _selectedStatus;
  bool _isGridView = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 20;
  
  List<Map<String, dynamic>> _books = [];
  
  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBooks({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final response = await _userBookService.getUserBooks(
        status: _selectedStatus,
        page: _currentPage,
        size: _pageSize,
      );
      
      final content = response['content'] as List<dynamic>? ?? [];
      final totalPages = response['totalPages'] as int? ?? 1;
      
      setState(() {
        if (refresh || _currentPage == 0) {
          _books = content.map((e) => e as Map<String, dynamic>).toList();
        } else {
          _books.addAll(content.map((e) => e as Map<String, dynamic>));
        }
        _hasMore = _currentPage < totalPages - 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore && _hasMore) {
      _loadMoreBooks();
    }
  }
  
  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    await _loadBooks();
  }
  
  void _onStatusFilterChanged(ReadingStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadBooks(refresh: true);
  }

  List<Map<String, dynamic>> get _filteredBooks {
    if (_searchController.text.isEmpty) return _books;
    
    final query = _searchController.text.toLowerCase();
    return _books.where((book) =>
      (book['title'] ?? '').toLowerCase().contains(query) ||
      (book['author'] ?? '').toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thư viện',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        onPressed: () => _loadBooks(refresh: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sách...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(null, 'Tất cả', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(ReadingStatus.reading, 'Đang đọc', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(ReadingStatus.read, 'Hoàn thành', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(ReadingStatus.wantToRead, 'Muốn đọc', isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: _buildContent(isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookOptions(context),
        backgroundColor: AppColors.primaryStart,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Thêm sách',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState(isDark);
    }
    
    if (_filteredBooks.isEmpty) {
      return _buildEmptyState(isDark);
    }
    
    return _isGridView
        ? _buildGridView(isDark)
        : _buildListView(isDark);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryStart),
          SizedBox(height: 16),
          Text('Đang tải sách...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Không thể tải dữ liệu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadBooks(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(ReadingStatus? status, String label, bool isDark) {
    final isSelected = _selectedStatus == status;
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected 
            ? Colors.white 
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
      selectedColor: AppColors.primaryStart,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        _onStatusFilterChanged(selected ? status : null);
      },
    );
  }

  Widget _buildGridView(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _loadBooks(refresh: true),
      color: AppColors.primaryStart,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredBooks.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredBooks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryStart),
              ),
            );
          }
          return _buildBookGridCard(_filteredBooks[index], isDark, index);
        },
      ),
    );
  }

  Widget _buildListView(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _loadBooks(refresh: true),
      color: AppColors.primaryStart,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _filteredBooks.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _filteredBooks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryStart),
              ),
            );
          }
          return _buildBookListCard(_filteredBooks[index], isDark, index);
        },
      ),
    );
  }

  ReadingStatus _parseStatus(dynamic status) {
    if (status is ReadingStatus) return status;
    if (status is String) {
      switch (status.toUpperCase()) {
        case 'READING':
          return ReadingStatus.reading;
        case 'READ':
        case 'COMPLETED':
          return ReadingStatus.read;
        case 'WANT_TO_READ':
        default:
          return ReadingStatus.wantToRead;
      }
    }
    return ReadingStatus.wantToRead;
  }

  Widget _buildBookGridCard(Map<String, dynamic> book, bool isDark, int index) {
    final status = _parseStatus(book['status']);
    final currentPage = book['currentPage'] as int? ?? 0;
    final totalPages = book['totalPages'] as int? ?? 1;
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    
    return GestureDetector(
      onTap: () => context.push('/book/${book['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.deckGradients[index % AppColors.deckGradients.length],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: book['coverUrl'] != null ? DecorationImage(
                    image: NetworkImage(book['coverUrl']),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: Stack(
                  children: [
                    if (book['coverUrl'] == null)
                      const Center(
                        child: Icon(Icons.menu_book, color: Colors.white, size: 48),
                      ),
                    // Status badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'Không có tiêu đề',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['author'] ?? 'Không rõ tác giả',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (status == ReadingStatus.reading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(AppColors.reading),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentPage/$totalPages trang',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListCard(Map<String, dynamic> book, bool isDark, int index) {
    final status = _parseStatus(book['status']);
    final currentPage = book['currentPage'] as int? ?? 0;
    final totalPages = book['totalPages'] as int? ?? 1;
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    
    return GestureDetector(
      onTap: () => context.push('/book/${book['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.deckGradients[index % AppColors.deckGradients.length],
                borderRadius: BorderRadius.circular(12),
                image: book['coverUrl'] != null ? DecorationImage(
                  image: NetworkImage(book['coverUrl']),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: book['coverUrl'] == null
                  ? const Icon(Icons.menu_book, color: Colors.white, size: 32)
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Không có tiêu đề',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book['author'] ?? 'Không rõ tác giả',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                      if (status == ReadingStatus.reading) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.reading),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.reading,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sách nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm sách đầu tiên vào thư viện!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
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

  void _showAddBookOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              'Thêm sách mới',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                context.push('/scanner');
              },
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.qr_code_scanner, color: AppColors.primaryStart),
              ),
              title: Text('Quét barcode', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              subtitle: Text('Thêm sách bằng mã vạch', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                context.push('/book/add');
              },
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.edit, color: AppColors.info),
              ),
              title: Text('Thêm thủ công', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
              subtitle: Text('Nhập thông tin sách', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
