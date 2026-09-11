import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/medicine_provider.dart';

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
    final medColor = Color(medicine.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm_on_rounded, color: AppColors.primaryLight, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'MEDICINE REMINDER • ${reminder.formattedTime}',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(begin: 1.0, end: 1.04, duration: 1200.ms),

              // Center Glowing Pill Icon & Info
              Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: medColor.withValues(alpha: 0.18),
                      border: Border.all(color: medColor.withValues(alpha: 0.6), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: medColor.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: AppSvgIcons.render(
                        medicine.type.svgString,
                        width: 72,
                        height: 72,
                        color: medColor,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleXY(begin: 0.95, end: 1.08, duration: 800.ms),

                  const SizedBox(height: 36),
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicine.dosage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: medColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppSvgIcons.render(
                          medicine.instruction.svgString,
                          width: 16,
                          height: 16,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          medicine.instruction.title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (medicine.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      medicine.notes,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),

              // Bottom Actions
              Column(
                children: [
                  // Prominent "Take Medicine" Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<MedicineProvider>().markAsTaken(medicine, reminder, DateTime.now());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'I TOOK MY MEDICINE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .shimmer(duration: 1800.ms, color: Colors.white24),

                  const SizedBox(height: 14),

                  // Snooze and Skip Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<MedicineProvider>().snoozeDose(medicine, reminder, minutes: 10);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.snooze_rounded, color: AppColors.warning),
                          label: const Text(
                            'Snooze 10m',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF334155)),
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
                          icon: const Icon(Icons.cancel_rounded, color: Colors.white54),
                          label: const Text(
                            'Skip Dose',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF334155)),
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
      ),
    );
  }
}
