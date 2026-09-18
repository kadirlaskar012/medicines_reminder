import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/scheduled_dose.dart';
import '../providers/language_provider.dart';
import '../screens/medicines/add_edit_medicine_screen.dart';
import '../screens/medicines/medicine_details_screen.dart';
import 'dual_tone_capsule.dart';
import 'medicine_info_stock_sheet.dart';

class DoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final VoidCallback onTake;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  const DoseCard({
    super.key,
    required this.dose,
    required this.onTake,
    required this.onSkip,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final med = dose.medicine;
    final rem = dose.reminder;

    final now = DateTime.now();
    final doseDateTime = DateTime(
      dose.scheduledDate.year,
      dose.scheduledDate.month,
      dose.scheduledDate.day,
      rem.hour,
      rem.minute,
    );
    final diff = doseDateTime.difference(now);

    final isPastGracePeriod = diff.inMinutes < -180; // More than 3 hours late
    final isOverdue = !dose.isTaken && !dose.isSkipped && diff.inMinutes < -15 && !isPastGracePeriod;
    final isMissed = !dose.isTaken && !dose.isSkipped && isPastGracePeriod;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailsScreen(medicine: med),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: dose.isTaken
              ? (isDark ? const Color(0xFF0D251D) : const Color(0xFFF0FDF4))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: dose.isTaken
                ? AppColors.accentEmerald.withValues(alpha: 0.4)
                : isMissed
                    ? AppColors.accentRose.withValues(alpha: 0.35)
                    : isOverdue
                        ? AppColors.accentAmber.withValues(alpha: 0.4)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: dose.isTaken
                  ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.12 : 0.08)
                  : isOverdue
                      ? AppColors.accentAmber.withValues(alpha: isDark ? 0.12 : 0.08)
                      : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            // Left: Dual-Tone 3D Capsule in Squircle Shell
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: DualToneCapsule.fromIndex(
                  med.colorValue,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle: Medicine Info & Timing Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          med.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (med.dosage.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            med.dosage,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Time pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryTeal.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 11, color: AppColors.primaryTealLight),
                            const SizedBox(width: 4),
                            Text(
                              rem.formattedTime,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Food instruction badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accentAmber.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          s.foodInstructionName(med.instruction.name),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right: Interactive Status / Actions
            if (dose.isTaken)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentEmerald.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentEmerald, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Taken',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentEmerald,
                          ),
                        ),
                      ],
                    ),
                    if (dose.record?.recordedAt != null)
                      Text(
                        DateFormat('h:mm a').format(dose.record!.recordedAt),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentEmerald.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              )
            else if (dose.isSkipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Skipped',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              )
            else if (isMissed)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentRose.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Missed',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentRose,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onTake,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Take Now',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTealLight,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Active / Due Now / Overdue / Upcoming Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Take Now Button
                  GestureDetector(
                    onTap: onTake,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentEmerald.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            isOverdue ? 'Take' : 'Take',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Snooze Icon Button
                  InkWell(
                    onTap: onSnooze,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.snooze_rounded,
                        size: 15,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // Skip Icon Button
                  InkWell(
                    onTap: onSkip,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Edit badge button
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEditMedicineScreen(medicineToEdit: med)),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardElevated : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryTealLight),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right: Info & Stock badge button
                InkWell(
                  onTap: () => MedicineInfoStockSheet.show(context, med),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 13, color: AppColors.primaryTealLight),
                        const SizedBox(width: 5),
                        Text(
                          'Info & Stock',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                          ),
                        ),
                        if (med.isLowStock || med.isOutOfStock) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentRose,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0, duration: 250.ms);
  }
}

