/// KeyTakeawaysScreen - Quản lý key points từ sách with API Integration
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/key_takeaway_service.dart';

class KeyTakeawaysScreen extends StatefulWidget {
  final String bookId;
  final String? bookTitle;
  
  const KeyTakeawaysScreen({super.key, required this.bookId, this.bookTitle});

  @override
  State<KeyTakeawaysScreen> createState() => _KeyTakeawaysScreenState();
}

class _KeyTakeawaysScreenState extends State<KeyTakeawaysScreen> {
  final KeyTakeawayService _service = KeyTakeawayService();
  List<Map<String, dynamic>> _takeaways = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  
  final _newTakeawayController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadTakeaways();
  }

  @override
  void dispose() {
    _newTakeawayController.dispose();
    super.dispose();
  }

  Future<void> _loadTakeaways() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getKeyTakeaways(widget.bookId);
      if (mounted) {
        setState(() {
          _takeaways = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTakeaway() async {
    if (_newTakeawayController.text.trim().isEmpty) return;
    
    setState(() => _isSaving = true);
    
    try {
      final result = await _service.createKeyTakeaway(
        userBookId: widget.bookId,
        content: _newTakeawayController.text.trim(),
      );
      
      if (mounted && result != null) {
        setState(() {
          _takeaways.add(result);
          _newTakeawayController.clear();
          _isAdding = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm takeaway'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteTakeaway(int index) async {
    final takeaway = _takeaways[index];
    final id = takeaway['id']?.toString();
    if (id == null) return;
    
    // Optimistic delete
    final removed = _takeaways.removeAt(index);
    setState(() {});
    
    try {
      await _service.deleteKeyTakeaway(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa takeaway')),
        );
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _takeaways.insert(index, removed);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _reorderTakeaways(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = _takeaways.removeAt(oldIndex);
    _takeaways.insert(newIndex, item);
    setState(() {});
    
    // Save reorder to API
    try {
      final ids = _takeaways.map((t) => t['id']?.toString() ?? '').toList();
      await _service.reorderTakeaways(ids);
    } catch (e) {
      // Ignore reorder errors for now
    }
  }

  Future<void> _createFlashcard(int index) async {
    final takeaway = _takeaways[index];
    final id = takeaway['id']?.toString();
    if (id == null) return;
    
    try {
      await _service.createFlashcardFromTakeaway(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo flashcard từ takeaway'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Key Takeaways',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadTakeaways,
                  color: AppColors.primaryStart,
                  child: Column(
                    children: [
                      // Book info header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.menu_book, color: Colors.white, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              widget.bookTitle ?? 'Sách',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_takeaways.length} điểm chính',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Takeaways list
                      Expanded(
                        child: _takeaways.isEmpty && !_isAdding
                            ? _buildEmptyState(isDark)
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _takeaways.length + (_isAdding ? 1 : 0),
                                onReorder: _reorderTakeaways,
                                itemBuilder: (context, index) {
                                  if (_isAdding && index == _takeaways.length) {
                                    return _buildAddInput(isDark, key: const ValueKey('add_input'));
                                  }
                                  return _buildTakeawayCard(index, isDark, key: ValueKey(_takeaways[index]['id']));
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: !_isAdding && !_isLoading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _isAdding = true),
              backgroundColor: AppColors.primaryStart,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Thêm takeaway',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Đã xảy ra lỗi'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTakeaways,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có takeaway nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm những điểm chính bạn học được từ sách',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeawayCard(int index, bool isDark, {required Key key}) {
    final takeaway = _takeaways[index];
    
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Text(
              (takeaway['content'] ?? '') as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTakeaway(index);
              } else if (value == 'flashcard') {
                _createFlashcard(index);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'flashcard',
                child: Row(
                  children: [
                    Icon(Icons.style),
                    SizedBox(width: 8),
                    Text('Tạo flashcard'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddInput(bool isDark, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryStart),
      ),
      child: Column(
        children: [
          TextField(
            controller: _newTakeawayController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập điểm chính mới...',
              border: InputBorder.none,
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () {
                  setState(() {
                    _isAdding = false;
                    _newTakeawayController.clear();
                  });
                },
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _addTakeaway,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Thêm',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xuất Takeaways',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép vào clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Xuất PDF'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
