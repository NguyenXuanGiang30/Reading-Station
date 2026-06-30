/// NoteEditorScreen - Tao/Sua ghi chu
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart' show AppConstants;
import '../../models/note.dart';
import '../../services/flashcard_service.dart';
import '../../services/note_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final String? bookId;
  final String? initialText;

  const NoteEditorScreen({
    super.key,
    this.noteId,
    this.bookId,
    this.initialText,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final FlashcardService _flashcardService = FlashcardService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();

  int? _pageNumber;
  List<String> _tags = [];
  String? _ocrImageUrl;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _createFlashcard = false;
  bool _isAlreadyFlashcard = false;

  bool get isEditing => widget.noteId != null;
  bool get _hasInitialOcrText =>
      widget.initialText != null && widget.initialText!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadNote();
    } else if (_hasInitialOcrText) {
      _contentController.text = widget.initialText!;
    }
    _contentController.addListener(_markChanged);
    _pageController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_markChanged)
      ..dispose();
    _pageController
      ..removeListener(_markChanged)
      ..dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) return;

    setState(() => _isLoading = true);

    try {
      final Note? note = await _noteService.getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _contentController.text = note.content;
          _pageNumber = note.pageNumber;
          _pageController.text = note.pageNumber?.toString() ?? '';
          _tags = note.tags.toList();
          _ocrImageUrl = note.ocrImageUrl;
          _isAlreadyFlashcard = note.isFlashcard;
          _createFlashcard = false;
          _hasChanges = false;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context).t("note_load_err")}: $e')),
        );
      }
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagsController.clear();
      _hasChanges = true;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    final contentResult = Validators.required(
      content,
      fieldName: S.of(context).t('note_content_label'),
    );
    if (!contentResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contentResult.errorMessage!)),
      );
      return;
    }

    final descResult = Validators.maxLength(
      content,
      AppConstants.maxDescriptionLength,
      fieldName: S.of(context).t('note_content_label'),
    );
    if (!descResult.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(descResult.errorMessage!)),
      );
      return;
    }

    if (!isEditing && widget.bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).t('note_missing_book'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? targetNoteId;
      if (isEditing) {
        targetNoteId = widget.noteId;
        await _noteService.updateNote(
          widget.noteId!,
          content: content,
          pageNumber: _pageNumber,
          tags: _tags,
        );
      } else {
        final newNote = await _noteService.createNote(
          bookId: widget.bookId!,
          content: content,
          pageNumber: _pageNumber,
          tags: _tags,
        );
        targetNoteId = newNote?.id;
      }

      if (_createFlashcard && !_isAlreadyFlashcard && targetNoteId != null) {
        try {
          await _flashcardService.createCardFromNote(targetNoteId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).t('note_fc_created'))),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${S.of(context).t("note_fc_err")}: $e')),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? S.of(context).t('note_updated') : S.of(context).t('note_created'),
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loi: $e')));
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(S.of(context).t('note_exit_title')),
            content: Text(S.of(context).t('note_exit_msg')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(S.of(context).t('note_stay')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(S.of(context).t('note_exit_btn')),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _onWillPop()) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: isEditing ? S.of(context).t('note_edit') : S.of(context).t('note_create'),
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop() && context.mounted) {
                context.pop();
              }
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PrimaryButton(
            label: isEditing ? 'Cap nhat ghi chu' : S.of(context).t('note_save'),
            loading: _isLoading,
            onPressed: _isLoading ? null : _saveNote,
          ),
        ),
        body:
            _isLoading && isEditing
                ? SafeArea(
                  child: LoadingWidget(
                    fullScreen: true,
                    message: S.of(context).t('note_loading'),
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    _buildHeroCard(context),
                    const SizedBox(height: AppSpacing.xl),
                    ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _pageController,
                                  label: S.of(context).t('note_page'),
                                  hint: S.of(context).t('note_page_hint'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefix: const Icon(Icons.bookmark_outline_rounded),
                                  onChanged: (value) {
                                    _pageNumber = int.tryParse(value);
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed:
                                    () => context.push('/ocr?bookId=${widget.bookId ?? ''}'),
                                icon: const Icon(Icons.document_scanner_outlined),
                                label: const Text('OCR'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CustomTextField(
                            controller: _contentController,
                            label: S.of(context).t('note_content_label'),
                            hint: S.of(context).t('note_content_hint'),
                            maxLines: 10,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (value) {
                              final result = Validators.maxLength(
                                value,
                                AppConstants.maxDescriptionLength,
                                fieldName: S.of(context).t('note_content_label'),
                              );
                              return result.isValid ? null : result.errorMessage;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTagsSection(context),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFlashcardSection(context),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final isOcrFlow = _hasInitialOcrText || _ocrImageUrl != null;

    return ModernCard(
      gradient: AppGradients.warmHero,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEditing ? S.of(context).t('note_edit') : S.of(context).t('note_hero_title'),
            subtitle:
                isOcrFlow
                    ? S.of(context).t('note_ocr_desc')
                    : S.of(context).t('note_hero_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetaChip(
                icon: Icons.text_snippet_outlined,
                label: '${_contentController.text.trim().length} ${S.of(context).t("note_chars")}',
                color: AppColors.primary,
              ),
              _MetaChip(
                icon: Icons.sell_outlined,
                label: '${_tags.length} tag',
                color: AppColors.secondary,
              ),
              _MetaChip(
                icon: Icons.auto_awesome_rounded,
                label: _createFlashcard || _isAlreadyFlashcard
                    ? S.of(context).t('note_has_fc')
                    : S.of(context).t('note_no_fc'),
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('note_tags_title'),
            subtitle: S.of(context).t('note_tags_desc'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _tagsController,
                  label: S.of(context).t('note_add_tag'),
                  hint: S.of(context).t('note_tag_hint'),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _addTag,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_tags.isEmpty)
            Text(
              S.of(context).t('note_no_tags'),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children:
                  _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardSection(BuildContext context) {
    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.style_rounded, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('takeaway_create_fc'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isAlreadyFlashcard
                      ? S.of(context).t('note_fc_linked')
                      : S.of(context).t('note_fc_create_desc'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: _isAlreadyFlashcard ? true : _createFlashcard,
            onChanged:
                _isAlreadyFlashcard
                    ? null
                    : (value) {
                      setState(() {
                        _createFlashcard = value;
                        _hasChanges = true;
                      });
                    },
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
