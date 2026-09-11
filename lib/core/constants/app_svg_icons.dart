import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  // ==================== MEDICINE FORMS ====================

  /// Dual-tone glossy capsule
  static const String capsule = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="capGrad1" x1="12" y1="12" x2="38" y2="38" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FF6B4A" />
      <stop offset="100%" stop-color="#C84B31" />
    </linearGradient>
    <linearGradient id="capGrad2" x1="26" y1="26" x2="52" y2="52" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FFFFFF" />
      <stop offset="100%" stop-color="#E2E8F0" />
    </linearGradient>
  </defs>
  <!-- Capsule Body Left / Top Half -->
  <path d="M16 32 C8 24 16 12 28 16 L34 22 L22 34 L16 32 Z" fill="url(#capGrad1)" />
  <!-- Capsule Body Right / Bottom Half -->
  <path d="M34 22 L46 34 C54 42 46 54 34 50 L28 44 L22 34 L34 22 Z" fill="url(#capGrad2)" />
  <!-- Pill Outer Outline -->
  <rect x="14" y="24" width="36" height="18" rx="9" transform="rotate(-45 32 32)" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" fill="none" />
  <!-- Division line -->
  <line x1="25" y1="25" x2="39" y2="39" stroke="currentColor" stroke-width="2" />
  <!-- Specular Reflection Highlight -->
  <path d="M22 18 C26 15 32 17 35 20" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.8" />
</svg>
''';

  /// Scored circular tablet
  static const String tablet = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="tabGrad" x1="10" y1="10" x2="54" y2="54" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FFFFFF" />
      <stop offset="100%" stop-color="#E2E8F0" />
    </linearGradient>
  </defs>
  <!-- Outer Bevel Rim -->
  <circle cx="32" cy="32" r="24" fill="url(#tabGrad)" stroke="currentColor" stroke-width="2.5" />
  <!-- Inner Rim -->
  <circle cx="32" cy="32" r="18" stroke="currentColor" stroke-width="1.5" stroke-dasharray="3 3" opacity="0.4" />
  <!-- Score line -->
  <line x1="18" y1="32" x2="46" y2="32" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" />
  <!-- Subtle Highlight Arc -->
  <path d="M18 24 C22 16 34 14 42 18" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.9" />
</svg>
''';

  /// Medicine syrup bottle
  static const String syrup = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="syrGrad" x1="16" y1="20" x2="48" y2="56" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#FEF3C7" />
      <stop offset="100%" stop-color="#FDE68A" />
    </linearGradient>
  </defs>
  <!-- Bottle Cap -->
  <rect x="25" y="8" width="14" height="6" rx="2" fill="currentColor" opacity="0.8" />
  <!-- Bottle Neck -->
  <rect x="27" y="14" width="10" height="5" fill="currentColor" opacity="0.4" />
  <!-- Bottle Main Body -->
  <rect x="18" y="19" width="28" height="37" rx="8" fill="url(#syrGrad)" stroke="currentColor" stroke-width="2.5" />
  <!-- Prescription Label -->
  <rect x="22" y="27" width="20" height="18" rx="4" fill="#FFFFFF" stroke="currentColor" stroke-width="1.5" />
  <!-- Medical Cross on Label -->
  <path d="M32 31 V41 M27 36 H37" stroke="#C84B31" stroke-width="2.5" stroke-linecap="round" />
  <!-- Liquid Wave Line -->
  <path d="M20 46 Q26 44 32 46 T44 46" stroke="currentColor" stroke-width="1.5" opacity="0.6" fill="none" />
</svg>
''';

  /// Liquid drops / eye drops
  static const String drops = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="dropGrad" x1="32" y1="10" x2="48" y2="54" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#67E8F9" />
      <stop offset="100%" stop-color="#06B6D4" />
    </linearGradient>
  </defs>
  <!-- Teardrop shape -->
  <path d="M32 10 C32 10 16 32 16 42 C16 51 23 58 32 58 C41 58 48 51 48 42 C48 32 32 10 32 10 Z" fill="url(#dropGrad)" stroke="currentColor" stroke-width="2.5" stroke-linejoin="round" />
  <!-- Drop Highlight Sheen -->
  <path d="M24 38 C23 34 26 26 30 22" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.9" />
</svg>
''';

  /// Metered dose asthma inhaler
  static const String inhaler = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Canister top -->
  <rect x="23" y="8" width="18" height="12" rx="3" fill="currentColor" opacity="0.3" stroke="currentColor" stroke-width="2" />
  <!-- Inhaler Body -->
  <path d="M20 18 H44 V38 C44 44 40 48 34 48 H24 C20 48 16 44 16 40 V22 C16 20 18 18 20 18 Z" fill="#E2E8F0" stroke="currentColor" stroke-width="2.5" />
  <!-- Mouthpiece Extrusion -->
  <path d="M16 36 H8 C6 36 4 38 4 40 V48 C4 50 6 52 8 52 H26 C30 52 34 48 34 44" fill="#CBD5E1" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
  <!-- Aerosol Mist Cloud -->
  <path d="M48 24 Q54 20 58 24 Q62 28 56 32 Q62 36 56 40" stroke="#06B6D4" stroke-width="2" stroke-linecap="round" fill="none" stroke-dasharray="2 3" />
