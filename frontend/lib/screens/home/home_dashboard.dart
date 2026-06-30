/// HomeDashboard - Trang chủ tổng quan
library;

import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../models/book.dart';
import '../../models/note.dart';
import '../../services/note_service.dart';
import '../../services/user_book_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final UserService _userService = UserService();
  final UserBookService _userBookService = UserBookService();
  final NoteService _noteService = NoteService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<UserBook> _readingBooks = [];
  List<Note> _recentNotes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _userService.getReadingStats(),
        _userBookService.getUserBooks(status: ReadingStatus.reading, size: 10),
        _noteService.getAllNotes(page: 0, size: 3),
      ]);

      if (!mounted) return;
      final booksData = results[1] as Map<String, dynamic>;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _readingBooks =
            (booksData['content'] as List?)
                ?.map((e) => UserBook.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _recentNotes = results[2] as List<Note>;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingWidget(
                  message: S.of(context).t('home_loading'),
                  fullScreen: true,
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(message: _error!, onRetry: _loadData),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroReadingCard(context),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildStatsSection(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildContinueReadingStrip(context),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildRecentNotesSection(context),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.select<AuthBloc, dynamic>(
      (bloc) => bloc.state is AuthAuthenticated
          ? (bloc.state as AuthAuthenticated).user
          : null,
    );
    final dateLabel = DateFormat(
      'EEEE, d MMMM',
      'vi_VN',
    ).format(DateTime.now());

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.editorialSurface),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        MediaQuery.of(context).padding.top + AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${S.of(context).t('home_greeting')} ${user?.fullName?.split(' ').last ?? S.of(context).t('home_you')}',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  backgroundColor: AppColors.primarySoft,
                  child: user?.avatarUrl == null
                      ? Text(
                          (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.primary),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SearchBarWidget(
            hintText: S.of(context).t('home_search_hint'),
            readOnly: true,
            onTap: () => context.push('/search'),
            trailing: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroReadingCard(BuildContext context) {
    if (_readingBooks.isEmpty) {
      return EmptyStateWidget(
        title: S.of(context).t('home_no_session'),
        message: S.of(context).t('home_no_session_msg'),
        icon: Icons.auto_stories_outlined,
      );
    }

    final current = _readingBooks.first;
    final progress = current.progressPercent / 100;

    return ModernCard(
      gradient: AppGradients.warmHero,
      elevated: true,
      onTap: () => context.push('/book/${current.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: S.of(context).t('home_reading'),
            color: AppColors.primary,
            icon: Icons.local_fire_department_rounded,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Hero(
                tag: 'book-cover-${current.id}',
                child: _BookCover(book: current.book, height: 168, width: 118),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.book.title,
                      style: Theme.of(context).textTheme.headlineLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      current.book.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.42),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${current.currentPage}/${current.book.totalPages} ${S.of(context).t('home_pages')} • ${current.progressPercent.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => context.push('/book/${current.id}'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(S.of(context).t('home_continue')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final items = [
      (
        S.of(context).t('home_books_read'),
        '${_stats['totalBooksRead'] ?? 0}',
        AppColors.secondary,
        Icons.menu_book_rounded,
      ),
      (
        S.of(context).t('home_pages_read'),
        '${_stats['totalReadPages'] ?? 0}',
        AppColors.info,
        Icons.sticky_note_2_outlined,
      ),
      (
        S.of(context).t('home_notes'),
        '${_stats['totalNotes'] ?? 0}',
        AppColors.accent,
        Icons.edit_note_rounded,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == items.last ? 0 : AppSpacing.md,
                  ),
                  child: ModernCard(
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: item.$3.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(item.$4, color: item.$3),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            item.$2,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.$1,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildContinueReadingStrip(BuildContext context) {
    if (_readingBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('home_continue_section'),
          subtitle: S.of(context).t('home_continue_subtitle'),
          trailing: TextButton(
            onPressed: () => context.go('/library'),
            child: Text(S.of(context).t('home_view_all')),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 246,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _readingBooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) {
              final userBook = _readingBooks[index];
              return SizedBox(
                width: 170,
                child: ModernCard(
                  onTap: () => context.push('/book/${userBook.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'book-cover-${userBook.id}',
                        child: _BookCover(
                          book: userBook.book,
                          height: 128,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: userBook.progressPercent / 100,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${userBook.progressPercent.toStringAsFixed(0)}% ${S.of(context).t('home_completed_pct')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentNotesSection(BuildContext context) {
    if (_recentNotes.isEmpty) return const SizedBox.shrink();
    final dateFormat = DateFormat('HH:mm • dd/MM', 'vi_VN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('home_recent_notes'),
          subtitle: S.of(context).t('home_recent_notes_subtitle'),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._recentNotes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ModernCard(
              onTap: () => context.push('/note/${note.id}'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notes_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${S.of(context).t('home_page_label')} ${note.pageNumber ?? '?'} • ${dateFormat.format(note.createdAt ?? DateTime.now())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final actions = [
          (S.of(context).t('home_scan_isbn'), Icons.qr_code_scanner_rounded, '/scanner'),
          (S.of(context).t('home_add_book'), Icons.add_circle_outline_rounded, '/book/add'),
          ('OCR', Icons.document_scanner_outlined, '/ocr'),
          (S.of(context).t('home_review'), Icons.auto_awesome_rounded, '/review'),
          (S.of(context).t('ai_title'), Icons.smart_toy_rounded, '/ai-chat'),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: S.of(context).t('home_quick_create'),
                subtitle: S.of(context).t('home_quick_create_subtitle'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: actions.map((action) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 60) / 2,
                    child: ModernCard(
                      onTap: () {
                        context.pop();
                        context.push(action.$3);
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(action.$2, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              action.$1,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;
  final double height;
  final double width;

  const _BookCover({
    required this.book,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: width,
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
            ? const Center(
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
