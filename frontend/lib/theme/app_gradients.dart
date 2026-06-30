library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  static const LinearGradient warmHero = LinearGradient(
    colors: [Color(0xFFFFEEE5), Color(0xFFFFD8CC), Color(0xFFFFB8A2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunriseAccent = LinearGradient(
    colors: [Color(0xFFFFC671), AppColors.accent, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGlassOverlay = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x66FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient editorialSurface = LinearGradient(
    colors: [AppColors.surface, AppColors.surfaceAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
