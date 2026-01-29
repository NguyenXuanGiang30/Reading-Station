/// OCREditScreen - Crop ảnh và trích xuất văn bản
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../theme/colors.dart';

class OCREditScreen extends StatefulWidget {
  final String? imagePath;
  final String? bookId;
  
  const OCREditScreen({super.key, this.imagePath, this.bookId});

  @override
  State<OCREditScreen> createState() => _OCREditScreenState();
}

class _OCREditScreenState extends State<OCREditScreen> {
  bool _isProcessing = false;
  String _extractedText = '';
  bool _textExtracted = false;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    if (widget.imagePath == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath!);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      setState(() {
        _extractedText = recognizedText.text;
        _textExtracted = true;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('OCR error: $e');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _useExtractedText() {
    // Return the text to previous screen
    context.pop(_extractedText);
  }

  void _createNote() {
    context.push('/note/create?bookId=${widget.bookId ?? ''}&text=${Uri.encodeComponent(_extractedText)}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trích xuất văn bản',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            flex: 2,
            child: _buildImagePreview(isDark),
          ),
          
          // Extracted text area
          Expanded(
            flex: 3,
            child: _buildTextArea(isDark),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, isDark),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      child: widget.imagePath != null
          ? Image.file(
              File(widget.imagePath!),
              fit: BoxFit.contain,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có ảnh',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Văn bản trích xuất',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              if (!_textExtracted && !_isProcessing)
                TextButton.icon(
                  onPressed: _processImage,
                  icon: const Icon(Icons.document_scanner, size: 18),
                  label: const Text('Trích xuất'),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: _isProcessing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang xử lý OCR...'),
                        ],
                      ),
                    )
                  : _textExtracted
                      ? SingleChildScrollView(
                          child: SelectableText(
                            _extractedText.isEmpty
                                ? 'Không tìm thấy văn bản trong ảnh'
                                : _extractedText,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.6,
                              color: _extractedText.isEmpty
                                  ? Colors.grey
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.text_snippet_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nhấn "Trích xuất" để bắt đầu',
                                style: GoogleFonts.inter(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _textExtracted && _extractedText.isNotEmpty
                    ? _createNote
                    : null,
                icon: const Icon(Icons.note_add, color: Colors.white),
                label: Text(
                  'Tạo ghi chú',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryStart,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
