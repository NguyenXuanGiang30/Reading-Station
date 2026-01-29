/// Trạm Đọc - Soft Pink Minimalist Color Palette
/// Modern, minimal, premium design with pastel pink tones
library;

import 'package:flutter/material.dart';

class AppColors {
  // Primary Pink Colors (Soft, Pastel)
  static const Color primaryStart = Color(0xFFF8A5B6); // Soft pink
  static const Color primaryEnd = Color(0xFFE8758A);   // Deeper pink
  static const Color primaryDark = Color(0xFFD65D75);  // CTA darker pink
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFDF2F4);   // Very light pink/white
  static const Color secondaryDark = Color(0xFFF9E0E5); // Light pink
  
  // Accent (Darker pink for highlights and CTAs)
  static const Color accent = Color(0xFFE8758A);
  static const Color accentLight = Color(0xFFFAB8C4);
  static const Color accentDark = Color(0xFFCE4A66);   // Strong CTA
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFBFC); // Almost white with pink tint
  static const Color backgroundDark = Color(0xFF1F1A1B);  // Dark with warm undertone
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2A2426);
  
  // Card Colors (Soft shadows)
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF352F31);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF2D2327);  // Dark warm gray
  static const Color textSecondaryLight = Color(0xFF8E7E83); // Muted pink-gray
  static const Color textPrimaryDark = Color(0xFFF9F4F5);
  static const Color textSecondaryDark = Color(0xFFB8A8AB);
  
  // Status Colors (Softened)
  static const Color success = Color(0xFF7AC9A7);  // Soft mint green
  static const Color warning = Color(0xFFE9B872);  // Soft amber
  static const Color error = Color(0xFFE87C8E);    // Soft coral
  static const Color info = Color(0xFF8CB4D9);     // Soft blue
  
  // Reading Status Colors (Pink-harmonized)
  static const Color wantToRead = Color(0xFFB8A5C9);  // Soft lavender
  static const Color reading = Color(0xFFF8A5B6);     // Primary pink
  static const Color completed = Color(0xFF7AC9A7);   // Soft mint
  
  // Flashcard Response Colors
  static const Color forgot = Color(0xFFE87C8E);      // Soft coral
  static const Color remembered = Color(0xFFE9B872); // Soft amber
  static const Color mastered = Color(0xFF7AC9A7);   // Soft mint
  
  // Gradients (Subtle, elegant)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFFDF2F4), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF90D5B8), Color(0xFF7AC9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFAB8C4), Color(0xFFE8758A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Deck Gradients (for flashcard decks) - Pink harmonized
  static const List<LinearGradient> deckGradients = [
    LinearGradient(colors: [Color(0xFFF8A5B6), Color(0xFFE8758A)]), // Pink
    LinearGradient(colors: [Color(0xFF90D5B8), Color(0xFF7AC9A7)]), // Mint
    LinearGradient(colors: [Color(0xFFB8A5C9), Color(0xFF9C88B0)]), // Lavender
    LinearGradient(colors: [Color(0xFF8CB4D9), Color(0xFF6A9CC4)]), // Soft blue
    LinearGradient(colors: [Color(0xFFE9B872), Color(0xFFDBA55C)]), // Amber
    LinearGradient(colors: [Color(0xFFA5D6D9), Color(0xFF88C4C8)]), // Teal
  ];
  
  // Shadow colors
  static Color shadowLight = const Color(0xFFD4C4C8).withValues(alpha: 0.3);
  static Color shadowMedium = const Color(0xFFD4C4C8).withValues(alpha: 0.5);
}
