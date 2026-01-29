/// BarcodeScannerScreen - Quét barcode thêm sách
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/colors.dart';
import '../../services/book_service.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
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

  void _showBookResult(String isbn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookResultSheet(
        isbn: isbn,
        onAddBook: () {
          Navigator.pop(context);
          context.push('/book/add?isbn=$isbn');
        },
        onScanAgain: () {
          Navigator.pop(context);
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
          // Camera view
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),
          
          // Overlay
          _buildScanOverlay(),
          
          // Top bar
          _buildTopBar(context),
          
          // Bottom controls
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Stack(
        children: [
          // Dark overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          
          // Scan area
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: ClipRect(
                child: Stack(
                  children: [
                    // Clear area
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    
                    // Corner decorations
                    ..._buildCorners(),
                    
                    // Scanning animation
                    if (_isScanning)
                      AnimatedPositioned(
                        duration: const Duration(seconds: 2),
                        child: Container(
                          width: 280,
                          height: 2,
                          color: AppColors.primaryStart,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Remove dark from scan area
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.src),
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Instruction text
          Positioned(
            bottom: 250,
            left: 0,
            right: 0,
            child: Text(
              _isScanning ? 'Đưa mã vạch vào khung' : 'Đã quét thành công!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const cornerSize = 24.0;
    const cornerWidth = 3.0;
    const color = AppColors.primaryStart;
    
    return [
      // Top left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Top right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Bottom left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
      
      // Bottom right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerSize,
          height: cornerWidth,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: cornerWidth,
          height: cornerSize,
          color: color,
        ),
      ),
    ];
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Text(
              'Quét mã vạch',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Camera controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _torchEnabled ? Icons.flash_on : Icons.flash_off,
                    label: 'Đèn flash',
                    onTap: () {
                      setState(() {
                        _torchEnabled = !_torchEnabled;
                      });
                      _controller?.toggleTorch();
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.flip_camera_ios,
                    label: 'Đổi camera',
                    onTap: () {
                      setState(() {
                        _frontCamera = !_frontCamera;
                      });
                      _controller?.switchCamera();
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.photo_library,
                    label: 'Thư viện',
                    onTap: () {
                      // TODO: Pick from gallery
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Manual entry button
              TextButton(
                onPressed: () => context.push('/book/add'),
                child: Text(
                  'Nhập thủ công',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.primaryStart,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
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
      if (mounted) {
        setState(() {
          _bookData = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookData = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final found = _bookData != null && _bookData!['found'] == true;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.primaryStart),
            )
          else ...[
            // Result icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: found
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                found ? Icons.check_circle : Icons.help_outline,
                size: 40,
                color: found ? AppColors.success : AppColors.warning,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              found ? 'Tìm thấy sách!' : 'Không tìm thấy',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'ISBN: ${widget.isbn}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            if (found) ...[
              const SizedBox(height: 24),
              
              // Book info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                        image: _bookData!['coverUrl'] != null && _bookData!['coverUrl'].toString().isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_bookData!['coverUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _bookData!['coverUrl'] == null || _bookData!['coverUrl'].toString().isEmpty
                          ? const Icon(Icons.menu_book, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bookData!['title'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bookData!['author'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (_bookData!['publisher'] != null && _bookData!['publisher'].toString().isNotEmpty)
                            Text(
                              _bookData!['publisher'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onScanAgain,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Quét lại',
                      style: GoogleFonts.inter(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAddBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      found ? 'Thêm sách' : 'Nhập thủ công',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
