library;

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'animated_button.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ] else if (icon != null) ...[
            icon!,
            const SizedBox(width: AppSpacing.md),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );

    return AnimatedButton(
      onPressed: loading ? null : onPressed,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
