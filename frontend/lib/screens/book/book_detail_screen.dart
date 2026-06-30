/// BookDetailScreen - Chi tiết sách
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/book.dart';
import '../../services/reading_progress_service.dart';
import '../../services/user_book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/info_tile.dart';
import '../../widgets/data/status_chip.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final UserBookService _userBookService = UserBookService();
  final ReadingProgressService _readingProgressService = ReadingProgressService();

  Map<String, dynamic>? _book;
  bool _isLoading = true;
  String? _error;

  List<dynamic> _friendsWhoRead = [];
  bool _loadingFriends = false;

  @override
  void initState() {
    super.initState();
    _loadBook();
    _loadFriendsWhoRead();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _userBookService.getUserBookById(widget.bookId),
        _userBookService.getUserBookStats(widget.bookId),
      ]);
      final book = results[0];
      final stats = results[1] as Map<String, dynamic>;
      if (book == null) {
        throw Exception(S.of(context).t('book_not_found'));
      }

      final status = ReadingStatus.fromString(book['status'] as String?);
      final currentPage =
          stats['currentPage'] as int? ?? book['currentPage'] as int? ?? 0;
      final totalPages =
          stats['totalPages'] as int? ??
          book['totalPages'] as int? ??
          (book['book']?['totalPages'] as int?) ??
          0;
      final safePages = totalPages == 0 ? 1 : totalPages;
      final bookData = Map<String, dynamic>.from(
        (book['book'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      bookData['coverUrl'] = bookData['coverUrl'] ?? bookData['coverImageUrl'];
      bookData['totalPages'] = safePages;

      if (!mounted) return;
      setState(() {
        _book = {
          ...book,
          ...stats,
          'status': status,
          'currentPage': currentPage,
          'totalPages': safePages,
          'progress': (currentPage / safePages).clamp(0.0, 1.0),
          'book': bookData,
          'startDate': book['startDate'] ?? book['startedAt'],
          'lastReadDate':
              book['lastReadDate'] ??
              book['updatedAt'] ??
              book['completedAt'] ??
              book['startedAt'],
          'notesCount': book['notesCount'] ?? 0,
          'flashcardsCount': book['flashcardsCount'] ?? 0,
          'location': book['location'] ?? S.of(context).t('book_detail_not_updated'),
          'rating': book['rating'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendsWhoRead() async {
    setState(() => _loadingFriends = true);
    try {
      final friends = await _userBookService.getFriendsWhoReadBook(
        widget.bookId,
      );
      if (!mounted) return;
      setState(() {
        _friendsWhoRead = friends;
        _loadingFriends = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _friendsWhoRead = [];
        _loadingFriends = false;
      });
    }
  }

  void _shareBook() {
    if (_book == null) return;
    final book = _book!['book'] as Map<String, dynamic>;
    final title = book['title'] ?? S.of(context).t('book_default_title');
    final author = book['author'] ?? '';
    final description = book['description'] ?? '';
    final shareText =
        '📚 $title\n'
        '✍️ $author\n\n'
        '${description.toString().length > 150 ? '${description.toString().substring(0, 150)}...' : description}\n\n'
        '${S.of(context).t("book_share_text")}';

    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: LoadingWidget(
          fullScreen: true,
          message: S.of(context).t('book_detail_loading'),
        ),
      );
    }

    if (_error != null || _book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          message: _error ?? S.of(context).t('book_detail_not_found'),
          onRetry: _loadBook,
        ),
      );
    }

    final bookData = _book!['book'] as Map<String, dynamic>;
    final progress = _book!['progress'] as double;

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(context),
      body: RefreshIndicator(
        onRefresh: _loadBook,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              stretch: true,
              actions: [
                IconButton(
                  onPressed: () => context.push('/book/${widget.bookId}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _showMoreOptions(context),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.warmHero,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Hero(
                                tag: 'book-cover-${widget.bookId}',
                                child: _BookCover(
                                  coverUrl:
                                      (bookData['coverUrl'] ??
                                              bookData['coverImageUrl'])
                                          as String?,
                                  title: bookData['title']?.toString() ?? '',
                                  width: 132,
                                  height: 196,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusChip(
                                      label: (_book!['status'] as ReadingStatus)
                                          .label,
                                      color: _getStatusColor(
                                        _book!['status'] as ReadingStatus,
                                      ),
                                      icon: Icons.bookmark_rounded,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      bookData['title']?.toString() ?? '',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.displayMedium,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      bookData['author']?.toString() ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      '${_book!['currentPage']}/${_book!['totalPages']} ${S.of(context).t('home_pages')} • ${(progress * 100).toStringAsFixed(0)}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionStrip(context),
                    const SizedBox(height: AppSpacing.xxxl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: S.of(context).t('book_detail_desc'),
                            subtitle: S.of(context).t('book_detail_desc_sub'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            bookData['description']?.toString().isNotEmpty ==
                                    true
                                ? bookData['description'].toString()
                                : S.of(context).t('book_detail_no_desc'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
            title: S.of(context).t('book_info'),
                            subtitle: S.of(context).t('book_info_subtitle'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          InfoTile(
                            icon: Icons.category_outlined,
                            label: S.of(context).t('add_book_category'),
                            value:
                                bookData['category']?.toString() ?? S.of(context).t('book_unknown'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InfoTile(
                            icon: Icons.business_outlined,
                            label: S.of(context).t('add_book_publisher'),
                            value:
                                bookData['publisher']?.toString() ?? S.of(context).t('book_unknown'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InfoTile(
                            icon: Icons.confirmation_number_outlined,
                            label: S.of(context).t('book_field_isbn'),
                            value: bookData['isbn']?.toString() ?? S.of(context).t('book_detail_unknown'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InfoTile(
                            icon: Icons.place_outlined,
                            label: S.of(context).t('book_location'),
                            value:
                                _book!['location']?.toString() ??
                                S.of(context).t('book_detail_not_updated'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
            title: S.of(context).t('book_reading_stats'),
                            subtitle: S.of(context).t('book_stats_subtitle'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: _StatTile(
                                  label: S.of(context).t('book_detail_started'),
                                  value: _formatDate(_book!['startDate']),
                                  icon: Icons.play_circle_outline_rounded,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _StatTile(
                                  label: S.of(context).t('book_detail_last_read'),
                                  value: _formatDate(_book!['lastReadDate']),
                                  icon: Icons.history_toggle_off_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_loadingFriends)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxl),
                        child: LoadingWidget(
                          message: S.of(context).t('book_detail_loading_friends'),
                        ),
                      )
                    else if (_friendsWhoRead.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: S.of(context).t('book_detail_friends_reading'),
                              subtitle:
                                  '${_friendsWhoRead.length} ${S.of(context).t('book_detail_friends_count')}',
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _friendsWhoRead.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final friend =
                                      _friendsWhoRead[index]
                                          as Map<String, dynamic>;
                                  final name =
                                      friend['fullName'] ??
                                      friend['name'] ??
                                      friend['displayName'] ??
                                      S.of(context).t('profile_reader');
                                  return GestureDetector(
                                    onTap: () =>
                                        context.push('/friend/${friend['id']}'),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor:
                                              AppColors.primarySoft,
                                          backgroundImage:
                                              friend['avatarUrl'] != null
                                              ? NetworkImage(
                                                  friend['avatarUrl'] as String,
                                                )
                                              : null,
                                          child: friend['avatarUrl'] == null
                                              ? Text(
                                                  name
                                                      .toString()
                                                      .substring(0, 1)
                                                      .toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        SizedBox(
                                          width: 72,
                                          child: Text(
                                            name.toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
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

  Widget _buildActionStrip(BuildContext context) {
    final bookData = _book!['book'] as Map<String, dynamic>;
    final actions = [
      (
        S.of(context).t('book_detail_notes'),
        '${_book!['notesCount']}',
        AppColors.info,
        Icons.note_alt_outlined,
        () => context.push('/book/${widget.bookId}/notes'),
      ),
      (
        'Flashcard',
        '${_book!['flashcardsCount']}',
        AppColors.secondary,
        Icons.style_outlined,
        () => context.push('/flashcard/session?deckId=${bookData['id']}'),
      ),
      (
        S.of(context).t('book_detail_share'),
        S.of(context).t('book_detail_share_now'),
        AppColors.accent,
        Icons.share_outlined,
        _shareBook,
      ),
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: action == actions.last ? 0 : AppSpacing.md,
            ),
            child: ModernCard(
              onTap: action.$5,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: action.$3.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(action.$4, color: action.$3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    action.$1,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(action.$2, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateProgress(context),
                icon: const Icon(Icons.auto_graph_rounded),
                label: Text(S.of(context).t('book_detail_update')),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/note/create?bookId=${widget.bookId}'),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(S.of(context).t('book_detail_notes')),
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
        return AppColors.primary;
      case ReadingStatus.read:
        return AppColors.success;
      case ReadingStatus.wantToRead:
        return AppColors.info;
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(S.of(context).t('book_detail_share_book')),
                onTap: () {
                  context.pop();
                  _shareBook();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(S.of(context).t('book_detail_add_list')),
                onTap: () => context.pop(),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  S.of(context).t('book_detail_delete'),
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  context.pop();
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateProgress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UpdateProgressSheet(
        currentPage: _book!['currentPage'] as int,
        totalPages: _book!['totalPages'] as int,
        onUpdate: (newPage) async {
          await _readingProgressService.updateProgress(
            userBookId: widget.bookId,
            currentPage: newPage,
          );
          if (!mounted) return;
          setState(() {
            _book!['currentPage'] = newPage;
            _book!['progress'] = newPage / (_book!['totalPages'] as int);
            _book!['lastReadDate'] = DateTime.now().toIso8601String();
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(context).t('book_detail_delete')),
          content: Text(
            S.of(context).t('book_detail_delete_confirm'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(S.of(context).t('book_detail_cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(this.context);
                final router = GoRouter.of(this.context);
                navigator.pop();
                try {
                  await _userBookService.deleteUserBook(widget.bookId);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(S.of(context).t('book_detail_deleted'))),
                  );
                  router.pop();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('$e'.replaceAll('Exception: ', ''))),
                  );
                }
              },
              child: Text(S.of(context).t('book_detail_delete')),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return S.of(context).t('book_detail_not_updated');
    final text = value.toString();
    if (text.isEmpty || text == 'null') return S.of(context).t('book_detail_not_updated');
    return text.length >= 10 ? text.substring(0, 10) : text;
  }
}

class _BookCover extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final double width;
  final double height;

  const _BookCover({
    required this.coverUrl,
    required this.title,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: AppColors
              .deckGradients[title.length % AppColors.deckGradients.length],
          image: coverUrl != null && coverUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(coverUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: coverUrl == null || coverUrl!.isEmpty
            ? const Center(
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressSheet extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Future<void> Function(int newPage) onUpdate;

  const _UpdateProgressSheet({
    required this.currentPage,
    required this.totalPages,
    required this.onUpdate,
  });

  @override
  State<_UpdateProgressSheet> createState() => _UpdateProgressSheetState();
}

class _UpdateProgressSheetState extends State<_UpdateProgressSheet> {
  late final TextEditingController _controller;
  late int _selectedPage;
  bool _isSubmitting = false;

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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            title: S.of(context).t('book_detail_update_progress'),
            subtitle: S.of(context).t('book_detail_update_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
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
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                  decoration: InputDecoration(
                    labelText: S.of(context).t('book_detail_page_current'),
                  ),
                  onChanged: (value) {
                    final page = int.tryParse(value);
                    if (page != null &&
                        page >= 0 &&
                        page <= widget.totalPages) {
                      setState(() => _selectedPage = page);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: _selectedPage < widget.totalPages
                    ? () {
                        setState(() {
                          _selectedPage++;
                          _controller.text = '$_selectedPage';
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      setState(() => _isSubmitting = true);
                      try {
                        await widget.onUpdate(_selectedPage);
                        if (mounted) {
                          navigator.pop();
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    },
              child: Text(S.of(context).t('book_detail_save_progress')),
            ),
          ),
        ],
      ),
    );
  }
}
