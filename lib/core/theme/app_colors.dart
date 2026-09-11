import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (KinCare Material 3 Expressive - Orange & Light Green)
  static const Color primary = Color(0xFFFF6B35); // Vibrant Warm Orange
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryLight = Color(0xFFFFEDD5);
  static const Color primaryContainer = Color(0xFFFFF7ED);

  static const Color secondary = Color(0xFF10B981); // Refreshing Light Mint Green
  static const Color secondaryDark = Color(0xFF047857);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryContainer = Color(0xFFECFDF5);

  static const Color tertiary = Color(0xFF059669); // Emerald Light Green
  static const Color tertiaryLight = Color(0xFFA7F3D0);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Mint Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF97316); // Warm Amber Orange
  static const Color warningLight = Color(0xFFFFEDD5);
  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7); // Cerulean
  static const Color infoLight = Color(0xFFE0F2FE);

  // Light Mode (Clean Sunlit Paper & Soft Mint Accents)
  static const Color lightBackground = Color(0xFFFCFBF7);
  static const Color lightSurface = Color(0xFFF7F5EE);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF3ECE1);
  static const Color lightBorder = Color(0xFFE6F4EA);
  static const Color lightTextPrimary = Color(0xFF1A1E1C);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Dark Mode (Deep OLED Obsidian & Muted Warmth)
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF141A28);
  static const Color darkCard = Color(0xFF1B2234);
  static const Color darkCardElevated = Color(0xFF232C42);
  static const Color darkBorder = Color(0xFF2C3752);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Curated 3D Pill Palette
  static const List<Color> pillColors = [
    Color(0xFFFF6B35), // Warm Orange
    Color(0xFF10B981), // Mint Light Green
    Color(0xFFF97316), // Tangerine
    Color(0xFF059669), // Emerald
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF7C3AED), // Royal Violet
    Color(0xFFEC4899), // Rose Pink
    Color(0xFF84CC16), // Lime Green
    Color(0xFF4F46E5), // Indigo
    Color(0xFFD97706), // Honey Gold
  ];

  static Color getPillColor(int index) {
    return pillColors[index % pillColors.length];
  }
}
