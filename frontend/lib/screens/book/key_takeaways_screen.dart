/// KeyTakeawaysScreen - Quan ly key takeaways tu sach
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/key_takeaway_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_container.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class KeyTakeawaysScreen extends StatefulWidget {
  final String bookId;
  final String? bookTitle;

  const KeyTakeawaysScreen({super.key, required this.bookId, this.bookTitle});

  @override
  State<KeyTakeawaysScreen> createState() => _KeyTakeawaysScreenState();
}

class _KeyTakeawaysScreenState extends State<KeyTakeawaysScreen> {
  final KeyTakeawayService _service = KeyTakeawayService();
  final TextEditingController _newTakeawayController = TextEditingController();

  List<Map<String, dynamic>> _takeaways = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
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
      if (!mounted) return;
      setState(() {
        _takeaways = data.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addTakeaway() async {
    final content = _newTakeawayController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final result = await _service.createKeyTakeaway(
        userBookId: widget.bookId,
        content: content,
      );

      if (!mounted || result == null) return;
      setState(() {
        _takeaways = [..._takeaways, result];
        _newTakeawayController.clear();
        _isAdding = false;
        _isSaving = false;
      });
      _showSnackBar(S.of(context).t('takeaway_added_msg'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Loi: $e');
    }
  }

  Future<void> _deleteTakeaway(int index) async {
    final takeaway = _takeaways[index];
    final id = takeaway['id']?.toString();
    if (id == null) return;

    final removed = _takeaways.removeAt(index);
    setState(() {});

    try {
      await _service.deleteKeyTakeaway(id);
      if (!mounted) return;
      _showSnackBar(S.of(context).t('takeaway_deleted_msg'));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _takeaways.insert(index, removed);
      });
      _showSnackBar('${S.of(context).t("error_delete")}: $e');
    }
  }

  Future<void> _reorderTakeaways(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _takeaways.removeAt(oldIndex);
    _takeaways.insert(newIndex, item);
    setState(() {});

    try {
      final ids = _takeaways
          .map((item) => item['id']?.toString() ?? '')
          .toList();
      await _service.reorderTakeaways(ids);
    } catch (_) {}
  }

  Future<void> _createFlashcard(int index) async {
    final takeaway = _takeaways[index];
    final id = takeaway['id']?.toString();
    if (id == null) return;

    try {
      await _service.createFlashcardFromTakeaway(id);
      if (!mounted) return;
      _showSnackBar(S.of(context).t('takeaway_fc_created'));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Loi: $e');
    }
  }

  Future<void> _copyAllTakeaways() async {
    final content = _exportText;
    if (content.isEmpty) {
      _showSnackBar(S.of(context).t('takeaway_copy_empty'));
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    _showSnackBar(S.of(context).t('takeaway_copied'));
  }

  String get _exportText {
    if (_takeaways.isEmpty) return '';
    return _takeaways
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value['content'] ?? ''}')
        .join('\n');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('takeaway_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          IconButton(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      floatingActionButton: !_isAdding && !_isLoading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _isAdding = true),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(S.of(context).t('takeaway_add')),
            )
          : null,
      body: AnimatedSwitcher(
        duration: AppDurations.page,
        switchInCurve: AppDurations.emphasized,
        switchOutCurve: Curves.easeInOut,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SafeArea(
        key: const ValueKey('loading'),
        child: LoadingWidget(fullScreen: true, message: S.of(context).t('takeaway_loading_msg')),
      );
    }

    if (_error != null) {
      return SafeArea(
        key: const ValueKey('error'),
        child: ErrorStateWidget(message: _error!, onRetry: _loadTakeaways),
      );
    }

    return Column(
      key: const ValueKey('content'),
      children: [
        _buildHeroHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTakeaways,
            child: _buildTakeawayContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.warmHero),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bookTitle ?? S.of(context).t('takeaway_current_book'),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          S.of(context).t('takeaway_hero_desc'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      value: '${_takeaways.length}',
                      label: S.of(context).t('takeaway_count_label'),
                      icon: Icons.format_list_bulleted_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _HeroMetric(
                      value:
                          '${_takeaways.where((item) => item['pageNumber'] != null).length}',
                      label: S.of(context).t('takeaway_with_page'),
                      icon: Icons.bookmark_added_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTakeawayContent() {
    if (_takeaways.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          AnimatedSwitcher(
            duration: AppDurations.standard,
            child: _isAdding
                ? _buildAddInput()
                : EmptyStateWidget(
                    title: S.of(context).t('takeaway_empty_title'),
                    message:
                        S.of(context).t('takeaway_empty_msg'),
                    icon: Icons.lightbulb_outline_rounded,
                  ),
          ),
          if (!_isAdding) ...[
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: S.of(context).t('takeaway_add_first'),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => setState(() => _isAdding = true),
            ),
          ],
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      onReorder: _reorderTakeaways,
      itemCount: _takeaways.length,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Transform.scale(
              scale: 1 + (animation.value * 0.02),
              child: Material(color: Colors.transparent, child: child),
            );
          },
        );
      },
      header: _isAdding
          ? Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildAddInput(),
            )
          : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey(_takeaways[index]['id'] ?? 'takeaway_$index'),
          padding: EdgeInsets.only(
            bottom: index == _takeaways.length - 1 ? 0 : AppSpacing.md,
          ),
          child: _buildTakeawayCard(index),
        );
      },
    );
  }

  Widget _buildTakeawayCard(int index) {
    final takeaway = _takeaways[index];
    final pageNumber = takeaway['pageNumber'];

    return ModernCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: index == 0
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: index.isEven
                      ? AppColors.primaryGradient
                      : AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusChip(
                      label: 'Takeaway ${index + 1}',
                      color: AppColors.primary,
                      icon: Icons.auto_awesome_rounded,
                    ),
                    if (pageNumber != null)
                      StatusChip(
                        label: 'Trang $pageNumber',
                        color: AppColors.secondary,
                        icon: Icons.book_outlined,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<_TakeawayAction>(
                onSelected: (action) {
                  if (action == _TakeawayAction.createFlashcard) {
                    _createFlashcard(index);
                  } else {
                    _deleteTakeaway(index);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_TakeawayAction>(
                    value: _TakeawayAction.createFlashcard,
                    child: Text(S.of(context).t('takeaway_create_fc')),
                  ),
                  PopupMenuItem<_TakeawayAction>(
                    value: _TakeawayAction.delete,
                    child: Text(S.of(context).t('takeaway_delete_item')),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${takeaway['content'] ?? ''}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _createFlashcard(index),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.style_rounded, size: 18),
                label: Text(S.of(context).t('takeaway_create_fc')),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteTakeaway(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(S.of(context).t('takeaway_delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddInput() {
    return SectionContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('takeaway_add_new'),
            subtitle:
                S.of(context).t('takeaway_add_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomTextField(
            controller: _newTakeawayController,
            label: S.of(context).t('takeaway_content_label'),
            hint: S.of(context).t('takeaway_content_hint'),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            prefix: const Icon(Icons.edit_note_rounded),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            S.of(context).t('takeaway_tip'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _isAdding = false;
                            _newTakeawayController.clear();
                          });
                        },
                  child: Text(S.of(context).t('takeaway_cancel')),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: S.of(context).t('takeaway_save_item'),
                  loading: _isSaving,
                  onPressed: _addTakeaway,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExportTile(
              icon: Icons.copy_rounded,
              title: S.of(context).t('takeaway_export_copy'),
              subtitle: S.of(context).t('takeaway_export_copy_sub'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                await _copyAllTakeaways();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExportTile(
              icon: Icons.share_rounded,
              title: S.of(context).t('takeaway_export_share'),
              subtitle: S.of(context).t('takeaway_export_share_sub'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showSnackBar(S.of(context).t('takeaway_share_coming'));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExportTile(
              icon: Icons.picture_as_pdf_outlined,
              title: S.of(context).t('takeaway_export_pdf'),
              subtitle: S.of(context).t('takeaway_export_pdf_sub'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showSnackBar(S.of(context).t('takeaway_pdf_coming'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _TakeawayAction { createFlashcard, delete }

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.82),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
