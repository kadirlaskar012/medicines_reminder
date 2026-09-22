import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';

/// A unified, responsive visual widget for all medicine types.
/// Displays actual captured photos, or pure, photorealistic 3D rendered assets
/// with transparent backgrounds, crisp details, and natural depth.
class MedicineVisual extends StatelessWidget {
  final MedicineType type;
  final int colorValue;
  final String? photoPath;
  final double size;
  final bool hasGlow;
  final BoxFit fit;

  const MedicineVisual({
    super.key,
    required this.type,
    this.colorValue = 0,
    this.photoPath,
    this.size = 40,
    this.hasGlow = false,
    this.fit = BoxFit.contain,
  });

  /// Convenience factory from a [Medicine] model
  factory MedicineVisual.fromMedicine(
    Medicine medicine, {
    double size = 40,
    bool hasGlow = false,
    BoxFit fit = BoxFit.contain,
  }) {
    return MedicineVisual(
      type: medicine.type,
      colorValue: medicine.colorValue,
      photoPath: medicine.photoPath,
      size: size,
      hasGlow: hasGlow,
      fit: fit,
    );
  }

  /// Safely resolves a color value, handling legacy indexes (0..7) as well as 32-bit ARGB values.
  static Color resolveColor(int colorValue) {
    if (colorValue == 0xFFFFFFFF || colorValue == -1 || colorValue == 0) {
      return Colors.white;
    }
    // Handle legacy indexes 1..7
    if (colorValue > 0 && colorValue < AppColors.pillColors.length) {
      return AppColors.pillColors[colorValue];
    }
    final c = Color(colorValue);
    if ((c.a * 255.0).round() == 0) {
      return Colors.white;
    }
    return c;
  }

  /// Returns signature delicate harmonic gradient pairs tailored per Medicine color and type
  /// for clean, frosted squircle containers.
  static List<Color> getGradients(int colorValue, MedicineType type) {
    if (colorValue != 0 && colorValue != 0xFFFFFFFF && colorValue != -1) {
      final baseColor = resolveColor(colorValue);
      if (baseColor != Colors.white && baseColor != Colors.transparent && baseColor.a > 0.1) {
        final hsl = HSLColor.fromColor(baseColor);
        final lighterHsl = hsl.withLightness((hsl.lightness + 0.14).clamp(0.0, 0.95));
        return [baseColor, lighterHsl.toColor()];
      }
    }

    switch (type) {
      case MedicineType.tablet:
        return const [Color(0xFF0D9488), Color(0xFF14B8A6)]; // Vibrant Emerald Mint
      case MedicineType.capsule:
        return const [Color(0xFF3B82F6), Color(0xFF60A5FA)]; // Vibrant Royal Blue
      case MedicineType.syrup:
        return const [Color(0xFFD97706), Color(0xFFF59E0B)]; // Warm Golden Amber
      case MedicineType.drops:
        return const [Color(0xFF06B6D4), Color(0xFF22D3EE)]; // Cyan Aqua
      case MedicineType.inhaler:
        return const [Color(0xFF0284C7), Color(0xFF38BDF8)]; // Sky Blue
      case MedicineType.injection:
        return const [Color(0xFF6366F1), Color(0xFF818CF8)]; // Radiant Indigo
      case MedicineType.ointment:
        return const [Color(0xFFEA580C), Color(0xFFFB923C)]; // Sunset Coral
      case MedicineType.supplement:
        return const [Color(0xFF10B981), Color(0xFF34D399)]; // Fresh Green
      case MedicineType.other:
        return const [Color(0xFF6366F1), Color(0xFF818CF8)]; // Radiant Indigo
    }
  }

  static final Map<String, bool> _photoExistenceCache = {};

  static bool checkPhotoExists(String path) {
    final cached = _photoExistenceCache[path];
    if (cached != null) return cached;
    try {
      final exists = File(path).existsSync();
      _photoExistenceCache[path] = exists;
      return exists;
    } catch (_) {
      return false;
    }
  }

  static void invalidatePhotoCache(String path) {
    _photoExistenceCache.remove(path);
  }

  @override
  Widget build(BuildContext context) {
    final pixelSize = (size * 2.5).toInt().clamp(48, 300);

    // 1. Photo display takes priority if a valid file exists on disk
    if (photoPath != null && photoPath!.isNotEmpty) {
      if (checkPhotoExists(photoPath!)) {
        final file = File(photoPath!);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: hasGlow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: size * 0.25,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.file(
              file,
              width: size,
              height: size,
              cacheWidth: pixelSize,
              cacheHeight: pixelSize,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    // 2. Pure, photorealistic 3D rendered asset with transparent background & natural depth
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Image.asset(
          type.assetPath,
          width: size,
          height: size,
          cacheWidth: pixelSize,
          cacheHeight: pixelSize,
          fit: fit,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
            type.svgString,
            width: size * 0.85,
            height: size * 0.85,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
