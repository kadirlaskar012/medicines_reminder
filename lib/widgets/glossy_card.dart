import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GlossyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? glowColor;
  final Color? customBackground;
  final bool isElevated;

  const GlossyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 22,
    this.onTap,
    this.glowColor,
    this.customBackground,
    this.isElevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = customBackground ??
        (isDark
            ? (isElevated ? AppColors.darkCardElevated : AppColors.darkCard)
            : (isElevated ? AppColors.lightCardElevated : AppColors.lightCard));

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? (glowColor != null
                  ? glowColor!.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.10))
              : (glowColor != null
                  ? glowColor!.withValues(alpha: 0.25)
                  : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: AppColors.glossyCardShadow(isDark, glowColor: glowColor),
      ),
      child: Stack(
        children: [
          // Specular glass highlight reflection at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 28,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius - 1),
                    topRight: Radius.circular(borderRadius - 1),
                  ),
                  gradient: isDark
                      ? AppColors.glossySheenDark
                      : AppColors.glossySheenLight,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );

    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (glowColor ?? AppColors.primaryTeal).withValues(alpha: 0.12),
          highlightColor: (glowColor ?? AppColors.primaryTeal).withValues(alpha: 0.06),
          child: cardContent,
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
