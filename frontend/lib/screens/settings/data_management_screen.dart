/// DataManagementScreen - Quan ly du lieu
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/flashcard_service.dart';
import '../../services/note_service.dart';
import '../../services/settings_service.dart';
import '../../services/user_book_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../l10n/app_localizations.dart';

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

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'tramdoc_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(backupData));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).t("data_backup_ok")}: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).t("data_backup_err")}: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _restoreData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).t('data_restore_title')),
        content: Text(
          S.of(context).t('data_restore_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(context).t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.of(context).t('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          S.of(context).t('data_restore_coming'),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
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

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'tramdoc_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).t("data_export_ok")}: $fileName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).t("data_export_err")}: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).t('data_clear_cache')),
        content: Text(
          S.of(context).t('data_clear_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(context).t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.of(context).t('data_clear_cache')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        await cacheDir.create();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).t('data_clear_success'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('data_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHeroCard(),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('data_backup_section'),
              subtitle:
                  S.of(context).t('data_backup_section_desc'),
              children: [
                SettingsTile(
                  icon: Icons.cloud_upload_outlined,
                  title: S.of(context).t('data_backup'),
                  subtitle: S.of(context).t('data_backup_desc'),
                  onTap: _isBackingUp ? null : _backupData,
                  loading: _isBackingUp,
                ),
                SettingsTile(
                  icon: Icons.cloud_download_outlined,
                  title: S.of(context).t('data_restore_title'),
                  subtitle: S.of(context).t('data_import_desc'),
                  onTap: _restoreData,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('data_export'),
              subtitle:
                  S.of(context).t('data_export_section_desc'),
              children: [
                SettingsTile(
                  icon: Icons.download_rounded,
                  title: S.of(context).t('data_export_json'),
                  subtitle: S.of(context).t('data_export_json_desc'),
                  onTap: _isExporting ? null : _exportData,
                  loading: _isExporting,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SettingsSectionCard(
              title: S.of(context).t('data_cache_section'),
              subtitle:
                  S.of(context).t('data_cache_desc'),
              children: [
                SettingsTile(
                  icon: Icons.cleaning_services_outlined,
                  title: S.of(context).t('data_clear_cache'),
                  subtitle: S.of(context).t('data_clear_desc'),
                  onTap: _clearCache,
                  destructive: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            ModernCard(
              padding: const EdgeInsets.all(20),
              gradient: AppGradients.softGlassOverlay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: S.of(context).t('data_note_title'),
                    subtitle:
                        S.of(context).t('data_note_desc'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    S.of(context).t('data_note_warning'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storage_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('data_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('data_hero_desc'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
