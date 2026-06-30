/// OCREditScreen - Trich xuat va chinh sua van ban
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../l10n/app_localizations.dart';

class OCREditScreen extends StatefulWidget {
  final String? imagePath;
  final String? bookId;

  const OCREditScreen({super.key, this.imagePath, this.bookId});

  @override
  State<OCREditScreen> createState() => _OCREditScreenState();
}

class _OCREditScreenState extends State<OCREditScreen> {
  bool _isProcessing = false;
  bool _textExtracted = false;
  final TextEditingController _textController = TextEditingController();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  void dispose() {
    _textController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processImage() async {
    if (widget.imagePath == null) return;

    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath!);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (!mounted) return;
      setState(() {
        _textController.text = recognizedText.text;
        _textExtracted = true;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${S.of(context).t("ocr_process_err")}: $e')));
    }
  }

  void _createNote() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.push(
      '/note/create?bookId=${widget.bookId ?? ''}&text=${Uri.encodeComponent(text)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('ocr_extract_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(S.of(context).t('ocr_retake')),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: S.of(context).t('ocr_create_note'),
                onPressed:
                    _textExtracted && _textController.text.trim().isNotEmpty
                        ? _createNote
                        : null,
                icon: const Icon(
                  Icons.note_add_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          ModernCard(
            gradient: AppGradients.warmHero,
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: S.of(context).t('ocr_editor_title'),
                  subtitle: S.of(context).t('ocr_editor_desc'),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _processImage,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: Text(_textExtracted ? S.of(context).t('ocr_re_extract') : S.of(context).t('ocr_start')),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1.2,
                child:
                    widget.imagePath != null
                        ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                        : Container(
                          color: AppColors.surfaceAlt,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 52,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: S.of(context).t('ocr_extracted_text'),
                  subtitle: S.of(context).t('ocr_edit_before_save'),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  TextField(
                    controller: _textController,
                    maxLines: 12,
                    decoration: InputDecoration(
                      hintText: S.of(context).t('ocr_hint'),
                    ),
                    onChanged: (_) {
                      if (!_textExtracted) {
                        setState(() => _textExtracted = true);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
