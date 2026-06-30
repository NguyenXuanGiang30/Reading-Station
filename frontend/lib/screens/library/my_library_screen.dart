/// MyLibraryScreen - Thư viện sách cá nhân
library;

import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../services/user_book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';

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

  List<UserBook> _books = [];

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
      final books =
          content
              .map((e) => UserBook.fromJson(e as Map<String, dynamic>))
              .toList();

      if (!mounted) return;
      setState(() {
        if (refresh || _currentPage == 0) {
          _books = books;
        } else {
          _books.addAll(books);
        }
        _hasMore = _currentPage < totalPages - 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 240 &&
        !_isLoadingMore &&
        _hasMore) {
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
    setState(() => _selectedStatus = status);
    _loadBooks(refresh: true);
  }

  List<UserBook> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _books;

    return _books.where((book) {
      return book.book.title.toLowerCase().contains(query) ||
          book.book.author.toLowerCase().contains(query) ||
          (book.book.category ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Map<ReadingStatus, int> get _statusCounts {
    return {
      ReadingStatus.reading:
          _books.where((book) => book.status == ReadingStatus.reading).length,
      ReadingStatus.read:
          _books.where((book) => book.status == ReadingStatus.read).length,
      ReadingStatus.wantToRead:
          _books.where((book) => book.status == ReadingStatus.wantToRead).length,
    };
  }

  int get _pagesRead {
    return _books.fold<int>(0, (sum, book) => sum + book.currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookOptions(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(S.of(context).t('lib_add_book')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadBooks(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeroSection(context),
                    const SizedBox(height: AppSpacing.xl),
                    SearchBarWidget(
                      controller: _searchController,
                      hintText: S.of(context).t('lib_search_hint'),
                      onChanged: (_) => setState(() {}),
                      trailing:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip(null, S.of(context).t('lib_filter_all')),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ReadingStatus.reading, S.of(context).t('lib_filter_reading')),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ReadingStatus.read, S.of(context).t('lib_filter_completed')),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ReadingStatus.wantToRead, S.of(context).t('lib_filter_want')),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
              _buildSliverContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return ModernCard(
      gradient: AppGradients.warmHero,
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  title: S.of(context).t('lib_title'),
                  subtitle:
                      '${_books.length} ${S.of(context).t('lib_subtitle_count')}',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _HeaderActionButton(
                icon:
                    _isGridView
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_rounded,
                onTap: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: AppSpacing.sm),
              _HeaderActionButton(
                icon: Icons.refresh_rounded,
                onTap: () => _loadBooks(refresh: true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _OverviewPill(
                  label: S.of(context).t('lib_reading'),
                  value: '${_statusCounts[ReadingStatus.reading] ?? 0}',
                  icon: Icons.auto_stories_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewPill(
                  label: S.of(context).t('lib_completed'),
                  value: '${_statusCounts[ReadingStatus.read] ?? 0}',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewPill(
                  label: S.of(context).t('lib_pages_read'),
                  value: '$_pagesRead',
                  icon: Icons.menu_book_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingWidget(
          key: const ValueKey('library-loading'),
          fullScreen: true,
          message: S.of(context).t('lib_loading'),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateWidget(
          key: const ValueKey('library-error'),
          message: _error!,
          onRetry: () => _loadBooks(refresh: true),
        ),
      );
    }

    if (_filteredBooks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          key: const ValueKey('library-empty'),
          title: S.of(context).t('lib_empty'),
          message:
              _searchController.text.isEmpty
                  ? S.of(context).t('lib_empty_msg')
                  : S.of(context).t('lib_empty_search'),
          icon:
              _searchController.text.isEmpty
                  ? Icons.local_library_outlined
                  : Icons.search_off_rounded,
          actionLabel: _searchController.text.isEmpty ? S.of(context).t('lib_add_book') : null,
          onAction:
              _searchController.text.isEmpty
                  ? () => _showAddBookOptions(context)
                  : null,
        ),
      );
    }

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= _filteredBooks.length) {
                return const Center(child: CircularProgressIndicator());
              }
              final userBook = _filteredBooks[index];
              return _GridBookCard(userBook: userBook);
            },
            childCount: _filteredBooks.length + (_isLoadingMore ? 1 : 0),
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.66,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= _filteredBooks.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final userBook = _filteredBooks[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _filteredBooks.length - 1 ? AppSpacing.md : 0,
              ),
              child: _ListBookCard(userBook: userBook),
            );
          },
          childCount: _filteredBooks.length + (_isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildFilterChip(ReadingStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      showCheckmark: false,
      avatar:
          isSelected
              ? const Icon(Icons.done_rounded, size: 16, color: AppColors.primary)
              : null,
      onSelected: (_) => _onStatusFilterChanged(isSelected ? null : status),
    );
  }

  void _showAddBookOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: S.of(context).t('lib_add_new'),
                  subtitle: S.of(context).t('lib_add_subtitle'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SheetOptionTile(
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                  title: S.of(context).t('lib_scan_barcode'),
                  subtitle: S.of(context).t('lib_scan_subtitle'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/scanner');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _SheetOptionTile(
                  icon: Icons.edit_outlined,
                  iconColor: AppColors.info,
                  backgroundColor: AppColors.info.withValues(alpha: 0.14),
                  title: S.of(context).t('lib_manual_add'),
                  subtitle: S.of(context).t('lib_manual_subtitle'),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.push('/book/add');
                  },
                ),
              ],
            ),
          ),
    );
  }
}

class _GridBookCard extends StatelessWidget {
  final UserBook userBook;

  const _GridBookCard({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;

    return ModernCard(
      onTap: () => context.push('/book/${userBook.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'book-cover-${userBook.id}',
            child: _BookCover(book: book, height: 160),
          ),
          const SizedBox(height: AppSpacing.md),
          StatusChip(
            label: userBook.status.label,
            color: _statusColor(userBook.status),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            book.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            book.author,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if ((book.category ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              book.category!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          if (userBook.status == ReadingStatus.reading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: userBook.progressPercent / 100,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${userBook.currentPage}/${book.totalPages} trang',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  S.of(context).t('lib_view_detail'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ListBookCard extends StatelessWidget {
  final UserBook userBook;

  const _ListBookCard({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;

    return ModernCard(
      onTap: () => context.push('/book/${userBook.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'book-cover-${userBook.id}',
            child: SizedBox(
              width: 76,
              child: _BookCover(book: book, height: 110),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if ((book.category ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.category!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    StatusChip(
                      label: userBook.status.label,
                      color: _statusColor(userBook.status),
                    ),
                    if (userBook.status == ReadingStatus.reading) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: userBook.progressPercent / 100,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${userBook.progressPercent.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.primary),
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
          const SizedBox(width: AppSpacing.md),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;
  final double height;

  const _BookCover({required this.book, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient:
              AppColors.deckGradients[book.title.length %
                  AppColors.deckGradients.length],
          image:
              book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? DecorationImage(
                    image: NetworkImage(book.coverUrl!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            book.coverUrl == null || book.coverUrl!.isEmpty
                ? const Center(
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                )
                : null,
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _OverviewPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
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
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SheetOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOptionTile({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
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
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

Color _statusColor(ReadingStatus status) {
  switch (status) {
    case ReadingStatus.reading:
      return AppColors.primary;
    case ReadingStatus.read:
      return AppColors.success;
    case ReadingStatus.wantToRead:
      return AppColors.info;
  }
}
