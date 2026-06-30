/// AI Chat Screen - Chat with local AI assistant + Agent actions
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/ai/ai_chat_bloc.dart';
import '../../blocs/ai/ai_chat_event.dart';
import '../../blocs/ai/ai_chat_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiChatBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AiChatBloc()..add(const CheckAiHealth());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _bloc.add(SendMessage(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF48BFE3)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('ai_title'), style: Theme.of(context).textTheme.titleMedium),
                    BlocBuilder<AiChatBloc, AiChatState>(
                      builder: (context, state) {
                        return Text(
                          state.isAiAvailable ? s.t('ai_online') : s.t('ai_offline'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: state.isAiAvailable
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _bloc.add(const ClearChat()),
              tooltip: s.t('ai_clear'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Offline banner
            BlocBuilder<AiChatBloc, AiChatState>(
              buildWhen: (prev, curr) =>
                  prev.isAiAvailable != curr.isAiAvailable,
              builder: (context, state) {
                if (state.isAiAvailable) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  color: AppColors.warning.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          s.t('ai_offline_msg'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Messages
            Expanded(
              child: BlocConsumer<AiChatBloc, AiChatState>(
                listener: (context, state) {
                  if (state is AiChatLoaded || state is AiChatError) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return _buildWelcome(context);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
                    ),
                    itemCount: state.messages.length +
                        (state is AiChatLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.messages.length) {
                        return _buildTypingIndicator(context);
                      }
                      final msg = state.messages[index];
                      return Column(
                        children: [
                          _buildMessageBubble(context, msg),
                          if (msg.actions != null)
                            ...msg.actions!.map((a) => _buildActionCard(context, a)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Quick suggestions
            BlocBuilder<AiChatBloc, AiChatState>(
              builder: (context, state) {
                if (state.messages.isNotEmpty) return const SizedBox.shrink();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      _buildSuggestionChip(s.t('ai_suggest_stats')),
                      const SizedBox(width: AppSpacing.sm),
                      _buildSuggestionChip(s.t('ai_suggest_recommend')),
                      const SizedBox(width: AppSpacing.sm),
                      _buildSuggestionChip(s.t('ai_suggest_tips')),
                      const SizedBox(width: AppSpacing.sm),
                      _buildSuggestionChip('Tìm sách Clean Code'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Input bar
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48BFE3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              s.t('ai_welcome'),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.t('ai_welcome_msg'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48BFE3)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : null,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.xl),
        ],
      ),
    );
  }

  // ── Action Cards ─────────────────────────────────────────────

  Widget _buildActionCard(BuildContext context, ActionResult action) {
    if (!action.success || action.data == null) {
      return _buildErrorActionCard(context, action);
    }

    return switch (action.tool) {
      'search_book_isbn' => _buildBookCard(context, action.data!),
      'search_book_name' => _buildBookListCard(context, action.data!),
      'add_book_to_library' => _buildAddedBookCard(context, action.data!),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> data) {
    final coverUrl = data['coverImageUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 85,
                    color: AppColors.primarySoft,
                    child: coverUrl != null && coverUrl.isNotEmpty
                        ? Image.network(coverUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.menu_book_rounded, color: AppColors.primary))
                        : const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] as String? ?? 'Không có tiêu đề',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['author'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (data['pageCount'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${data['pageCount']} trang',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Add to library button
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _controller.text = 'Thêm sách "${data['title']}" vào thư viện';
                      _sendMessage();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm vào thư viện'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListCard(BuildContext context, Map<String, dynamic> data) {
    final books = data['books'] as List? ?? [];
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
      child: Column(
        children: books.take(3).map((book) {
          final b = book as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildBookCard(context, b),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddedBookCard(BuildContext context, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.success),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Đã thêm vào thư viện!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['title'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/library'),
              child: const Text('Xem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorActionCard(BuildContext context, ActionResult action) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                action.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing Indicator & Input ──────────────────────────────────

  Widget _buildTypingIndicator(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48BFE3)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  s.t('ai_thinking'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _controller.text = label;
        _sendMessage();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: s.t('ai_chat_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          BlocBuilder<AiChatBloc, AiChatState>(
            builder: (context, state) {
              final isLoading = state is AiChatLoading;
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF48BFE3)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: isLoading ? null : _sendMessage,
                  icon: Icon(
                    isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
