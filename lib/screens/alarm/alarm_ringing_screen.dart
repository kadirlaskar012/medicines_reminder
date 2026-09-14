import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/dual_tone_capsule.dart';

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
      backgroundColor: const Color(0xFF0B132B),
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
                        const Icon(Icons.notifications_active_rounded, color: AppColors.accentMint, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          s.medicineReminderTag.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accentMint,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleXY(begin: 0.98, end: 1.04, duration: 1200.ms),

                  // Center Content: 3D Dual-Tone Capsule, Time Badge & Details
                  Column(
                    children: [
                      // 3D Angled Dual Tone Capsule Hero
                      Center(
                        child: DualToneCapsule.fromIndex(
                          medicine.colorValue,
                          size: 110,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                       .moveY(begin: -8, end: 8, duration: 1800.ms)
                       .rotate(begin: -0.04, end: 0.04, duration: 2200.ms),

                      const SizedBox(height: 24),

                      // Scheduled Alarm Time Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.alarm_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              reminder.formattedTime,
                              style: const TextStyle(
                                fontSize: 26,
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        medicine.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        '${medicine.dosage} • ${s.foodInstructionName(medicine.instruction.name)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentMint,
                        ),
                      ),

                      if (medicine.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            medicine.notes,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Bottom 3 Action Buttons (Screen 10 Layout)
                  Column(
                    children: [
                      // 1. Mark as Taken (Vibrant Mint Green)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<MedicineProvider>().markAsTaken(medicine, reminder, DateTime.now());
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentMint,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppColors.accentMint.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                s.iTookMyMedicine,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
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
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.snooze_rounded, color: Colors.white, size: 18),
                              label: Text(
                                s.snooze10m,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                              label: Text(
                                s.skipDose,
                                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
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
