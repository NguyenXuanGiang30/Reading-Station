/// CreateFlashcardScreen - Tao flashcard thu cong
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../../services/flashcard_service.dart';
import '../../services/user_book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final String? deckId;

  const CreateFlashcardScreen({super.key, this.deckId});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final FlashcardService _service = FlashcardService();
  final UserBookService _userBookService = UserBookService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  String? _selectedBookId;
  List<UserBook> _books = [];
  bool _isLoading = false;
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.deckId;
    _loadBooks();
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      final response = await _userBookService.getUserBooks(page: 0, size: 100);
      final content = response['content'] as List? ?? const [];
      final books =
          content
              .map((item) => UserBook.fromJson(item as Map<String, dynamic>))
              .toList();

      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoadingBooks = false;
        if (_selectedBookId == null && _books.isNotEmpty) {
          _selectedBookId = _books.first.book.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingBooks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).t("create_fc_load_err")}: $e')),
      );
    }
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).t('focus_select_book'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createCard(
        deckId: _selectedBookId!,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).t('create_fc_saved'))),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loi: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('takeaway_create_fc'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: PrimaryButton(
          label: S.of(context).t('create_fc_save'),
          loading: _isLoading,
          onPressed: _isLoading ? null : _saveFlashcard,
        ),
      ),
      body:
          _isLoadingBooks
              ? SafeArea(
                child: LoadingWidget(
                  fullScreen: true,
                  message: S.of(context).t('create_fc_loading'),
                ),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    ModernCard(
                      gradient: AppGradients.warmHero,
                      elevated: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
            title: S.of(context).t('create_fc_add_deck'),
                            subtitle: S.of(context).t('create_fc_hero_desc'),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (_selectedBookId != null && _books.isNotEmpty)
                            _SelectedBookPreview(
                              userBook:
                                  _books.firstWhere(
                                    (book) => book.book.id == _selectedBookId,
                                    orElse: () => _books.first,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: S.of(context).t('create_fc_linked_book'),
                            subtitle: S.of(context).t('create_fc_linked_desc'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBookId,
                            decoration: InputDecoration(
                              labelText: S.of(context).t('focus_select_book'),
                            ),
                            items:
                                _books
                                    .map(
                                      (userBook) => DropdownMenuItem<String>(
                                        value: userBook.book.id,
                                        child: Text(
                                          userBook.book.title,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() => _selectedBookId = value);
                            },
                            isExpanded: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ModernCard(
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _frontController,
                            label: S.of(context).t('fc_session_front'),
                            hint: S.of(context).t('create_fc_front_hint'),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              final result = Validators.required(
                                value,
                                fieldName: S.of(context).t('create_fc_front_field'),
                              );
                              return result.isValid ? null : result.errorMessage;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CustomTextField(
                            controller: _backController,
                            label: S.of(context).t('fc_session_back'),
                            hint: S.of(context).t('create_fc_back_hint'),
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              final result = Validators.required(
                                value,
                                fieldName: S.of(context).t('create_fc_back_field'),
                              );
                              return result.isValid ? null : result.errorMessage;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SelectedBookPreview extends StatelessWidget {
  final UserBook userBook;

  const _SelectedBookPreview({required this.userBook});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 78,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            image:
                userBook.book.coverUrl != null && userBook.book.coverUrl!.isNotEmpty
                    ? DecorationImage(
                      image: NetworkImage(userBook.book.coverUrl!),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              userBook.book.coverUrl == null || userBook.book.coverUrl!.isEmpty
                  ? const Icon(Icons.auto_stories_rounded, color: Colors.white)
                  : null,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
