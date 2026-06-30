library;

import 'package:flutter/material.dart';

import '../../theme/app_durations.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const AnimatedButton({super.key, required this.child, this.onPressed});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double _scale = 1;

  void _setScale(double value) {
    if (mounted) {
      setState(() => _scale = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.98),
      onTapCancel: () => _setScale(1),
      onTapUp: (_) => _setScale(1),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.micro,
        curve: AppDurations.emphasized,
        child: widget.child,
      ),
    );
  }
}