</svg>
''';

  /// Syringe / Injection
  static const String injection = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Needle -->
  <line x1="10" y1="54" x2="22" y2="42" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" />
  <!-- Syringe Barrel -->
  <rect x="20" y="16" width="14" height="28" rx="2" transform="rotate(-45 27 30)" fill="#F1F5F9" stroke="currentColor" stroke-width="2.5" />
  <!-- Plunger Stem & Flange -->
  <line x1="38" y1="26" x2="52" y2="12" stroke="currentColor" stroke-width="3" stroke-linecap="round" />
  <line x1="47" y1="7" x2="57" y2="17" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" />
  <!-- Measurement ticks -->
  <line x1="28" y1="31" x2="32" y2="27" stroke="#C84B31" stroke-width="2" />
  <line x1="32" y1="35" x2="36" y2="31" stroke="#C84B31" stroke-width="2" />
</svg>
''';

  /// Ointment / Topical tube
  static const String ointment = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Crimp end -->
  <line x1="14" y1="48" x2="22" y2="56" stroke="currentColor" stroke-width="4" stroke-linecap="round" />
  <!-- Tube body -->
  <path d="M18 52 L36 34 L46 44 L28 62 Z" fill="#E2E8F0" stroke="currentColor" stroke-width="2" />
  <!-- Shoulder & Nozzle -->
  <path d="M36 34 L44 26 L52 34 L46 44 Z" fill="#CBD5E1" stroke="currentColor" stroke-width="2" />
  <!-- Screw Cap -->
  <rect x="46" y="18" width="8" height="12" rx="2" transform="rotate(45 50 24)" fill="currentColor" opacity="0.8" />
</svg>
''';

  /// Herbal Supplement / Vitamins
  static const String supplement = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Botanical Leaf 1 -->
  <path d="M32 48 C32 48 18 36 20 22 C22 8 36 10 42 16 C48 22 46 36 32 48 Z" fill="#D1FAE5" stroke="#10B981" stroke-width="2.5" />
  <!-- Leaf Vein -->
  <path d="M24 20 Q30 30 32 48" stroke="#059669" stroke-width="2" stroke-linecap="round" />
  <!-- Secondary Leaf -->
  <path d="M32 48 C36 40 48 34 50 24 C52 14 42 12 36 16" stroke="#10B981" stroke-width="2" stroke-linecap="round" fill="none" />
</svg>
''';

  // ==================== FOOD INTAKE TIMING ====================

  /// After meal / food icon
  static const String afterMeal = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 24 L24 10 L40 24" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="10" y="24" width="28" height="14" rx="4" fill="currentColor" fill-opacity="0.15" stroke="currentColor" stroke-width="2.5"/>
  <circle cx="24" cy="31" r="3" fill="#10B981"/>
  <!-- Checkmark -->
  <path d="M34 12 L38 16 L46 8" stroke="#10B981" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  /// Before meal / hourglass
  static const String beforeMeal = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 8 H34 M14 40 H34" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>
  <path d="M16 8 C16 20 32 20 32 8" stroke="currentColor" stroke-width="2.5"/>
  <path d="M16 40 C16 28 32 28 32 40" stroke="currentColor" stroke-width="2.5" fill="currentColor" fill-opacity="0.2"/>
  <circle cx="24" cy="24" r="2" fill="#D97706"/>
</svg>
''';

  /// Empty stomach / glass of water
  static const String emptyStomach = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M14 10 L18 38 C18 41 21 43 24 43 C27 43 30 41 30 38 L34 10 H14 Z" stroke="currentColor" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M17 26 Q24 24 31 26" stroke="#06B6D4" stroke-width="2" stroke-linecap="round"/>
  <!-- Bubble -->
  <circle cx="24" cy="32" r="2" fill="#06B6D4"/>
</svg>
''';

  /// With healthy fats / meal
  static const String withMeal = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="24" cy="24" r="16" stroke="currentColor" stroke-width="2.5" fill="currentColor" fill-opacity="0.1"/>
  <circle cx="24" cy="24" r="9" stroke="currentColor" stroke-width="1.5" stroke-dasharray="2 2"/>
  <line x1="8" y1="24" x2="11" y2="24" stroke="currentColor" stroke-width="2.5"/>
  <line x1="37" y1="24" x2="40" y2="24" stroke="currentColor" stroke-width="2.5"/>
