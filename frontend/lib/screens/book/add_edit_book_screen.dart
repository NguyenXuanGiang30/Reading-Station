/// AddEditBookScreen - Form thêm/sửa sách
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../models/book.dart';
import '../../services/user_book_service.dart';
import '../../services/book_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddEditBookScreen extends StatefulWidget {
  final String? bookId;
  final String? isbn;
  
  const AddEditBookScreen({super.key, this.bookId, this.isbn});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _userBookService = UserBookService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _publisherController = TextEditingController();
  final _pagesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  ReadingStatus _status = ReadingStatus.wantToRead;
  String? _category;
  String? _coverUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  
  bool get isEditing => widget.bookId != null;
  
  final List<String> _categories = [
    'Tự phát triển',
    'Kinh doanh',
    'Tâm lý',
    'Tiểu thuyết',
    'Khoa học',
    'Lịch sử',
    'Triết học',
    'Khác',
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

  Future<void> _loadBook() async {
    if (widget.bookId == null) return;
    
    try {
      setState(() => _isLoading = true);
      // Fetch user book details
      final data = await _userBookService.getUserBookById(widget.bookId!);
      
      if (data != null && data['book'] != null) {
        final book = data['book'];
        _titleController.text = book['title'] ?? '';
        _authorController.text = book['author'] ?? '';
        _isbnController.text = book['isbn'] ?? '';
        _publisherController.text = book['publisher'] ?? '';
        _pagesController.text = (data['currentPage'] ?? book['totalPages'] ?? 0).toString(); // Using currentPage as progress proxy if needed, or totalPages
        // Corrections: _pagesController typically is total pages of book.
        // Let's assume user wants to edit book info.
        _pagesController.text = (book['totalPages'] ?? 0).toString();
        
        _descriptionController.text = book['description'] ?? '';
        _locationController.text = data['location'] ?? ''; // location is in UserBook
        
        // Status parsing
        try {
            final statusStr = data['status'] as String?;
            if (statusStr != null) {
                // Find enum by value or name
                _status = ReadingStatus.values.firstWhere(
                  (e) => e.value == statusStr || e.name.toUpperCase() == statusStr,
                  orElse: () => ReadingStatus.wantToRead,
                );
            }
        } catch (_) {}
        
        _category = book['category'];
        if (!_categories.contains(_category)) {
           _category = null; // or add to list dynamically
        }
        
        _coverUrl = book['coverUrl'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải sách: $e'), backgroundColor: AppColors.error),
        );
      }
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
            _pagesController.text = bookData['totalPages'].toString();
          }
          if (bookData['category'] != null && _categories.contains(bookData['category'])) {
            _category = bookData['category'];
          }
          if (bookData['coverUrl'] != null) {
            _coverUrl = bookData['coverUrl'];
          }
        });
      }
    } catch (e) {
      // Silently fail - user can still enter manually
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (isEditing) {
        await _userBookService.updateUserBook(
          userBookId: widget.bookId!,
          title: _titleController.text,
          author: _authorController.text,
          status: _status,
          category: _category,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          totalPages: int.tryParse(_pagesController.text),
        );
      } else {
        await _userBookService.addUserBook(
          title: _titleController.text,
          author: _authorController.text,
          status: _status,
          isbn: _isbnController.text.isNotEmpty ? _isbnController.text : null,
          publisher: _publisherController.text.isNotEmpty ? _publisherController.text : null,
          category: _category,
          coverUrl: _coverUrl, // Pass coverUrl if available from API/ISBN
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          totalPages: int.tryParse(_pagesController.text),
        );
      }
      
      // Warning if local image was selected but couldn't be uploaded
      if (_selectedImage != null && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Lưu ý: Ảnh tải lên chưa được hỗ trợ, chỉ lưu thông tin sách'),
             backgroundColor: Colors.orange,
           ),
         );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Đã cập nhật sách' : 'Đã thêm sách mới'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Chỉnh sửa sách' : 'Thêm sách mới',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBook,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Book cover placeholder
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : (_coverUrl != null && _coverUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(_coverUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: (_selectedImage == null && (_coverUrl == null || _coverUrl!.isEmpty))
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thêm ảnh bìa',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                      if (_selectedImage != null || (_coverUrl != null && _coverUrl!.isNotEmpty))
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _coverUrl = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Tên sách *',
              hint: 'Nhập tên sách',
              validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên sách' : null,
              isDark: isDark,
            ),
            
            const SizedBox(height: 16),
            
            // Author
            _buildTextField(
              controller: _authorController,
              label: 'Tác giả *',
              hint: 'Nhập tên tác giả',
              validator: (v) => v?.isEmpty == true ? 'Vui lòng nhập tên tác giả' : null,
              isDark: isDark,
            ),
            
            const SizedBox(height: 16),
            
            // ISBN
            _buildTextField(
              controller: _isbnController,
              label: 'ISBN',
              hint: 'Nhập mã ISBN',
              keyboardType: TextInputType.number,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => context.push('/scanner'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category & Status row
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Thể loại',
                    value: _category,
                    items: _categories,
                    onChanged: (v) => setState(() => _category = v),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusDropdown(isDark),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Publisher & Pages row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _publisherController,
                    label: 'Nhà xuất bản',
                    hint: 'NXB',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _pagesController,
                    label: 'Số trang',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Vị trí sách',
              hint: 'VD: Kệ sách phòng khách',
              prefixIcon: const Icon(Icons.location_on_outlined),
              isDark: isDark,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả',
              hint: 'Nhập mô tả sách...',
              maxLines: 4,
              isDark: isDark,
            ),
            
            const SizedBox(height: 32),
            
            // Scan barcode hint
            if (!isEditing)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mẹo: Quét mã vạch để tự động điền thông tin sách',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('Chọn'),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReadingStatus>(
          value: _status,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: ReadingStatus.values.map((status) => DropdownMenuItem(
            value: status,
            child: Text(status.label),
          )).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _status = v);
          },
        ),
      ],
    );
  }
}
