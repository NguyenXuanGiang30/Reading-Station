import 'package:flutter/material.dart';

import 'states/error_state_widget.dart';

class AppError extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppError({
    super.key,
    required this.message,
    this.title = 'Đã xảy ra lỗi',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: title ?? 'Đã xảy ra lỗi',
      message: message,
      onRetry: onRetry,
    );
  }
}
