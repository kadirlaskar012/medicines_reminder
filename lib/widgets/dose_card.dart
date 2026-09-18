import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import '../models/scheduled_dose.dart';
import '../providers/language_provider.dart';
import '../screens/medicines/medicine_details_screen.dart';
import 'dual_tone_capsule.dart';

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

  static List<Color> _getGradientForMedicine(MedicineType type) => switch (type) {
        MedicineType.tablet => const [Color(0xFF0D9488), Color(0xFF06B6D4)],
        MedicineType.capsule => const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        MedicineType.syrup => const [Color(0xFFD97706), Color(0xFFF59E0B)],
        MedicineType.injection => const [Color(0xFFE11D48), Color(0xFFF43F5E)],
        MedicineType.drops => const [Color(0xFF0284C7), Color(0xFF38BDF8)],
        MedicineType.inhaler => const [Color(0xFF059669), Color(0xFF10B981)],
        MedicineType.ointment => const [Color(0xFF9333EA), Color(0xFFC084FC)],
        MedicineType.supplement => const [Color(0xFFEA580C), Color(0xFFFBBF24)],
        MedicineType.other => const [Color(0xFF0D9488), Color(0xFF3B82F6)],
      };

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

    final medGradients = _getGradientForMedicine(med.type);

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
              : isMissed
                  ? (isDark ? const Color(0xFF280E14) : const Color(0xFFFFF1F2))
                  : isOverdue
                      ? (isDark ? const Color(0xFF261808) : const Color(0xFFFFFBEB))
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
                            ? medGradients[0].withValues(alpha: 0.32)
                            : medGradients[0].withValues(alpha: 0.22)),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: dose.isTaken
                  ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.2 : 0.12)
                  : isMissed
                      ? AppColors.accentRose.withValues(alpha: isDark ? 0.22 : 0.14)
                      : isOverdue
                          ? AppColors.accentAmber.withValues(alpha: isDark ? 0.22 : 0.14)
                          : medGradients[0].withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 16,
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
                // Left: Medicine Squircle Gradient Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        medGradients[0].withValues(alpha: isDark ? 0.35 : 0.18),
                        medGradients[1].withValues(alpha: isDark ? 0.18 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: medGradients[0].withValues(alpha: isDark ? 0.55 : 0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: medGradients[0].withValues(alpha: isDark ? 0.3 : 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: DualToneCapsule.fromIndex(
                      med.colorValue,
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
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right: Status indicator (Taken / Skipped / Missed / Due Now)
                if (dose.isTaken)
                  Container(
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
                      s.code == 'bn' ? 'বাদ দেওয়া হয়েছে' : (s.code == 'hi' ? 'छोड़ दिया' : 'Skipped'),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                          s.code == 'bn' ? 'মিস হয়েছে' : (s.code == 'hi' ? 'छूट गई' : 'Missed'),
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
                          s.code == 'bn' ? 'বাকি আছে' : (s.code == 'hi' ? 'देरी' : 'Due Now'),
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

            // Action Buttons for Active / Due / Upcoming / Missed Doses
            if (!dose.isTaken && !dose.isSkipped) ...[
              const SizedBox(height: 13),
              Row(
                children: [
                  // 1. Take Now Button (Emerald Radiant Gradient)
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: onTake,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.38),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              s.takeAction,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. Snooze Button (Radiant Warm Amber Gradient)
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: onSnooze,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.snooze_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              s.snoozeAction,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Skip Button (Sleek Slate Pill)
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: onSkip,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.skipAction,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0, duration: 250.ms);
  }
}

