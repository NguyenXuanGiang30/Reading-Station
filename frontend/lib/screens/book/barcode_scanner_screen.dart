/// BarcodeScannerScreen - Quet barcode them sach
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;
  String? _lastScannedCode;
  bool _torchEnabled = false;
  bool _frontCamera = false;
  bool _scanLineAtBottom = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _scanLineAtBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isScanning = false;
      _lastScannedCode = code;
    });

    _showBookResult(code);
  }

  Future<void> _scanFromGallery() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('barcode_web_unsupported')),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ModernCard(
          child: LoadingWidget(message: S.of(context).t('barcode_analyzing')),
        ),
      ),
    );

    try {
      await _controller?.analyzeImage(image.path);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (_isScanning) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).t('barcode_not_found')),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showBookResult(String isbn) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BookResultSheet(
        isbn: isbn,
        onAddBook: () {
          Navigator.pop(sheetContext);
          context.push('/book/add?isbn=$isbn');
        },
        onScanAgain: () {
          Navigator.pop(sheetContext);
          setState(() {
            _isScanning = true;
            _lastScannedCode = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null)
            MobileScanner(controller: _controller!, onDetect: _onDetect),
          _buildOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  _buildScanPanel(),
                  const Spacer(),
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.36),
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.44),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _FloatingActionIcon(
          icon: Icons.close_rounded,
          onTap: () => context.pop(),
        ),
        const Spacer(),
        ModernCard(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            S.of(context).t('barcode_title'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
        const Spacer(),
        _FloatingActionIcon(
          icon: Icons.edit_note_rounded,
          onTap: () => context.push('/book/add'),
        ),
      ],
    );
  }

  Widget _buildScanPanel() {
    return Column(
      children: [
        Container(
          width: 296,
          height: 192,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              ..._buildCorners(),
              if (_isScanning)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: _scanLineAtBottom ? -1 : 1,
                    end: _scanLineAtBottom ? 1 : -1,
                  ),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeInOut,
                  onEnd: () {
                    if (mounted && _isScanning) {
                      setState(() => _scanLineAtBottom = !_scanLineAtBottom);
                    }
                  },
                  builder: (context, value, child) {
                    return Align(
                      alignment: Alignment(0, value),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary,
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.60),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ModernCard(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                _isScanning
                    ? S.of(context).t('barcode_center_barcode')
                    : S.of(context).t('barcode_recognized'),
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isScanning
                    ? S.of(context).t('barcode_hold_steady')
                    : S.of(context).t('barcode_showing_result'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const cornerSize = 28.0;
    const cornerWidth = 4.0;
    const color = AppColors.primary;

    return [
      _CornerLine(
        top: 0,
        left: 0,
        width: cornerSize,
        height: cornerWidth,
        color: color,
      ),
      _CornerLine(
        top: 0,
        left: 0,
        width: cornerWidth,
        height: cornerSize,
        color: color,
      ),
      _CornerLine(
        top: 0,
        right: 0,
        width: cornerSize,
        height: cornerWidth,
        color: color,
      ),
      _CornerLine(
        top: 0,
        right: 0,
        width: cornerWidth,
        height: cornerSize,
        color: color,
      ),
      _CornerLine(
        bottom: 0,
        left: 0,
        width: cornerSize,
        height: cornerWidth,
        color: color,
      ),
      _CornerLine(
        bottom: 0,
        left: 0,
        width: cornerWidth,
        height: cornerSize,
        color: color,
      ),
      _CornerLine(
        bottom: 0,
        right: 0,
        width: cornerSize,
        height: cornerWidth,
        color: color,
      ),
      _CornerLine(
        bottom: 0,
        right: 0,
        width: cornerWidth,
        height: cornerSize,
        color: color,
      ),
    ];
  }

  Widget _buildBottomControls() {
    return ModernCard(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.08),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _ControlButton(
                  icon: _torchEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  label: 'Flash',
                  selected: _torchEnabled,
                  onTap: () {
                    setState(() => _torchEnabled = !_torchEnabled);
                    _controller?.toggleTorch();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ControlButton(
                  icon: Icons.flip_camera_ios_rounded,
                  label: _frontCamera ? S.of(context).t('barcode_front_cam') : S.of(context).t('barcode_back_cam'),
                  selected: _frontCamera,
                  onTap: () {
                    setState(() => _frontCamera = !_frontCamera);
                    _controller?.switchCamera();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ControlButton(
                  icon: Icons.photo_library_outlined,
                  label: S.of(context).t('barcode_gallery'),
                  onTap: _scanFromGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/book/add'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              ),
              icon: const Icon(Icons.keyboard_rounded),
              label: Text(S.of(context).t('barcode_manual_isbn')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookResultSheet extends StatefulWidget {
  final String isbn;
  final VoidCallback onAddBook;
  final VoidCallback onScanAgain;

  const _BookResultSheet({
    required this.isbn,
    required this.onAddBook,
    required this.onScanAgain,
  });

  @override
  State<_BookResultSheet> createState() => _BookResultSheetState();
}

class _BookResultSheetState extends State<_BookResultSheet> {
  final BookService _bookService = BookService();

  Map<String, dynamic>? _bookData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookInfo();
  }

  Future<void> _fetchBookInfo() async {
    try {
      final result = await _bookService.getBookByIsbn(widget.isbn);
      if (!mounted) return;
      setState(() {
        _bookData = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookData = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _bookData != null && _bookData!['found'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: LoadingWidget(message: S.of(context).t('barcode_searching')),
            )
          else ...[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: found
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                found ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                size: 42,
                color: found ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              found ? S.of(context).t('barcode_book_found') : S.of(context).t('barcode_book_not_found'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ISBN: ${widget.isbn}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (found)
              ModernCard(
                gradient: const LinearGradient(
                  colors: [AppColors.surfaceAlt, AppColors.surface],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 96,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        image: _hasCover
                            ? DecorationImage(
                                image: NetworkImage(
                                  '${_bookData!['coverUrl']}',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !_hasCover
                          ? const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_bookData!['title'] ?? ''}',
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${_bookData!['author'] ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          if ((_bookData!['publisher'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xs,
                              ),
                              child: Text(
                                '${_bookData!['publisher']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ModernCard(
                padding: const EdgeInsets.all(16),
                child: SectionHeader(
                  title: S.of(context).t('barcode_add_manual'),
                  subtitle: S.of(context).t('barcode_add_manual_desc'),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onScanAgain,
                    child: Text(S.of(context).t('barcode_scan_again')),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: found ? S.of(context).t('barcode_add_book') : S.of(context).t('barcode_manual'),
                    onPressed: widget.onAddBook,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  bool get _hasCover =>
      _bookData?['coverUrl'] != null &&
      _bookData!['coverUrl'].toString().isNotEmpty;
}

class _FloatingActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.08),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      gradient: LinearGradient(
        colors: selected
            ? [
                AppColors.primary.withValues(alpha: 0.26),
                AppColors.primary.withValues(alpha: 0.18),
              ]
            : [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.06),
              ],
      ),
      border: Border.all(
        color: selected
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.08),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CornerLine extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double width;
  final double height;
  final Color color;

  const _CornerLine({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
