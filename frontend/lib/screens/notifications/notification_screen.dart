/// NotificationScreen - Trung tâm thông báo
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/activity_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ActivityService _activityService = ActivityService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _activityService.getFeed(page: 0, size: 30);
      final content = response['content'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _items = content.map((e) => e as Map<String, dynamic>).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
            title: S.of(context).t('notification_title'),
              subtitle: S.of(context).t('notif_subtitle'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingWidget(
        fullScreen: true,
        message: S.of(context).t('notif_loading'),
      );
    }
    if (_error != null) {
      return ErrorStateWidget(message: _error!, onRetry: _loadNotifications);
    }
    if (_items.isEmpty) {
      return EmptyStateWidget(
            title: S.of(context).t('notif_empty'),
        message: S.of(context).t('notif_empty_desc'),
        icon: Icons.notifications_off_outlined,
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = _items[index];
        final type =
            (item['activityType'] ?? item['type'] ?? item['action'] ?? '')
                .toString();
        final title = item['userName'] ?? item['user'] ?? S.of(context).t('notif_user_default');
        final detail =
            item['bookTitle'] ?? item['achievement'] ?? S.of(context).t('notif_new_activity');
        final icon = _iconForType(type);
        final color = _colorForType(type);

        return ModernCard(
          onTap: () {
            final bookId = item['bookId']?.toString();
            if (bookId != null && bookId.isNotEmpty) {
              context.push('/book/$bookId');
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _messageForType(context, type, detail.toString()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'review':
        return Icons.auto_awesome_rounded;
      case 'achievement':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'review':
        return AppColors.primary;
      case 'achievement':
        return AppColors.accent;
      default:
        return AppColors.info;
    }
  }

  String _messageForType(BuildContext context, String type, String detail) {
    switch (type.toLowerCase()) {
      case 'completed':
        return '${S.of(context).t("notif_completed")} $detail';
      case 'review':
        return '${S.of(context).t("notif_reviewed")} $detail';
      case 'achievement':
        return '${S.of(context).t("notif_achievement")}: $detail';
      default:
        return detail;
    }
  }
}
