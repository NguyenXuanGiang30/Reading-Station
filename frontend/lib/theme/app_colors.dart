library;

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE86F5C);
  static const Color primaryStrong = Color(0xFFD55640);
  static const Color primarySoft = Color(0xFFFFE0DB);

  static const Color secondary = Color(0xFF2F8F83);
  static const Color secondarySoft = Color(0xFFDDF6F0);

  static const Color accent = Color(0xFFF4B860);
  static const Color accentSoft = Color(0xFFFFEED5);

  static const Color background = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFF8F3);
  static const Color surfaceMuted = Color(0xFFF2ECE5);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA3AF);

  static const Color border = Color(0xFFE7E2DA);
  static const Color divider = Color(0xFFF0EAE1);

  static const Color success = Color(0xFF1E9E6A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);

  static const Color darkBackground = Color(0xFF151A22);
  static const Color darkSurface = Color(0xFF1D2430);
  static const Color darkSurfaceAlt = Color(0xFF242C39);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFB8C0CC);
  static const Color darkBorder = Color(0xFF334155);

  static final Color shadowSoft = const Color(
    0xFF5A3E33,
  ).withValues(alpha: 0.08);
  static final Color shadowElevated = const Color(
    0xFF5A3E33,
  ).withValues(alpha: 0.14);

  // Compatibility aliases for existing screens.
  static const Color primaryStart = primary;
  static const Color primaryEnd = primaryStrong;
  static const Color primaryDark = primaryStrong;
  static const Color accentLight = accentSoft;
  static const Color accentDark = accent;
  static const Color backgroundLight = background;
  static const Color backgroundDark = darkBackground;
  static const Color surfaceLight = surface;
  static const Color surfaceDark = darkSurface;
  static const Color cardLight = surface;
  static const Color cardDark = darkSurfaceAlt;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textPrimaryDark = darkTextPrimary;
  static const Color textSecondaryDark = darkTextSecondary;
  static const Color secondaryDark = surfaceMuted;
  static const Color wantToRead = info;
  static const Color reading = primary;
  static const Color completed = success;
  static const Color forgot = error;
  static const Color remembered = accent;
  static const Color mastered = success;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8A72), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [surfaceAlt, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFD899), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF46C792), success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFC0A8), primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<LinearGradient> deckGradients = [
    LinearGradient(
      colors: [Color(0xFFFFA08A), Color(0xFFE86F5C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF6CD4C7), Color(0xFF2F8F83)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFFD56B), Color(0xFFF4B860)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF70A7FF), Color(0xFF3B82F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF9BD37B), Color(0xFF1E9E6A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];
}
