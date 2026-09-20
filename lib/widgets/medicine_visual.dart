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
    if (colorValue >= 0 && colorValue < AppColors.pillColors.length) {
      return AppColors.pillColors[colorValue];
    }
    // Check if alpha is zero (e.g. from index 0 miscast as Color(0))
    final c = Color(colorValue);
    if ((c.a * 255.0).round() == 0) {
      return AppColors.primary;
    }
    return c;
  }

  /// Returns a harmonic 2-color gradient for backgrounds and badge containers
  static List<Color> getGradients(int colorValue, MedicineType type) {
    final primary = resolveColor(colorValue);
    final hsl = HSLColor.fromColor(primary);
    final secondary = hsl
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 0.95))
        .toColor();
    return [primary, secondary];
  }

  @override
  Widget build(BuildContext context) {
    // 1. Photo display takes priority if a valid file exists on disk
    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
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
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    final resolvedColor = resolveColor(colorValue);

    // 2. Capsule: Renders 3D DualToneCapsule with vibrant dual-tone gradients
    if (type == MedicineType.capsule) {
      if (colorValue >= 0 && colorValue < AppColors.dualCapsuleColors.length) {
        return DualToneCapsule.fromIndex(
          colorValue,
          size: size,
          hasGlow: hasGlow,
        );
      }
      final hsl = HSLColor.fromColor(resolvedColor);
      final secondary = hsl
          .withLightness((hsl.lightness + 0.26).clamp(0.0, 0.95))
          .toColor();
      return DualToneCapsule(
        size: size,
        primaryColor: resolvedColor,
        secondaryColor: secondary,
        hasGlow: hasGlow,
      );
    }

    // 3. Tablet: Renders 3D Tablet with user-chosen color modulation & ambient glow
    if (type == MedicineType.tablet) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: hasGlow
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: resolvedColor.withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    spreadRadius: 1,
                  ),
                ],
              )
            : null,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(resolvedColor, BlendMode.modulate),
          child: Image.asset(
            type.assetPath,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
              type.svgString,
              width: size * 0.85,
              height: size * 0.85,
              color: resolvedColor,
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
      decoration: hasGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: resolvedColor.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          resolvedColor,
          isDropOrSyrup ? BlendMode.color : BlendMode.modulate,
        ),
        child: Image.asset(
          type.assetPath,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => AppSvgIcons.render(
            type.svgString,
            width: size * 0.85,
            height: size * 0.85,
            color: resolvedColor,
          ),
        ),
      ),
    );
  }
}
