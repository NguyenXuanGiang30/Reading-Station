/// OCRCameraScreen - Chụp ảnh để OCR
library;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class OCRCameraScreen extends StatefulWidget {
  final String? bookId;
  
  const OCRCameraScreen({super.key, this.bookId});

  @override
  State<OCRCameraScreen> createState() => _OCRCameraScreenState();
}

class _OCRCameraScreenState extends State<OCRCameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  final ImagePicker _picker = ImagePicker();
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        if (mounted) {
           setState(() => _errorMsg = 'Không tìm thấy camera');
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
         setState(() => _errorMsg = 'Lỗi khởi động camera: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        context.push('/ocr/edit?image=${Uri.encodeComponent(image.path)}&bookId=${widget.bookId ?? ''}');
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chụp ảnh')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        context.push('/ocr/edit?image=${Uri.encodeComponent(pickedFile.path)}&bookId=${widget.bookId ?? ''}');
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    
    try {
      _flashOn = !_flashOn;
      await _controller!.setFlashMode(
        _flashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            Center(
              child: _errorMsg != null 
                  ? Text(_errorMsg!, style: const TextStyle(color: Colors.white))
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          
          // Overlay with focus area
          _buildOverlay(),
          
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          // Top dark area
          Expanded(
            flex: 2,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          
          // Focus area
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryStart, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Guide text
                Center(
                  child: Text(
                    'Đặt văn bản trong khung',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom dark area
          Expanded(
            flex: 3,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
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
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Text(
              'Chụp ảnh OCR',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: _toggleFlash,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _flashOn ? Icons.flash_on : Icons.flash_off,
                  color: _flashOn ? AppColors.warning : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Tips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '💡 Đảm bảo đủ ánh sáng và văn bản rõ ràng',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Capture button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  _buildControlButton(
                    icon: Icons.photo_library,
                    onTap: _pickImage,
                  ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _captureImage,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.grey : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                    ),
                  ),
                  
                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