</svg>
''';

  /// Bedtime / night
  static const String bedtime = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M34 26 C34 33.7 27.7 40 20 40 C15.4 40 11.4 37.8 8.8 34.4 C9.8 34.8 10.9 35 12 35 C19.7 35 26 28.7 26 21 C26 16.5 23.8 12.5 20.4 9.8 C28.2 10.8 34 17.7 34 26 Z" fill="#6366F1" fill-opacity="0.2" stroke="#6366F1" stroke-width="2.5" stroke-linejoin="round"/>
  <circle cx="36" cy="14" r="1.5" fill="#F59E0B"/>
  <circle cx="42" cy="22" r="1" fill="#F59E0B"/>
</svg>
''';

  // ==================== FAMILY PROFILE AVATARS ====================

  /// User / Myself avatar
  static const String avatarMyself = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="#CCFBF1" stroke="#0D9488" stroke-width="2"/>
  <circle cx="32" cy="24" r="10" fill="#0D9488"/>
  <path d="M16 48 C16 40 22 36 32 36 C42 36 48 40 48 48" fill="#0F766E"/>
</svg>
''';

  /// Dad avatar
  static const String avatarDad = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
  <circle cx="32" cy="24" r="10" fill="#D97706"/>
  <!-- Glasses -->
  <circle cx="28" cy="24" r="4" stroke="#78350F" stroke-width="1.5" fill="none"/>
  <circle cx="36" cy="24" r="4" stroke="#78350F" stroke-width="1.5" fill="none"/>
  <line x1="32" y1="24" x2="32" y2="24" stroke="#78350F" stroke-width="2"/>
  <path d="M16 48 C16 40 22 36 32 36 C42 36 48 40 48 48" fill="#B45309"/>
</svg>
''';

  /// Mom avatar
  static const String avatarMom = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="#FCE7F3" stroke="#DB2777" stroke-width="2"/>
  <circle cx="32" cy="24" r="10" fill="#EC4899"/>
  <!-- Gentle hairdo arc -->
  <path d="M20 22 C20 14 44 14 44 22" stroke="#BE185D" stroke-width="3" stroke-linecap="round" fill="none"/>
  <path d="M16 48 C16 40 22 36 32 36 C42 36 48 40 48 48" fill="#DB2777"/>
</svg>
''';

  /// Child avatar
  static const String avatarChild = '''
<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="#E0F2FE" stroke="#0284C7" stroke-width="2"/>
  <circle cx="32" cy="26" r="8" fill="#0284C7"/>
  <!-- Friendly curl -->
  <path d="M30 18 Q32 14 36 16" stroke="#0369A1" stroke-width="2.5" stroke-linecap="round" fill="none"/>
  <path d="M20 50 C20 42 24 38 32 38 C40 38 44 42 44 50" fill="#0284C7"/>
</svg>
''';

  // ==================== CELEBRATIONS & STREAKS ====================

  /// Fire streak flame
  static const String fireStreak = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="fireGrad" x1="24" y1="4" x2="24" y2="44" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#F59E0B" />
      <stop offset="100%" stop-color="#DC2626" />
    </linearGradient>
  </defs>
  <!-- Outer Flame -->
  <path d="M24 4 C24 4 10 18 10 30 C10 37.7 16.3 44 24 44 C31.7 44 38 37.7 38 30 C38 18 24 4 24 4 Z" fill="url(#fireGrad)"/>
  <!-- Inner Heart Flame -->
  <path d="M24 20 C24 20 17 28 17 34 C17 37.9 20.1 41 24 41 C27.9 41 31 37.9 31 34 C31 28 24 20 24 20 Z" fill="#FDE047"/>
</svg>
''';

  /// Confetti party celebration
  static const String celebration = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M8 40 L22 26 L12 16 L6 26 Z" fill="#C84B31" stroke="#991B1B" stroke-width="2"/>
  <!-- Streamers & Sparkles -->
  <circle cx="28" cy="14" r="2.5" fill="#F59E0B"/>
  <circle cx="38" cy="20" r="3" fill="#10B981"/>
  <circle cx="34" cy="32" r="2" fill="#3B82F6"/>
  <path d="M20 10 Q28 8 32 16" stroke="#EC4899" stroke-width="2.5" stroke-linecap="round" fill="none"/>
  <path d="M28 26 Q36 28 42 22" stroke="#8B5CF6" stroke-width="2.5" stroke-linecap="round" fill="none"/>
</svg>
''';

  // ==================== CONVENIENCE HELPER WIDGET ====================

  /// Helper widget to render any of the SVG strings cleanly with size and tint
  static Widget render(
    String svgString, {
    double width = 24,
    double height = 24,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.string(
      svgString,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}
