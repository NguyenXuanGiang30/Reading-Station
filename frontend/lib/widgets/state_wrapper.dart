/// State wrapper widget for handling loading, error, empty, and content states
library;

import 'package:flutter/material.dart';
import 'app_loading.dart';
import 'app_error.dart';
import 'app_empty.dart';

/// Enum for content states
enum ContentState {
  loading,
  loaded,
  empty,
  error,
}

/// A widget that wraps content with common states: loading, error, empty, and loaded
class StateWrapper<T> extends StatelessWidget {
  /// Current state of the content
  final ContentState state;
  
  /// Data when state is loaded
  final T? data;
  
  /// Error message when state is error
  final String? errorMessage;
  
  /// Empty state title
  final String emptyTitle;
  
  /// Empty state message  
  final String emptyMessage;
  
  /// Empty state icon
  final IconData emptyIcon;
  
  /// Loading message
  final String? loadingMessage;
  
  /// Callback when retry is pressed (for error state)
  final VoidCallback? onRetry;
  
  /// Callback when action button is pressed (for empty state)
  final VoidCallback? onEmptyAction;
  
  /// Label for empty state action button
  final String? emptyActionLabel;
  
  /// The actual content widget
  final Widget Function(T data) contentBuilder;
  
  /// Custom error widget builder
  final Widget Function(String message, VoidCallback? onRetry)? errorBuilder;
  
  /// Custom empty widget builder
  final Widget Function()? emptyBuilder;
  
  /// Custom loading widget builder
  final Widget Function(String? message)? loadingBuilder;
  
  const StateWrapper({
    super.key,
    required this.state,
    required this.contentBuilder,
    this.data,
    this.errorMessage,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptyMessage = 'Hiện chưa có nội dung để hiển thị',
    this.emptyIcon = Icons.inbox_outlined,
    this.loadingMessage,
    this.onRetry,
    this.onEmptyAction,
    this.emptyActionLabel,
    this.errorBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ContentState.loading:
        if (loadingBuilder != null) {
          return loadingBuilder!(loadingMessage);
        }
        return AppLoading(
          message: loadingMessage,
          fullScreen: true,
        );
      
      case ContentState.error:
        if (errorBuilder != null) {
          return errorBuilder!(errorMessage ?? 'Đã xảy ra lỗi', onRetry);
        }
        return AppError(
          message: errorMessage ?? 'Đã xảy ra lỗi',
          onRetry: onRetry,
        );
      
      case ContentState.empty:
        if (emptyBuilder != null) {
          return emptyBuilder!();
        }
        return AppEmpty(
          title: emptyTitle,
          message: emptyMessage,
          icon: emptyIcon,
          onAction: onEmptyAction,
          actionLabel: emptyActionLabel,
        );
      
      case ContentState.loaded:
        if (data == null) {
          return const AppEmpty(
            title: 'Chưa có dữ liệu',
            message: 'Nguồn dữ liệu hiện đang trống',
          );
        }
        return contentBuilder(data as T);
    }
  }
}
