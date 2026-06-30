/// AddEditBookScreen - Form them/sua sach
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_constants.dart' show AppConstants;
import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../services/user_book_service.dart';
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
import '../../l10n/app_localizations.dart';

class AddEditBookScreen extends StatefulWidget {
  final String? bookId;
  final String? isbn;

  const AddEditBookScreen({super.key, this.bookId, this.isbn});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final UserBookService _userBookService = UserBookService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _pagesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  ReadingStatus _status = ReadingStatus.wantToRead;
  String? _category;
  String? _coverUrl;
  File? _selectedImage;
  bool _isLoading = false;

  bool get isEditing => widget.bookId != null;

  List<String> get _categories => [
    S.of(context).t('book_cat_self'),
    S.of(context).t('book_cat_business'),
    S.of(context).t('book_cat_psychology'),
    S.of(context).t('book_cat_novel'),
    S.of(context).t('book_cat_science'),
    S.of(context).t('book_cat_history'),
    S.of(context).t('book_cat_philosophy'),
    S.of(context).t('book_cat_other'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isbn != null) {
      _isbnController.text = widget.isbn!;
      _fetchBookInfo(widget.isbn!);
    }
    if (isEditing) {
      _loadBook();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _pagesController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    if (widget.bookId == null) return;

    try {
      setState(() => _isLoading = true);
      final data = await _userBookService.getUserBookById(widget.bookId!);

      if (data != null && data['book'] != null) {
        final book = data['book'];
        _titleController.text = book['title'] ?? '';
        _authorController.text = book['author'] ?? '';
        _isbnController.text = book['isbn'] ?? '';
        _publisherController.text = book['publisher'] ?? '';
        _pagesController.text = (book['totalPages'] ?? 0).toString();
        _descriptionController.text = book['description'] ?? '';
        _locationController.text = data['location'] ?? '';
        _category = book['category'];
        if (!_categories.contains(_category)) {
          _category = null;
        }
        _coverUrl = book['coverUrl'];

        final statusStr = data['status'] as String?;
        if (statusStr != null) {
          _status = ReadingStatus.values.firstWhere(
            (element) =>
                element.value == statusStr ||
                element.name.toUpperCase() == statusStr,
            orElse: () => ReadingStatus.wantToRead,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).t('book_load_err')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBookInfo(String isbn) async {
    setState(() => _isLoading = true);

    try {
      final bookService = BookService();
      final bookData = await bookService.getBookByIsbn(isbn);

      if (bookData != null && mounted) {
        setState(() {
          _titleController.text = bookData['title'] ?? '';
          _authorController.text = bookData['author'] ?? '';
          _publisherController.text = bookData['publisher'] ?? '';
          _descriptionController.text = bookData['description'] ?? '';
          if (bookData['totalPages'] != null && bookData['totalPages'] > 0) {
            _pagesController.text = '${bookData['totalPages']}';
          }
          if (bookData['category'] != null &&
              _categories.contains(bookData['category'])) {
            _category = bookData['category'];
          }
          if (bookData['coverUrl'] != null) {
            _coverUrl = bookData['coverUrl'];
          }
        });
      }
    } catch (_) {
      // Keep manual input available even if ISBN lookup fails.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${S.of(context).t('book_pick_err')}: $e')));
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await _userBookService.updateUserBook(
          userBookId: widget.bookId!,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          status: _status,
          category: _category,
          description:
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
          location:
              _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
          totalPages: int.tryParse(_pagesController.text.trim()),
        );
      } else {
        await _userBookService.addUserBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          status: _status,
          isbn:
              _isbnController.text.trim().isNotEmpty
                  ? _isbnController.text.trim()
                  : null,
          publisher:
              _publisherController.text.trim().isNotEmpty
                  ? _publisherController.text.trim()
                  : null,
          category: _category,
          coverUrl: _coverUrl,
          description:
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
          location:
              _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : null,
          totalPages: int.tryParse(_pagesController.text.trim()),
        );
      }

      if (_selectedImage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).t('book_cover_local_note'),
            ),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? S.of(context).t('book_updated') : S.of(context).t('book_added')),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? S.of(context).t('book_edit_title') : S.of(context).t('book_add_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: PrimaryButton(
          label: isEditing ? S.of(context).t('book_update_btn') : S.of(context).t('book_save_btn'),
          loading: _isLoading,
          onPressed: _isLoading ? null : _saveBook,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: AppSpacing.xl),
            _buildInfoSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildMetaSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildDescriptionSection(),
            if (!isEditing) ...[
              const SizedBox(height: AppSpacing.xl),
              ModernCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        S.of(context).t('book_isbn_tip'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return ModernCard(
      gradient: AppGradients.warmHero,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEditing ? S.of(context).t('book_edit_hero') : S.of(context).t('book_add_hero'),
            subtitle:
                isEditing
                    ? S.of(context).t('book_edit_hero_desc')
                    : S.of(context).t('book_add_hero_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _buildCoverPreview(),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(S.of(context).t('book_pick_cover')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/scanner'),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(S.of(context).t('book_scan_barcode')),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_coverUrl != null || _selectedImage != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _coverUrl = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(S.of(context).t('book_remove_cover')),
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

  Widget _buildInfoSection() {
    return ModernCard(
      child: Column(
        children: [
          CustomTextField(
            controller: _titleController,
            label: S.of(context).t('book_field_title'),
            hint: S.of(context).t('book_field_title_hint'),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final result = Validators.combine([
                Validators.required(value, fieldName: S.of(context).t('book_field_title')),
                Validators.maxLength(
                  value,
                  AppConstants.maxTitleLength,
                  fieldName: S.of(context).t('book_field_title'),
                ),
              ]);
              return result.isValid ? null : result.errorMessage;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField(
            controller: _authorController,
            label: S.of(context).t('book_field_author'),
            hint: S.of(context).t('book_field_author_hint'),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              final result = Validators.combine([
                Validators.required(value, fieldName: S.of(context).t('book_field_author')),
                Validators.maxLength(value, 200, fieldName: S.of(context).t('book_field_author')),
              ]);
              return result.isValid ? null : result.errorMessage;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _isbnController,
                  label: S.of(context).t('book_field_isbn'),
                  hint: S.of(context).t('book_field_isbn_hint'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final result = Validators.isbn(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                onPressed: () {
                  final isbn = _isbnController.text.trim();
                  if (isbn.isNotEmpty) {
                    _fetchBookInfo(isbn);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).t('book_isbn_search_err'))),
                    );
                  }
                },
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection() {
    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  label: S.of(context).t('book_field_category'),
                  value: _category,
                  hint: S.of(context).t('book_field_category_hint'),
                  items: _categories,
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdownField<ReadingStatus>(
                  label: S.of(context).t('book_field_status'),
                  value: _status,
                  hint: S.of(context).t('book_field_status_hint'),
                  items: ReadingStatus.values,
                  itemLabel: (value) => value.label,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _publisherController,
                  label: S.of(context).t('book_field_publisher'),
                  hint: S.of(context).t('book_field_publisher_hint'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomTextField(
                  controller: _pagesController,
                  label: S.of(context).t('book_field_pages'),
                  hint: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField(
            controller: _locationController,
            label: S.of(context).t('book_field_location'),
            hint: S.of(context).t('book_field_location_hint'),
            prefix: const Icon(Icons.location_on_outlined),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('book_desc_title'),
            subtitle: S.of(context).t('book_desc_subtitle'),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField(
            controller: _descriptionController,
            label: S.of(context).t('book_desc_label'),
            hint: S.of(context).t('book_desc_hint'),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              final result = Validators.maxLength(
                value,
                AppConstants.maxDescriptionLength,
                fieldName: S.of(context).t('book_desc_title'),
              );
              return result.isValid ? null : result.errorMessage;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPreview() {
    ImageProvider<Object>? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_coverUrl != null && _coverUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_coverUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        height: 176,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          image:
              imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
        ),
        child:
            imageProvider == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      S.of(context).t('book_add_cover'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T value)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel != null ? itemLabel(item) : '$item'),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
