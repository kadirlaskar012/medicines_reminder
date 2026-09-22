import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

class StockMeterBar extends StatelessWidget {
  final int currentStock;
  final int totalCapacity;
  final int threshold;
  final String unit;
  final VoidCallback? onRefillTap;
  final AppStrings? strings;

  const StockMeterBar({
    super.key,
    required this.currentStock,
    this.totalCapacity = 30,
    this.threshold = 5,
    this.unit = 'units',
    this.onRefillTap,
    this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final s = strings ?? context.watch<LanguageProvider>().strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = totalCapacity > 0 ? totalCapacity : 30;
    final ratio = (currentStock / maxVal).clamp(0.0, 1.0);
    final isLow = currentStock <= threshold;
    final isWarning = !isLow && currentStock <= (threshold * 2);

    final fillColor = isLow
        ? AppColors.accentRose
        : isWarning
            ? AppColors.accentAmber
            : AppColors.accentEmerald;

    final fillGradient = isLow
        ? AppColors.roseGradient
        : isWarning
            ? AppColors.amberGradient
            : AppColors.emeraldGradient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isLow) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentRose,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentRose.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  isLow ? s.lowStockWarningLabel : s.stockRemainingLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLow
                        ? AppColors.accentRose
                        : isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  s.unitsLeftText(currentStock, unit),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLow
                        ? AppColors.accentRose
                        : isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
                if (onRefillTap != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onRefillTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryTeal.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        s.refillBtn,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryTealLight : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar track
        Container(
          height: 7,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * ratio,
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: fillGradient,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: fillColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
