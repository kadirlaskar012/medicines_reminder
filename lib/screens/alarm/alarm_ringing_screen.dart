import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_visual.dart';

class AlarmRingingScreen extends StatelessWidget {
  final Medicine medicine;
  final ReminderTime reminder;

  const AlarmRingingScreen({
    super.key,
    required this.medicine,
    required this.reminder,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: SafeArea(
        child: Stack(
          children: [
            // Glowing radial background spotlight behind the capsule
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.35),
                        AppColors.accentMint.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.accentEmerald, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          s.medicineReminderTag.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: AppColors.accentEmerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleXY(begin: 0.98, end: 1.04, duration: 1200.ms),

                  // Center Content: 3D Dual-Tone Capsule, Time Badge & Details
                  Column(
                    children: [
                      // 3D Angled Medicine Visual Hero
                      Center(
                        child: MedicineVisual.fromMedicine(
                          medicine,
                          size: 110,
                          hasGlow: true,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .moveY(begin: -8, end: 8, duration: 1800.ms)
                       .rotate(begin: -0.04, end: 0.04, duration: 2200.ms),

                      const SizedBox(height: 24),

                      // Scheduled Alarm Time Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alarm_rounded, color: AppColors.primaryTealLight, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              reminder.formattedTime,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // "Time to take your [Medicine]"
                      Text(
                        'Time to take your medicine',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        medicine.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '${medicine.dosage} • ${s.foodInstructionName(medicine.instruction.name)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTealLight,
                        ),
                      ),

                      if (medicine.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Text(
                            medicine.notes,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom 3 Action Buttons (Screen 10 Layout)
                  Column(
                    children: [
                      // 1. Mark as Taken (Vibrant Emerald Gradient)
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.emeraldGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentEmerald.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              context.read<MedicineProvider>().markAsTaken(medicine, reminder, DateTime.now());
                              NotificationService.instance.dismissActiveReminderNotification(reminder: reminder);
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  s.iTookMyMedicine,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .shimmer(duration: 1800.ms, color: Colors.white30),

                      const SizedBox(height: 12),

                      // 2. Snooze & Skip row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<MedicineProvider>().snoozeDose(medicine, reminder, minutes: 10);
                                NotificationService.instance.dismissActiveReminderNotification(reminder: reminder);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.snooze_rounded, color: Colors.white, size: 18),
                              label: Text(
                                s.snooze10m,
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<MedicineProvider>().markAsSkipped(medicine, reminder, DateTime.now());
                                NotificationService.instance.dismissActiveReminderNotification(reminder: reminder);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.accentRose, size: 18),
                              label: Text(
                                s.skipDose,
                                style: GoogleFonts.outfit(color: AppColors.accentRose, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.4), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
