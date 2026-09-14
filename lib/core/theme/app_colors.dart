import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Modern Digital Health - Medical Blue & Fresh Mint)
  static const Color primary = Color(0xFF2563EB); // Fresh Medical Blue
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Royal Blue
  static const Color primaryLight = Color(0xFFDBEAFE); // Soft Blue Tint
  static const Color primaryContainer = Color(0xFFEFF6FF); // Clean Blue Container

  static const Color secondary = Color(0xFF10B981); // Vibrant Mint Green
  static const Color accentMint = Color(0xFF10B981); // Vibrant Mint Green Alias
  static const Color brandMint = Color(0xFF10B981); // Brand Mint
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryContainer = Color(0xFFECFDF5);

  static const Color tertiary = Color(0xFF06B6D4); // Cyan Accent
  static const Color tertiaryLight = Color(0xFFCFFAFE);

  // Status Colors
  static const Color success = Color(0xFF10B981); // Mint Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber Gold
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB); // Royal Blue
  static const Color infoLight = Color(0xFFEFF6FF);

  // Alarm Screen Colors
  static const Color alarmBackground = Color(0xFF0B132B); // Midnight Navy
  static const Color alarmSurface = Color(0xFF1C2541); // Elevated Deep Navy
  static const Color alarmGlow = Color(0xFF3B82F6); // Blue Glow

  // Light Mode (Clean Fresh Slate-Tinted Surface & High Contrast Text)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark Mode (Deep Slate & High Legibility)
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF111D3E);
  static const Color darkCard = Color(0xFF16234B);
  static const Color darkCardElevated = Color(0xFF1C2C5E);
  static const Color darkBorder = Color(0xFF22346B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Curated 3D Pill Palette
  static const List<Color> pillColors = [
    Color(0xFF2563EB), // Medical Blue
    Color(0xFF10B981), // Mint Green
    Color(0xFFEF4444), // Crimson Red
    Color(0xFFF59E0B), // Honey Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  // Dual-Tone Capsule Colors matching the Reference UI
  static const List<List<Color>> dualCapsuleColors = [
    [Color(0xFFEF4444), Color(0xFF06B6D4)], // Paracetamol: Red & Cyan
    [Color(0xFFF59E0B), Color(0xFFFEF08A)], // Vitamin D3: Yellow & Light Yellow
    [Color(0xFFEF4444), Color(0xFFFFFFFF)], // Amoxicillin: Red & White
    [Color(0xFF10B981), Color(0xFF67E8F9)], // Calcium: Mint & Sky Blue
    [Color(0xFF2563EB), Color(0xFF93C5FD)], // Blue & Ice Blue
    [Color(0xFF8B5CF6), Color(0xFFF472B6)], // Violet & Rose
  ];

  static Color getPillColor(int index) {
    return pillColors[index % pillColors.length];
  }

  static List<Color> getDualCapsuleColor(int index) {
    return dualCapsuleColors[index % dualCapsuleColors.length];
  }
}
