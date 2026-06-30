/// OCRCameraScreen - Chup anh de OCR
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../l10n/app_localizations.dart';

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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
          setState(() => _isInitialized = true);
        }
      } else if (mounted) {
        setState(() => _errorMsg = S.of(context).t('ocr_no_camera'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMsg = '${S.of(context).t("ocr_cam_err")}: $e');
      }
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        context.push(
          '/ocr/edit?image=${Uri.encodeComponent(image.path)}&bookId=${widget.bookId ?? ''}',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).t('ocr_capture_err'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        context.push(
          '/ocr/edit?image=${Uri.encodeComponent(pickedFile.path)}&bookId=${widget.bookId ?? ''}',
        );
      }
    } catch (_) {}
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    try {
      _flashOn = !_flashOn;
      await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildPreview()),
          Positioned.fill(child: _buildOverlay()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _TopButton(
                      icon: Icons.close_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    ModernCard(
                      gradient: AppGradients.softGlassOverlay,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        S.of(context).t('ocr_camera_title'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _TopButton(
                      icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      onTap: _toggleFlash,
                      active: _flashOn,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: Column(
                children: [
                  ModernCard(
                    gradient: AppGradients.softGlassOverlay,
                    child: Column(
                      children: [
                        Text(
                          S.of(context).t('ocr_place_text'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BottomAction(
                              icon: Icons.photo_library_outlined,
                              label: S.of(context).t('barcode_gallery'),
                              onTap: _pickImage,
                            ),
                            GestureDetector(
                              onTap: _isCapturing ? null : _captureImage,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Color(0xFFF4E7E1)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child:
                                      _isCapturing
                                          ? const Padding(
                                            padding: EdgeInsets.all(24),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.camera_alt_rounded,
                                            color: AppColors.primary,
                                            size: 34,
                                          ),
                                ),
                              ),
                            ),
                            _BottomAction(
                              icon: Icons.auto_awesome_outlined,
                              label: 'OCR',
                              onTap: _isInitialized ? _captureImage : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isInitialized && _controller != null) {
      return CameraPreview(_controller!);
    }

    return Center(
      child:
          _errorMsg != null
              ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              )
              : const CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black.withValues(alpha: 0.45))),
        Container(
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Center(
            child: Text(
               S.of(context).t('ocr_place_in_frame'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
      ],
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _TopButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          active
              ? AppColors.warning.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: active ? AppColors.warning : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
