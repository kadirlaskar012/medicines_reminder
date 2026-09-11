import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_svg_icons.dart';
import '../core/services/report_and_alert_service.dart';
import '../core/theme/app_colors.dart';
import '../models/scheduled_dose.dart';
import 'pill_icon_badge.dart';

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
    final med = dose.medicine;
    final rem = dose.reminder;
    final medColor = Color(med.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dose.isTaken
              ? AppColors.success.withValues(alpha: 0.3)
              : dose.isOverdue
                  ? AppColors.error.withValues(alpha: 0.3)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
          width: dose.isTaken || dose.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PillIconBadge(
                  type: med.type,
                  color: medColor,
                  size: 50,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (rem.isAlarm)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            med.dosage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: medColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${rem.formattedTime}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 10),
            Row(
              children: [
                // Food instruction pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSvgIcons.render(
                        med.instruction.svgString,
                        width: 15,
                        height: 15,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        med.instruction.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (med.isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${med.currentStock} left',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Status or Actions
                if (dose.isTaken)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          dose.record?.recordedAt != null
                              ? 'Taken at ${DateFormat('hh:mm a').format(dose.record!.recordedAt)}'
                              : 'Taken',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 200.ms)
                else if (dose.isSkipped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_rounded, size: 16, color: AppColors.lightTextMuted),
                        SizedBox(width: 6),
                        Text(
                          'Skipped',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Popup menu for snooze & skip
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    onSelected: (val) {
                      if (val == 'snooze') onSnooze();
                      if (val == 'skip') onSkip();
                      if (val == 'caregiver') {
                        ReportAndAlertService.instance.sendCaregiverWhatsAppAlert(
                          memberName: dose.medicine.profileId == 'default_me' ? 'Patient' : 'Family Member',
                          medicineName: med.name,
                          dosage: med.dosage,
                          scheduledTime: rem.formattedTime,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'snooze',
                        child: Row(
                          children: [
                            Icon(Icons.snooze_rounded, size: 18, color: AppColors.warning),
                            SizedBox(width: 10),
                            Text('Snooze 10 mins'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'skip',
                        child: Row(
                          children: [
                            Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                            SizedBox(width: 10),
                            Text('Skip Dose'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'caregiver',
                        child: Row(
                          children: [
                            Icon(Icons.chat_rounded, size: 18, color: Color(0xFF10B981)),
                            SizedBox(width: 10),
                            Text('Alert Caregiver (WhatsApp)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: onTake,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Take', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
