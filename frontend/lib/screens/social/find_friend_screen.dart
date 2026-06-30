/// FindFriendScreen - Tim kiem ban be
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/friend_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/states/empty_state_widget.dart';
import '../../widgets/states/error_state_widget.dart';
import '../../widgets/states/loading_widget.dart';
import '../../l10n/app_localizations.dart';

class FindFriendScreen extends StatefulWidget {
  const FindFriendScreen({super.key});

  @override
  State<FindFriendScreen> createState() => _FindFriendScreenState();
}

class _FindFriendScreenState extends State<FindFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  Timer? _debounce;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _friendService.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${S.of(context).t("friend_search_error")}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      await _friendService.sendFriendRequest(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).t('find_friend_added'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('find_friend_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          ModernCard(
            gradient: AppGradients.warmHero,
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: S.of(context).t('find_friend_hero'),
                  subtitle: S.of(context).t('find_friend_hero_desc'),
                ),
                const SizedBox(height: AppSpacing.xl),
                SearchBarWidget(
                  controller: _searchController,
                  hintText: S.of(context).t('find_friend_hint'),
                  onChanged: _onSearchChanged,
                  trailing:
                      _searchController.text.isEmpty
                          ? null
                          : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return LoadingWidget(
        fullScreen: true,
        message: S.of(context).t('find_friend_loading'),
      );
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: () => _performSearch(_searchController.text.trim()),
      );
    }

    if (_searchController.text.isEmpty) {
      return EmptyStateWidget(
        title: S.of(context).t('find_friend_start'),
        message: S.of(context).t('find_friend_start_msg'),
        icon: Icons.person_search_rounded,
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyStateWidget(
        title: S.of(context).t('find_friend_no_result'),
        message: S.of(context).t('find_friend_no_result_msg'),
        icon: Icons.search_off_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: S.of(context).t('find_friend_results'),
          subtitle: '${_searchResults.length} ${S.of(context).t("find_friend_results_desc")}',
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._searchResults.asMap().entries.map((entry) {
          final user = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == _searchResults.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _UserResultCard(
              user: user,
              onSendRequest: _sendFriendRequest,
            ),
          );
        }),
      ],
    );
  }
}

class _UserResultCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final Future<void> Function(String userId) onSendRequest;

  const _UserResultCard({
    required this.user,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        '${user['fullName'] ?? user['displayName'] ?? user['name'] ?? S.of(context).t("find_friend_user")}';
    final email = '${user['email'] ?? ''}';
    final avatarUrl = user['avatarUrl'] as String?;
    final userId = '${user['id']}';

    return ModernCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primarySoft,
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
            child:
                avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: () => onSendRequest(userId),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: Text(S.of(context).t('find_friend_connect')),
          ),
        ],
      ),
    );
  }
}
