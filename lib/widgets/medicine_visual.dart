import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import 'dual_tone_capsule.dart';

/// A unified, responsive visual widget for all medicine types.
/// Displays actual captured photos, dynamic 3D rendered assets with user-selected color modulation,
/// or custom dual-tone capsules and vector fallbacks.
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
    required this.colorValue,
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
    if (colorValue == 0xFFFFFFFF || colorValue == -1) {
      return Colors.white;
    }
    // Handle legacy indexes 1..7
    if (colorValue > 0 && colorValue < AppColors.pillColors.length) {
      return AppColors.pillColors[colorValue];
    }
    if (colorValue == 0) {
      return Colors.white;
    }
    final c = Color(colorValue);
    if ((c.a * 255.0).round() == 0) {
      return Colors.white;
    }
    return c;
  }

  /// Returns a harmonic 2-color gradient for backgrounds and badge containers
  static List<Color> getGradients(int colorValue, MedicineType type) {
    final primary = resolveColor(colorValue);
    // If medicine color is white or very bright/light,
    // return a sleek cool-slate / silver gradient so badge borders and cards have clear contrast!
    if (primary.computeLuminance() > 0.85) {
      return [
        const Color(0xFF64748B), // Slate 500
        const Color(0xFF94A3B8), // Slate 400
      ];
    }
    final hsl = HSLColor.fromColor(primary);
    final secondary = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 0.95))
        .toColor();
    return [primary, secondary];
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
    final pixelSize = (size * 2).toInt().clamp(40, 200);

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

    final resolvedColor = resolveColor(colorValue);
    final isWhiteOrLight = resolvedColor.computeLuminance() > 0.82;

    // 2. Capsule: Renders 3D DualToneCapsule with vibrant dual-tone gradients or white pearl
    if (type == MedicineType.capsule) {
      if (isWhiteOrLight) {
        return DualToneCapsule(
          size: size,
          primaryColor: Colors.white,
          secondaryColor: const Color(0xFFE2E8F0),
          hasGlow: hasGlow,
        );
      }
      final hsl = HSLColor.fromColor(resolvedColor);
      final secondary = hsl
          .withLightness((hsl.lightness + 0.22).clamp(0.0, 0.95))
          .toColor();
      return DualToneCapsule(
        size: size,
        primaryColor: resolvedColor,
        secondaryColor: secondary,
        hasGlow: hasGlow,
      );
    }

    // 3. Tablet: Renders 3D Tablet with user-chosen color modulation & ambient glow/shadow
    if (type == MedicineType.tablet) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isWhiteOrLight
                  ? Colors.black.withValues(alpha: hasGlow ? 0.28 : 0.14)
                  : resolvedColor.withValues(alpha: hasGlow ? 0.45 : 0.22),
              blurRadius: size * (hasGlow ? 0.35 : 0.18),
              offset: Offset(0, size * 0.04),
              spreadRadius: hasGlow ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: SizedBox(
            width: size,
            height: size,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(resolvedColor, BlendMode.modulate),
              child: Image.asset(
                type.assetPath,
                width: size,
                height: size,
                cacheWidth: pixelSize,
                cacheHeight: pixelSize,
                fit: fit,
                errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
                  type.svgString,
                  width: size * 0.85,
                  height: size * 0.85,
                  color: isWhiteOrLight ? const Color(0xFF64748B) : resolvedColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 4. Other types (Syrup, Drops, Inhaler, Injection, Ointment, Supplement, Other):
    // Renders 3D asset with color modulation, and vector fallback if needed
    final isDropOrSyrup = type == MedicineType.drops || type == MedicineType.syrup;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isWhiteOrLight
                ? Colors.black.withValues(alpha: hasGlow ? 0.25 : 0.12)
                : resolvedColor.withValues(alpha: hasGlow ? 0.40 : 0.18),
            blurRadius: size * (hasGlow ? 0.35 : 0.16),
            offset: Offset(0, size * 0.04),
            spreadRadius: hasGlow ? 1 : 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SizedBox(
          width: size,
          height: size,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              resolvedColor,
              isDropOrSyrup ? BlendMode.color : BlendMode.modulate,
            ),
            child: Image.asset(
              type.assetPath,
              width: size,
              height: size,
              cacheWidth: pixelSize,
              cacheHeight: pixelSize,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
                type.svgString,
                width: size * 0.85,
                height: size * 0.85,
                color: isWhiteOrLight ? const Color(0xFF64748B) : resolvedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
