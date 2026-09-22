import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/app_strings.dart';
import '../models/app_notification.dart';
import '../models/medicine.dart';
import 'medicine_visual.dart';

/// A luxury, glassmorphic notification card designed specifically for MediRemind.
/// Features frosted crystal glass styling, 3D medicine visual with a glowing halo,
/// handwritten cursive motivational quote, and strictly horizontal action buttons
/// across all device screen sizes.
class LuxuryNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final AppStrings s;
  final bool isDark;
  final VoidCallback? onTake;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;
  final VoidCallback? onTap;

  const LuxuryNotificationCard({
    super.key,
    required this.notification,
    required this.s,
    required this.isDark,
    this.onTake,
    this.onSnooze,
    this.onSkip,
    this.onTap,
  });

  MedicineType _resolveMedicineType() {
    final rawType = notification.metadata?['medicineType'] as String?;
    if (rawType != null && rawType.isNotEmpty) {
      return MedicineType.values.firstWhere(
        (t) => t.name.toLowerCase() == rawType.toLowerCase(),
        orElse: () => MedicineType.tablet,
      );
    }
    return MedicineType.tablet;
  }

  @override
  Widget build(BuildContext context) {
    final medType = _resolveMedicineType();
    final medName = notification.medicineName ??
        (notification.metadata?['medicineName'] as String?) ??
        notification.localizedTitle(s);
    final dosage = (notification.metadata?['dosage'] as String?) ?? '';
    final rawInstruction = (notification.metadata?['instruction'] as String?) ?? '';
    final instruction = rawInstruction.isNotEmpty ? s.foodInstructionName(rawInstruction) : '';
    final timeStr = (notification.metadata?['time'] as String?) ?? '';
    final formattedTimestamp = s.formatNotifTimestamp(notification.timestamp);
    final isActionable = notification.type == NotificationType.reminderDue || onTake != null;

    final cardBg = isDark
        ? const Color(0xFF131D31)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF26354D)
        : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textMuted = isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 390;
        final double cardPadding = isNarrow ? 14 : 18;
        final double haloSize = isNarrow ? 76 : 88;
        final double visualSize = isNarrow ? 52 : 62;

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: !notification.isRead
                  ? const Color(0xFF0D9488).withValues(alpha: 0.5)
                  : borderColor,
              width: !notification.isRead ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF0D9488).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Brand & Timestamp Header Row
                    _buildHeaderRow(formattedTimestamp, textMain, textMuted),

                    const SizedBox(height: 14),

                    // 2. Middle Presentation: Info on Left + 3D Halo Visual on Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Medicine Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Primary Title
                              Text(
                                isActionable
                                    ? s.timeToTake
                                    : notification.localizedTitle(s),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isNarrow ? 15 : 17,
                                  fontWeight: FontWeight.w800,
                                  color: textMain,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),

                              // Medicine Name & Dosage Headline
                              Text(
                                medName.isNotEmpty ? medName : s.appName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isNarrow ? 18 : 21,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0D9488),
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Metadata Pills (Dosage + Timing)
                              Wrap(
                                spacing: 6,
                                runSpacing: 5,
                                children: [
                                  if (dosage.isNotEmpty)
                                    _buildMetaChip(
                                      icon: Icons.medication_rounded,
                                      label: dosage,
                                      isDark: isDark,
                                    ),
                                  if (instruction.isNotEmpty)
                                    _buildMetaChip(
                                      icon: Icons.nightlight_round,
                                      label: instruction,
                                      isDark: isDark,
                                    ),
                                  if (timeStr.isNotEmpty && instruction.isEmpty)
                                    _buildMetaChip(
                                      icon: Icons.access_time_filled_rounded,
                                      label: timeStr,
                                      isDark: isDark,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Motivational Prompt
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.notifMotivationPrompt,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: isNarrow ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: textSub,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFF06B6D4),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right: Glowing Halo + 3D Medicine Asset + Cursive Quote
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: haloSize,
                              height: haloSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF0D9488).withValues(alpha: isDark ? 0.35 : 0.18),
                                    const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.08),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.6, 0.85],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.28),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.3 : 0.12),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: MedicineVisual(
                                  type: medType,
                                  size: visualSize,
                                  hasGlow: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: haloSize + 20,
                              child: Text(
                                s.notifCursiveNote,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.caveat(
                                  fontSize: isNarrow ? 12 : 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0284C7),
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 3. Horizontal Action Buttons (Strictly side-by-side)
                    if (isActionable) ...[
                      const SizedBox(height: 16),
                      _buildHorizontalActionButtons(isNarrow, isDark),
                    ] else if (notification.localizedMessage(s).isNotEmpty && !isActionable) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notification.localizedMessage(s),
                          style: TextStyle(
                            fontSize: 12,
                            color: textSub,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(String timestamp, Color textMain, Color textMuted) {
    return Row(
      children: [
        // App Squircle Logo
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/icons/app_brand_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.medication_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Brand Names
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    s.appName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '• $timestamp',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                s.notifPartnerTagline,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),

        // Category Badge
        _buildCategoryBadge(),
      ],
    );
  }

  Widget _buildCategoryBadge() {
    final String label;
    final Color badgeBg;
    final Color badgeText;

    switch (notification.type) {
      case NotificationType.reminderDue:
        label = s.due;
        badgeBg = const Color(0xFF0D9488).withValues(alpha: 0.12);
        badgeText = const Color(0xFF0D9488);
        break;
      case NotificationType.doseTaken:
        label = s.taken;
        badgeBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        badgeText = const Color(0xFF059669);
        break;
      case NotificationType.doseSkipped:
        label = s.skipped;
        badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        badgeText = const Color(0xFFD97706);
        break;
      case NotificationType.doseSnoozed:
        label = s.notifFilterUpcoming;
        badgeBg = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
        badgeText = const Color(0xFF7C3AED);
        break;
      case NotificationType.doseMissed:
        label = s.missed;
        badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        badgeText = const Color(0xFFDC2626);
        break;
      case NotificationType.medicineAdded:
        label = s.notifFilterMedicines;
        badgeBg = const Color(0xFF06B6D4).withValues(alpha: 0.12);
        badgeText = const Color(0xFF0891B2);
        break;
      case NotificationType.medicineUpdated:
        label = s.notifFilterMedicines;
        badgeBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        badgeText = const Color(0xFF2563EB);
        break;
      case NotificationType.refillAdded:
      case NotificationType.lowStock:
        label = s.notifFilterStock;
        badgeBg = const Color(0xFFF97316).withValues(alpha: 0.12);
        badgeText = const Color(0xFFEA580C);
        break;
      default:
        label = s.notifHubTitle;
        badgeBg = const Color(0xFF64748B).withValues(alpha: 0.12);
        badgeText = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: badgeText,
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D9488).withValues(alpha: 0.15)
            : const Color(0xFF0D9488).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0D9488)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }

  /// Strictly horizontal row of 3 action buttons across all screen widths.
  Widget _buildHorizontalActionButtons(bool isNarrow, bool isDark) {
    return Row(
      children: [
        // 1. Primary: Mark as Taken
        Expanded(
          flex: 13,
          child: _buildPillButton(
            label: s.iTookMyMedicine,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            textColor: Colors.white,
            iconWidget: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
            ),
            onTap: onTake,
            shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.35),
            fontSize: isNarrow ? 11 : 12,
          ),
        ),
        const SizedBox(width: 6),

        // 2. Secondary: Snooze 10m
        Expanded(
          flex: 11,
          child: _buildPillButton(
            label: s.snooze10m,
            bgColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            textColor: isDark ? Colors.white : const Color(0xFF334155),
            iconWidget: Icon(
              Icons.access_time_rounded,
              size: 13,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            onTap: onSnooze,
            fontSize: isNarrow ? 10.5 : 11.5,
          ),
        ),
        const SizedBox(width: 6),

        // 3. Negative: Skip
        Expanded(
          flex: 8,
          child: _buildPillButton(
            label: s.skip,
            bgColor: isDark
                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                : const Color(0xFFFEF2F2),
            borderColor: isDark
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : const Color(0xFFFECACA),
            textColor: const Color(0xFFEF4444),
            iconWidget: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFFEF4444),
            ),
            onTap: onSkip,
            fontSize: isNarrow ? 10.5 : 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton({
    required String label,
    required VoidCallback? onTap,
    Gradient? gradient,
    Color? bgColor,
    Color? borderColor,
    required Color textColor,
    required Widget iconWidget,
    Color? shadowColor,
    required double fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
