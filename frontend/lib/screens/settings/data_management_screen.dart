/// DataManagementScreen - Quản lý dữ liệu
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/colors.dart';
import '../../services/settings_service.dart';
import '../../services/note_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/user_book_service.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final SettingsService _settingsService = SettingsService();
  final NoteService _noteService = NoteService();
  final FlashcardService _flashcardService = FlashcardService();
  final UserBookService _userBookService = UserBookService();
  
  bool _isExporting = false;
  bool _isBackingUp = false;

  Future<void> _backupData() async {
    setState(() => _isBackingUp = true);
    
    try {
      // Collect all data
      final settings = await _settingsService.exportSettings();
      final books = await _userBookService.getUserBooks();
      
      List<dynamic> notes = [];
      try {
        notes = await _noteService.getAllNotes();
      } catch (_) {}
      
      List<dynamic> flashcards = [];
      try {
        flashcards = await _flashcardService.getDecks();
      } catch (_) {}

      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'settings': settings,
        'books': books,
        'notes': notes,
        'flashcards': flashcards,
      };

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'tramdoc_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(backupData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã sao lưu dữ liệu thành công!\n📁 $fileName',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi sao lưu: ${e.toString()}', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Khôi phục dữ liệu', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Chức năng này sẽ thay thế dữ liệu hiện tại bằng dữ liệu từ file backup. Bạn có chắc chắn muốn tiếp tục?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('Tiếp tục', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tính năng đang được phát triển. Vui lòng sử dụng file manager để chọn file backup.',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      // Collect data for export
      final books = await _userBookService.getUserBooks();
      
      List<dynamic> notes = [];
      try {
        notes = await _noteService.getAllNotes();
      } catch (_) {}

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalBooks': (books as List?)?.length ?? 0,
        'totalNotes': notes.length,
        'books': books,
        'notes': notes,
      };

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'tramdoc_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(exportData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xuất dữ liệu thành công!\n📁 $fileName',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất dữ liệu: ${e.toString()}', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa cache', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Xóa cache sẽ giải phóng dung lượng nhưng ảnh và dữ liệu tạm thời sẽ phải tải lại. Tiếp tục?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Xóa cache', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final cacheDir = await getTemporaryDirectory();
        if (cacheDir.existsSync()) {
          cacheDir.deleteSync(recursive: true);
          await cacheDir.create();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa cache thành công!', style: GoogleFonts.inter()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}', style: GoogleFonts.inter()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý dữ liệu',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Backup section
          _buildSection(
            title: 'Sao lưu & Khôi phục',
            children: [
              _buildActionItem(
                icon: Icons.cloud_upload_outlined,
                title: 'Sao lưu dữ liệu',
                subtitle: 'Lưu toàn bộ dữ liệu vào file',
                onTap: _isBackingUp ? null : _backupData,
                isLoading: _isBackingUp,
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 72),
              _buildActionItem(
                icon: Icons.cloud_download_outlined,
                title: 'Khôi phục dữ liệu',
                subtitle: 'Phục hồi từ file backup',
                onTap: _restoreData,
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Export section
          _buildSection(
            title: 'Xuất dữ liệu',
            children: [
              _buildActionItem(
                icon: Icons.download_outlined,
                title: 'Xuất dữ liệu JSON',
                subtitle: 'Xuất sách và ghi chú thành file JSON',
                onTap: _isExporting ? null : _exportData,
                isLoading: _isExporting,
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Cache section
          _buildSection(
            title: 'Bộ nhớ đệm',
            children: [
              _buildActionItem(
                icon: Icons.cleaning_services_outlined,
                title: 'Xóa cache',
                subtitle: 'Giải phóng dung lượng bộ nhớ đệm',
                onTap: _clearCache,
                isDark: isDark,
                isDestructive: true,
              ),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'File backup và export được lưu trong thư mục Documents của ứng dụng.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isDark,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.primaryStart;
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }
}
