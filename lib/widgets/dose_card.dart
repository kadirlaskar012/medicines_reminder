import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/reminder_time.dart';
import '../models/scheduled_dose.dart';
import '../providers/language_provider.dart';
import '../providers/medicine_provider.dart';
import '../screens/medicines/medicine_details_screen.dart';
import 'medicine_visual.dart';

class DoseCard extends StatelessWidget {
  final ScheduledDose dose;
  final VoidCallback onTake;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;
  final bool isActionable;
  final VoidCallback? onLongPress;
  final VoidCallback? onStatusTap;

  const DoseCard({
    super.key,
    required this.dose,
    required this.onTake,
    required this.onSkip,
    required this.onSnooze,
    this.isActionable = true,
    this.onLongPress,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.read<LanguageProvider>().strings;
    final med = dose.medicine;
    final rem = dose.reminder;

    final provider = context.read<MedicineProvider>();
    final allRems = provider.getRemindersForMedicine(med.id);
    String? routinePattern;
    if (allRems.isNotEmpty) {
      int m = 0, l = 0, a = 0, e = 0, n = 0;
      for (final r in allRems) {
        switch (r.timeSlot) {
          case TimeSlot.morning: m++; break;
          case TimeSlot.lunch: l++; break;
          case TimeSlot.afternoon: a++; break;
          case TimeSlot.evening: e++; break;
          case TimeSlot.night: n++; break;
        }
      }
      final sm = s.formatNumber(m);
      final sl = s.formatNumber(l);
      final sa = s.formatNumber(a);
      final se = s.formatNumber(e);
      final sn = s.formatNumber(n);
      if (l == 0 && a == 0 && e == 0) {
        routinePattern = '$sm-$sn';
      } else if (l == 0 && e == 0) {
        routinePattern = '$sm-$sa-$sn';
      } else if (l == 0) {
        routinePattern = '$sm-$sa-$se-$sn';
      } else {
        routinePattern = '$sm-$sl-$sa-$se-$sn';
      }
    }

    final now = DateTime.now();
    final doseDateTime = DateTime(
      dose.scheduledDate.year,
      dose.scheduledDate.month,
      dose.scheduledDate.day,
      rem.hour,
      rem.minute,
    );
    final isOverdue = !dose.isTaken && !dose.isSkipped && now.isAfter(doseDateTime);
    final isPastGracePeriod = now.isAfter(doseDateTime.add(const Duration(minutes: 60)));
    final isMissed = !dose.isTaken && !dose.isSkipped && isPastGracePeriod;

    final medGradients = MedicineVisual.getGradients(med.colorValue, med.type);

    final card = InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailsScreen(medicine: med),
          ),
        );
      },
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: dose.isTaken
              ? (isDark ? const Color(0xFF0C241C) : const Color(0xFFF0FDF4))
              : isMissed
                  ? (isDark ? const Color(0xFF260E14) : const Color(0xFFFFF1F2))
                  : isOverdue
                      ? (isDark ? const Color(0xFF241608) : const Color(0xFFFFFBEB))
                      : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: dose.isTaken
                ? AppColors.accentEmerald.withValues(alpha: 0.5)
                : isMissed
                    ? AppColors.accentRose.withValues(alpha: 0.5)
                    : isOverdue
                        ? AppColors.accentAmber.withValues(alpha: 0.55)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : medGradients[0].withValues(alpha: 0.22)),
            width: 1.3,
          ),
          boxShadow: AppColors.glossyCardShadow(
            isDark,
            glowColor: dose.isTaken
                ? AppColors.accentEmerald
                : isMissed
                    ? AppColors.accentRose
                    : isOverdue
                        ? AppColors.accentAmber
                        : medGradients[0],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.glossySheenDark
                          : AppColors.glossySheenLight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Medicine Squircle Frosted Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medGradients[0].withValues(alpha: isDark ? 0.16 : 0.08),
                        medGradients[1].withValues(alpha: isDark ? 0.06 : 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: medGradients[0].withValues(alpha: isDark ? 0.35 : 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: MedicineVisual.fromMedicine(
                      med,
                      size: 38,
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
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: medGradients[0].withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: medGradients[0].withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                med.dosage,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? medGradients[1] : medGradients[0],
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
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.25 : 0.12),
                                  const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                Text(
                                  rem.formattedTime,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Food instruction badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFEA580C).withValues(alpha: isDark ? 0.25 : 0.12),
                                  const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 11, color: Color(0xFFEA580C)),
                                const SizedBox(width: 4),
                                Text(
                                  s.foodInstructionName(med.instruction.name),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Prescription Pattern badge (e.g. 💊 1-0-1)
                          if (routinePattern != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF0D9488).withValues(alpha: isDark ? 0.25 : 0.12),
                                    const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('💊', style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    routinePattern,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right: Status indicator (Taken / Skipped / Missed / Due Now)
                if (dose.isTaken)
                  InkWell(
                    onTap: onStatusTap ?? onLongPress,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentEmerald.withValues(alpha: isDark ? 0.28 : 0.16),
                            AppColors.accentEmerald.withValues(alpha: isDark ? 0.14 : 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentEmerald.withValues(alpha: 0.4),
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
                                s.taken,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentEmerald,
                                ),
                              ),
                              if (onLongPress != null || onStatusTap != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.sync_rounded,
                                  size: 11,
                                  color: AppColors.accentEmerald.withValues(alpha: 0.8),
                                ),
                              ],
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
                    ),
                  )
                else if (dose.isSkipped)
                  InkWell(
                    onTap: onStatusTap ?? onLongPress,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.28) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.45 : 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cancel_rounded, size: 12, color: Color(0xFFE11D48)),
                          const SizedBox(width: 4),
                          Text(
                            s.skipped,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
                            ),
                          ),
                          if (onLongPress != null || onStatusTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.sync_rounded,
                              size: 11,
                              color: const Color(0xFFE11D48).withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (isMissed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentRose.withValues(alpha: isDark ? 0.28 : 0.16),
                          AppColors.accentRose.withValues(alpha: isDark ? 0.14 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.accentRose.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 12, color: AppColors.accentRose),
                        const SizedBox(width: 3),
                        Text(
                          s.missed,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentRose,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentAmber.withValues(alpha: isDark ? 0.28 : 0.16),
                          AppColors.accentAmber.withValues(alpha: isDark ? 0.14 : 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.accentAmber.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.dueNow,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Action Buttons or Scheduled Indicator for Pending Doses
            if (!dose.isTaken && !dose.isSkipped) ...[
              if (isActionable) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    // 1. Take Now Button (Soft Calming Light Mint Pastel)
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: onTake,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      const Color(0xFF064E3B).withValues(alpha: 0.4),
                                      const Color(0xFF022C22).withValues(alpha: 0.5),
                                    ]
                                  : [
                                      const Color(0xFFECFDF5),
                                      const Color(0xFFD1FAE5),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.45),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                s.takeAction,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),

                    // 2. Snooze Button (Soft Warm Light Honey Amber Pastel)
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: onSnooze,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      const Color(0xFF78350F).withValues(alpha: 0.35),
                                      const Color(0xFF451A03).withValues(alpha: 0.45),
                                    ]
                                  : [
                                      const Color(0xFFFFFBEB),
                                      const Color(0xFFFEF3C7),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.45),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.snooze_rounded,
                                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                s.snoozeAction,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),

                    // 3. Skip Button (Soft Light Pastel Crimson Red - Gentle & Eye-Pleasing)
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: onSkip,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isDark
                                  ? [
                                      const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                                      const Color(0xFF450A0A).withValues(alpha: 0.45),
                                    ]
                                  : [
                                      const Color(0xFFFEF2F2),
                                      const Color(0xFFFEE2E2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.4 : 0.45),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                s.skipAction,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Inactive Future Dose: Clean Scheduled Timing Banner
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: rem.timeSlot.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.timeSlotScheduled(rem.timeSlot.titleLocalized(s), rem.formattedTime),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: rem.timeSlot.color.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.upcomingStatus,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: rem.timeSlot.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if ((dose.isTaken || dose.isSkipped) && onLongPress != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 11.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.holdToCorrectStatus,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return RepaintBoundary(child: card);
  }
}

