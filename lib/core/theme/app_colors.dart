import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Medical Blue)
  static const Color primary = Color(0xFF2563EB); // Primary Action Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Royal Blue (pressed/strong)
  static const Color primaryLight = Color(0xFFDBEAFE); // Soft Blue Tint
  static const Color primaryContainer = Color(0xFFEFF6FF); // Clean Blue Container

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Success Green (taken/active/healthy)
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Warning Amber (low stock/refill/streak)
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Error Red (missed/errors/destructive)
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color secondary = Color(0xFF10B981); // Vibrant Mint Green Alias
  static const Color accentMint = Color(0xFF10B981);
  static const Color brandMint = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryContainer = Color(0xFFECFDF5);

  static const Color tertiary = Color(0xFF06B6D4); // Cyan Accent
  static const Color tertiaryLight = Color(0xFFCFFAFE);
  static const Color info = Color(0xFF2563EB); // Action Blue
  static const Color infoLight = Color(0xFFEFF6FF);

  // Alarm Screen Colors
  static const Color alarmBackground = Color(0xFF0B132B); // Midnight Navy
  static const Color alarmSurface = Color(0xFF1C2541); // Elevated Deep Navy
  static const Color alarmGlow = Color(0xFF3B82F6); // Blue Glow

  // Light Mode (Clean Slate & High Contrast Text)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightDisabled = Color(0xFFCBD5E1);

  // Common aliases for light mode defaults
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color card = lightCard;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textMuted = lightTextMuted;

  // Dark Mode (#0F172A Background, #1E293B Surface, #60A5FA Primary)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardElevated = Color(0xFF27354A);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkError = Color(0xFFF87171);

  // Curated 8 Muted Distinguishable Pill Tag Colors
  static const List<Color> pillColors = [
    Color(0xFF2563EB), // Medical Blue
    Color(0xFF10B981), // Mint Green
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFF8B5CF6), // Soft Violet
    Color(0xFF06B6D4), // Muted Cyan
    Color(0xFFEC4899), // Soft Rose
    Color(0xFF14B8A6), // Deep Teal
    Color(0xFF64748B), // Neutral Slate
  ];

  // Dual-Tone Capsule Colors matching the Reference UI
  static const List<List<Color>> dualCapsuleColors = [
    [Color(0xFFEF4444), Color(0xFF06B6D4)], // Red & Cyan
    [Color(0xFFF59E0B), Color(0xFFFEF08A)], // Amber & Soft Yellow
    [Color(0xFFEF4444), Color(0xFFFFFFFF)], // Red & White
    [Color(0xFF10B981), Color(0xFF67E8F9)], // Mint & Sky
    [Color(0xFF2563EB), Color(0xFF93C5FD)], // Blue & Soft Blue
    [Color(0xFF8B5CF6), Color(0xFFF472B6)], // Violet & Rose
  ];

  static Color getPillColor(int index) {
    return pillColors[index % pillColors.length];
  }

  static List<Color> getDualCapsuleColor(int index) {
    return dualCapsuleColors[index % dualCapsuleColors.length];
  }
}
