/// SearchScreen - Tìm kiếm toàn cục
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../services/user_book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserBookService _service = UserBookService();

  bool _isLoading = true;
  String? _error;
  List<UserBook> _allBooks = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.getUserBooks(size: 60);
      final content = response['content'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _allBooks = content
            .map((e) => UserBook.fromJson(e as Map<String, dynamic>))
            .toList();
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

  List<UserBook> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allBooks;
    return _allBooks.where((book) {
      return book.book.title.toLowerCase().contains(query) ||
          book.book.author.toLowerCase().contains(query) ||
          (book.book.category ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
            title: S.of(context).t('search_title'),
              subtitle: S.of(context).t('search_subtitle'),
            ),
            const SizedBox(height: AppSpacing.xl),
            SearchBarWidget(
              controller: _searchController,
              hintText: S.of(context).t('search_hint'),
              onChanged: (_) => setState(() {}),
              trailing: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return LoadingWidget(fullScreen: true, message: S.of(context).t('search_loading'));
    }
    if (_error != null) {
      return ErrorStateWidget(message: _error!, onRetry: _loadBooks);
    }
    if (_filteredBooks.isEmpty) {
      return EmptyStateWidget(
            title: S.of(context).t('search_no_result'),
        message: S.of(context).t('search_no_result_desc'),
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.separated(
      itemCount: _filteredBooks.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final userBook = _filteredBooks[index];
        return ModernCard(
          onTap: () => context.push('/book/${userBook.id}'),
          child: Row(
            children: [
              Hero(
                tag: 'book-cover-${userBook.id}',
                child: _SearchCover(book: userBook.book),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userBook.book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      userBook.book.author,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatusChip(
                      label: userBook.status.label,
                      color: userBook.status == ReadingStatus.reading
                          ? AppColors.primary
                          : userBook.status == ReadingStatus.read
                          ? AppColors.success
                          : AppColors.info,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }
}

class _SearchCover extends StatelessWidget {
  final Book book;

  const _SearchCover({required this.book});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        height: 102,
        decoration: BoxDecoration(
          gradient:
              AppColors.deckGradients[book.title.length %
                  AppColors.deckGradients.length],
          image: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(book.coverUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: book.coverUrl == null || book.coverUrl!.isEmpty
            ? const Icon(Icons.auto_stories_rounded, color: Colors.white)
            : null,
      ),
    );
  }
}
