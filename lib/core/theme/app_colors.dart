import 'package:flutter/material.dart';

class AppColors {
  // Jewel-Tone Palette from Master Design Blueprint
  static const Color primaryTeal = Color(0xFF0D9488); // Deep Medical Teal
  static const Color primaryTealLight = Color(0xFF14B8A6); // Bright Cyan-Teal
  static const Color accentEmerald = Color(0xFF10B981); // Emerald Mint (Active/Taken)
  static const Color accentCyan = Color(0xFF06B6D4); // Electric Cyan
  static const Color accentPurple = Color(0xFF8B5CF6); // Royal Amethyst
  static const Color accentAmber = Color(0xFFF59E0B); // Radiant Amber Flame
  static const Color accentRose = Color(0xFFF43F5E); // Crimson Coral (Alerts/Overdue)
  static const Color accentBlue = Color(0xFF3B82F6); // Electric Blue

  // Core Brand Colors (Teal Dominant)
  static const Color primary = Color(0xFF0D9488); // Master Primary Teal
  static const Color primaryDark = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFFCCFBF1); // Soft Teal Mist
  static const Color primaryContainer = Color(0xFFF0FDFA); // Clean Teal Tint

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber Flame
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFF43F5E); // Crimson Rose
  static const Color errorLight = Color(0xFFFFE4E6);

  static const Color secondary = Color(0xFF10B981);
  static const Color accentMint = Color(0xFF10B981);
  static const Color brandMint = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFFD1FAE5);
  static const Color secondaryContainer = Color(0xFFECFDF5);

  static const Color tertiary = Color(0xFF06B6D4);
  static const Color tertiaryLight = Color(0xFFCFFAFE);
  static const Color info = Color(0xFF0D9488);
  static const Color infoLight = Color(0xFFF0FDFA);

  // Alarm Screen Colors
  static const Color alarmBackground = Color(0xFF080D1A);
  static const Color alarmSurface = Color(0xFF151F32);
  static const Color alarmGlow = Color(0xFF0D9488);

  // Light Mode (Crisp Porcelain & Soft Slate)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
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

  // Dark Mode (Deep Obsidian #090D16, Glass Card #131D33, Elevated #1A2640)
  static const Color darkBackground = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF131D33);
  static const Color darkCard = Color(0xFF131D33);
  static const Color darkCardElevated = Color(0xFF1A2640);
  static const Color darkBorder = Color(0xFF23314E);
  static const Color darkPrimary = Color(0xFF14B8A6);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkSuccess = Color(0xFF10B981);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkError = Color(0xFFF43F5E);

  // Glossy Glassmorphic Sheen Gradients
  static const LinearGradient glossySheenDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x18FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  static const LinearGradient glossySheenLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x66FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  static const LinearGradient glassBorderDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x2EFFFFFF),
      Color(0x0AFFFFFF),
    ],
  );

  static const LinearGradient glassBorderLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFE2E8F0),
    ],
  );

  // Rich Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Multi-layered Luxury Atmospheric Shadows
  static List<BoxShadow> glossyCardShadow(bool isDark, {Color? glowColor}) {
    if (isDark) {
      return [
        BoxShadow(
          color: (glowColor ?? Colors.black).withValues(alpha: glowColor != null ? 0.22 : 0.45),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: (glowColor ?? const Color(0xFF0F172A)).withValues(alpha: glowColor != null ? 0.12 : 0.05),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // Ambient Glow BoxShadow Helper
  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.28, double blurRadius = 18, Offset offset = const Offset(0, 6)}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }

  // Curated Distinguishable Pill Tag Colors
  static const List<Color> pillColors = [
    Color(0xFF0D9488), // Medical Teal
    Color(0xFF10B981), // Emerald Mint
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFF8B5CF6), // Royal Violet
    Color(0xFF06B6D4), // Electric Cyan
    Color(0xFFF43F5E), // Crimson Rose
    Color(0xFF3B82F6), // Ocean Blue
    Color(0xFFEC4899), // Hot Pink
  ];

  // Dual-Tone Capsule Colors matching the Reference UI
  static const List<List<Color>> dualCapsuleColors = [
    [Color(0xFFF43F5E), Color(0xFF06B6D4)], // Crimson & Cyan
    [Color(0xFFF59E0B), Color(0xFFFEF08A)], // Amber & Soft Yellow
    [Color(0xFF0D9488), Color(0xFFCCFBF1)], // Teal & Ice
    [Color(0xFF10B981), Color(0xFF67E8F9)], // Mint & Sky
    [Color(0xFF3B82F6), Color(0xFF93C5FD)], // Blue & Soft Blue
    [Color(0xFF8B5CF6), Color(0xFFF472B6)], // Violet & Rose
  ];

  static Color getPillColor(int index) {
    return pillColors[index % pillColors.length];
  }

  static List<Color> getDualCapsuleColor(int index) {
    return dualCapsuleColors[index % dualCapsuleColors.length];
  }
}
