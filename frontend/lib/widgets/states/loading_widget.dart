library;

import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingWidget({super.key, this.message, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }

    return Padding(padding: const EdgeInsets.all(16), child: content);
  }
}
