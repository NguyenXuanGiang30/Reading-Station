/// NoteEditorScreen - Tạo/Sửa ghi chú với OCR
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/note_service.dart';
import '../../services/flashcard_service.dart';
import '../../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final String? bookId;
  
  const NoteEditorScreen({super.key, this.noteId, this.bookId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final FlashcardService _flashcardService = FlashcardService();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  int? _pageNumber;
  List<String> _tags = [];
  String? _ocrImagePath;
  bool _isLoading = false;
  bool _isLoadingNote = false;
  bool _hasChanges = false;
  bool _createFlashcard = false;
  bool _isAlreadyFlashcard = false;
  String? _error;

  bool get isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadNote();
    }
    _contentController.addListener(() {
      if (!_hasChanges) setState(() => _hasChanges = true);
    });
  }

  Future<void> _loadNote() async {
    if (widget.noteId == null) return;
    
    setState(() {
      _isLoadingNote = true;
      _error = null;
    });
    
    try {
      final Note? note = await _noteService.getNoteById(widget.noteId!);
      if (note != null && mounted) {
        setState(() {
          _contentController.text = note.content;
          _pageNumber = note.pageNumber;
          _tags = note.tags.toList();
          _isAlreadyFlashcard = note.isFlashcard;
          // If it's already a flashcard, we don't need to create one
          _createFlashcard = false;
          _isLoadingNote = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingNote = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung ghi chú')),
      );
      return;
    }

    if (widget.bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang thiếu bookId')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      String? targetNoteId;

      if (isEditing) {
        targetNoteId = widget.noteId;
        await _noteService.updateNote(widget.noteId!,
          content: _contentController.text.trim(),
          pageNumber: _pageNumber,
          tags: _tags,
        );
      } else {
        final newNote = await _noteService.createNote(
          bookId: widget.bookId!,
          content: _contentController.text.trim(),
          pageNumber: _pageNumber,
          tags: _tags,
        );
        targetNoteId = newNote?.id;
      }
      
      // Handle Flashcard Creation
      if (_createFlashcard && !_isAlreadyFlashcard && targetNoteId != null) {
         try {
           await _flashcardService.createCardFromNote(targetNoteId);
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Đã tạo flashcard từ ghi chú')),
             );
           }
         } catch (e) {
            print('Flashcard creation error: $e');
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Lỗi tạo flashcard: $e'), backgroundColor: AppColors.error),
               );
            }
         }
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Đã cập nhật ghi chú' : 'Đã tạo ghi chú mới'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bạn muốn thoát?'),
        content: const Text('Thay đổi chưa được lưu sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _onWillPop()) {
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing ? 'Sửa ghi chú' : 'Tạo ghi chú',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveNote,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Lưu',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryStart,
                      ),
                    ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OCR Section
              if (_ocrImagePath != null) _buildOcrImage(isDark),
              
              // OCR Button
              _buildOcrButton(context, isDark),
              
              const SizedBox(height: 20),
              
              // Page number
              _buildPageInput(isDark),
              
              const SizedBox(height: 20),
              
              // Content
              _buildContentField(isDark),
              
              const SizedBox(height: 20),
              
              // Tags
              _buildTagsSection(isDark),
              
              const SizedBox(height: 32),
              
              // Create flashcard option
              _buildFlashcardOption(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOcrImage(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh OCR',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã trích xuất văn bản',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _ocrImagePath = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOcrButton(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => context.push('/ocr?bookId=${widget.bookId}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primaryStart.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: AppColors.primaryStart,
            ),
            const SizedBox(width: 12),
            Text(
              'Chụp ảnh & trích xuất văn bản (OCR)',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppColors.primaryStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageInput(bool isDark) {
    return Row(
      children: [
        Text(
          'Trang:',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            controller: TextEditingController(text: _pageNumber?.toString() ?? ''),
            onChanged: (value) {
              _pageNumber = int.tryParse(value);
              _hasChanges = true;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nội dung ghi chú',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contentController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung ghi chú của bạn...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        
        // Tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: 'Thêm tag...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryStart,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Tags list
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) => Chip(
            label: Text(tag),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _removeTag(tag),
            backgroundColor: AppColors.primaryStart.withValues(alpha: 0.15),
            labelStyle: GoogleFonts.inter(
              color: AppColors.primaryStart,
              fontWeight: FontWeight.w500,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildFlashcardOption(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.style, color: AppColors.success),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo Flashcard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Tạo thẻ ôn tập từ ghi chú này',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            activeColor: AppColors.success,
            onChanged: _isAlreadyFlashcard 
                ? null 
                : (value) {
                    setState(() {
                      _createFlashcard = value;
                      _hasChanges = true;
                    });
                  },
            value: _isAlreadyFlashcard ? true : _createFlashcard,
          ),
        ],
      ),
    );
  }
}
