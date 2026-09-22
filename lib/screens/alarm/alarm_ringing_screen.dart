import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/alarm_audio_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_visual.dart';

class AlarmRingingScreen extends StatefulWidget {
  final Medicine medicine;
  final ReminderTime reminder;
  final int? notificationId;

  const AlarmRingingScreen({
    super.key,
    required this.medicine,
    required this.reminder,
    this.notificationId,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  @override
  void initState() {
    super.initState();
    // Start playing the alarm tone in a loop
    AlarmAudioService.instance.startAlarm();
  }

  @override
  void dispose() {
    // Ensure alarm stops if navigating away
    AlarmAudioService.instance.stopAlarm();
    super.dispose();
  }

  Future<void> _handlePopDismiss() async {
    await AlarmAudioService.instance.stopAlarm();
    await NotificationService.instance.dismissActiveReminderNotification(
      reminder: widget.reminder,
      notificationId: widget.notificationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final medicine = widget.medicine;
    final reminder = widget.reminder;
    final gradients = MedicineVisual.getGradients(medicine.colorValue, medicine.type);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _handlePopDismiss();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF070B14),
        body: Stack(
          children: [
            // Background Ambient Aura Glow tailored dynamically to medicine color
            Positioned(
              top: -120,
              left: -80,
              right: -80,
              height: 480,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gradients.first.withValues(alpha: 0.38),
                      gradients.last.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top App Header: Pill Title + Symmetrical Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.alarm_on_rounded, color: AppColors.accentEmerald, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                s.doseReminderTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () async {
                              await _handlePopDismiss();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Central Medicine Presentation Card
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing Icon Squircle Container with actual medicine visual
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradients.first.withValues(alpha: 0.9),
                                gradients.last.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gradients.first.withValues(alpha: 0.45),
                                blurRadius: 36,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: MedicineVisual.fromMedicine(
                              medicine,
                              size: 80,
                              hasGlow: true,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut),

                        const SizedBox(height: 26),

                        // Time Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D33),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled_rounded, color: AppColors.accentCyan, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                reminder.formattedTime,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Medicine Name + Dose beside it
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Text(
                                medicine.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (medicine.dosage.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        gradients.first.withValues(alpha: 0.35),
                                        gradients.last.withValues(alpha: 0.18),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: gradients.first.withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    medicine.unit.isNotEmpty
                                        ? '${medicine.dosage} ${medicine.unit}'
                                        : medicine.dosage,
                                    style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Type & Timing / Food Instruction below
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${s.medicineTypeName(medicine.type.name)} • ${s.foodInstructionName(medicine.instruction.name)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),

                        if (medicine.notes.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
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

                    // Action Buttons (Take, Snooze, Skip)
                    Column(
                      children: [
                        // 1. Take Medicine Button (Large Vibrant Emerald Gradient)
                        Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                await AlarmAudioService.instance.stopAlarm();
                                final now = DateTime.now();
                                if (context.mounted) {
                                  await context.read<MedicineProvider>().markAsTaken(medicine, reminder, now);
                                }
                                await NotificationService.instance.dismissActiveReminderNotification(
                                  reminder: reminder,
                                  notificationId: widget.notificationId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.takeDoseAction,
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
                         .shimmer(duration: 2000.ms, color: Colors.white38),

                        const SizedBox(height: 12),

                        // 2. Snooze & Skip row
                        Row(
                          children: [
                            // Snooze Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await AlarmAudioService.instance.stopAlarm();
                                  if (!context.mounted) return;
                                  final provider = context.read<MedicineProvider>();
                                  final nav = Navigator.of(context);
                                  await NotificationService.instance.dismissActiveReminderNotification(
                                    reminder: reminder,
                                    notificationId: widget.notificationId,
                                  );
                                  await provider.snoozeDose(medicine, reminder, minutes: 10);
                                  if (context.mounted) {
                                    nav.pop();
                                  }
                                },
                                icon: const Icon(Icons.snooze_rounded, color: Colors.white, size: 18),
                                label: Text(
                                  s.snooze10mAction,
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
                                  backgroundColor: const Color(0xFF131D33),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Skip Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await AlarmAudioService.instance.stopAlarm();
                                  if (!context.mounted) return;
                                  final provider = context.read<MedicineProvider>();
                                  final nav = Navigator.of(context);
                                  final now = DateTime.now();
                                  await provider.markAsSkipped(medicine, reminder, now);
                                  await NotificationService.instance.dismissActiveReminderNotification(
                                    reminder: reminder,
                                    notificationId: widget.notificationId,
                                  );
                                  if (context.mounted) {
                                    nav.pop();
                                  }
                                },
                                icon: const Icon(Icons.close_rounded, color: AppColors.accentRose, size: 18),
                                label: Text(
                                  s.skipAction,
                                  style: GoogleFonts.outfit(color: AppColors.accentRose, fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: AppColors.accentRose.withValues(alpha: 0.4), width: 1.2),
                                  backgroundColor: const Color(0xFF131D33),
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
          ],
        ),
      ),
    );
  }
}
