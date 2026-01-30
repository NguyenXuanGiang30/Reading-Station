/// CreateFlashcardScreen - Tạo flashcard thủ công
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/flashcard_service.dart';
import '../../models/flashcard.dart';

class CreateFlashcardScreen extends StatefulWidget {
  final String? deckId; // Optional: pre-select a deck

  const CreateFlashcardScreen({super.key, this.deckId});

  @override
  State<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final FlashcardService _service = FlashcardService();
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  
  String? _selectedDeckId;
  List<FlashcardDeck> _decks = [];
  bool _isLoading = false;
  bool _isLoadingDecks = true;

  @override
  void initState() {
    super.initState();
    _selectedDeckId = widget.deckId;
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await _service.getDecks();
      if (mounted) {
        setState(() {
          _decks = decks;
          _isLoadingDecks = false;
          // Auto-select first deck if none selected and decks available
          if (_selectedDeckId == null && _decks.isNotEmpty) {
            _selectedDeckId = _decks.first.userBookId;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDecks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách bộ thẻ: $e')),
        );
      }
    }
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn bộ thẻ (sách)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.createCard(
        deckId: _selectedDeckId!,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo flashcard thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tạo Flashcard',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveFlashcard,
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
      body: _isLoadingDecks
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deck Selection
                    Text(
                      'Bộ thẻ (Sách)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDeckId,
                      items: _decks.map((deck) {
                        return DropdownMenuItem(
                          value: deck.userBookId,
                          child: Text(
                            deck.bookTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDeckId = value);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      ),
                      hint: const Text('Chọn bộ thẻ'),
                      isExpanded: true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Front
                    Text(
                      'Mặt trước (Câu hỏi)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _frontController,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập câu hỏi';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Back
                    Text(
                      'Mặt sau (Câu trả lời)',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _backController,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập câu trả lời';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập câu trả lời...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
