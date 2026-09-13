import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Modern Digital Health - Royal Teal & Fresh Mint)
  static const Color primary = Color(0xFF0D9488); // Royal Teal
  static const Color primaryDark = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFFCCFBF1); // Soft Teal Tint
  static const Color primaryContainer = Color(0xFFE6FFFA); // Soft Clean Teal Container

  static const Color secondary = Color(0xFF10B981); // Refreshing Light Mint Green
  static const Color secondaryDark = Color(0xFF047857);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryContainer = Color(0xFFECFDF5);

  static const Color tertiary = Color(0xFF06B6D4); // Cyan Accent
  static const Color tertiaryLight = Color(0xFFCFFAFE);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Mint Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber Gold
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7); // Cerulean
  static const Color infoLight = Color(0xFFE0F2FE);

  // Light Mode (Clean Fresh Teal-Tinted Surface & High Contrast Text)
  static const Color lightBackground = Color(0xFFF0FDFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFE6FFFA);
  static const Color lightBorder = Color(0xFFCCFBF1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark Mode (Deep OLED Teal Obsidian & High Legibility)
  static const Color darkBackground = Color(0xFF061A19);
  static const Color darkSurface = Color(0xFF0B2423);
  static const Color darkCard = Color(0xFF102E2D);
  static const Color darkCardElevated = Color(0xFF173D3B);
  static const Color darkBorder = Color(0xFF22514D);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Curated 3D Pill Palette
  static const List<Color> pillColors = [
    Color(0xFF0D9488), // Royal Teal
    Color(0xFF10B981), // Mint Light Green
    Color(0xFF06B6D4), // Cyan
    Color(0xFF059669), // Emerald
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF7C3AED), // Royal Violet
    Color(0xFFEC4899), // Rose Pink
    Color(0xFF84CC16), // Lime Green
    Color(0xFF4F46E5), // Indigo
    Color(0xFFF59E0B), // Honey Amber
  ];

  static Color getPillColor(int index) {
    return pillColors[index % pillColors.length];
  }
}
