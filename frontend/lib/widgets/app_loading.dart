import 'package:flutter/material.dart';

import 'states/loading_widget.dart';

class AppLoading extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const AppLoading({super.key, this.message, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(message: message, fullScreen: fullScreen);
  }
}
