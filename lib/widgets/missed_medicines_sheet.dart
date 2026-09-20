import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_strings.dart';
import '../models/reminder_time.dart';
import '../models/scheduled_dose.dart';
import '../providers/language_provider.dart';
import '../providers/medicine_provider.dart';
import 'medicine_visual.dart';

class MissedMedicinesSheet extends StatelessWidget {
  const MissedMedicinesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MissedMedicinesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final missedDoses = provider.getMissedDoses();

    // Group doses by date string
    final Map<String, List<ScheduledDose>> grouped = {};
    for (final dose in missedDoses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(dose.scheduledDate);
      grouped.putIfAbsent(dateKey, () => []).add(dose);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest date first

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFFF43F5E).withValues(alpha: 0.35)
                : const Color(0xFFF43F5E).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.code == 'bn' ? 'ছুটে যাওয়া ওষুধ' : (s.code == 'hi' ? 'छूटी हुई दवाएं' : 'Missed Medicines'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        missedDoses.isEmpty
                            ? (s.code == 'bn' ? 'কোনো ওষুধ বাকি নেই 🎉' : 'All caught up! 🎉')
                            : (s.code == 'bn'
                                ? '${missedDoses.length}টি ওষুধের ডোজ গ্রহণ করা হয়নি'
                                : '${missedDoses.length} missed dose(s) pending'),
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),

          // Body Content
          Flexible(
            child: missedDoses.isEmpty
                ? _buildEmptyState(context, isDark, s)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, dateIndex) {
                      final dateStr = sortedDates[dateIndex];
                      final doses = grouped[dateStr] ?? [];
                      final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
                      final dateLabel = _formatDateLabel(parsedDate, s);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header Pill
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event_note_rounded, size: 13, color: Color(0xFFE11D48)),
                                      const SizedBox(width: 5),
                                      Text(
                                        dateLabel,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Missed Dose Cards for this date
                          ...doses.map((dose) => _buildMissedDoseCard(context, dose, isDark, s)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.code == 'bn' ? 'সব মিসড ওষুধ ক্লিয়ার হয়েছে!' : 'All Missed Doses Cleared!',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.code == 'bn'
                ? 'আপনার আর কোনো ছুটে যাওয়া ওষুধ বাকি নেই।'
                : 'You have no unresolved missed medicines.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            ),
            child: Text(
              s.code == 'bn' ? 'ঠিক আছে' : 'Got it',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedDoseCard(
    BuildContext context,
    ScheduledDose dose,
    bool isDark,
    AppStrings s,
  ) {
    final provider = context.read<MedicineProvider>();
    final med = dose.medicine;
    final rem = dose.reminder;
    final typeGradients = MedicineVisual.getGradients(med.colorValue, med.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF43F5E).withValues(alpha: 0.3)
              : const Color(0xFFFECDD3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      typeGradients[0].withValues(alpha: isDark ? 0.16 : 0.08),
                      typeGradients[1].withValues(alpha: isDark ? 0.06 : 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: typeGradients[0].withValues(alpha: isDark ? 0.35 : 0.22),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: MedicineVisual.fromMedicine(
                    med,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 11),

              // Medicine Name & Dosage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (med.dosage.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeGradients[0].withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              med.dosage,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? typeGradients[1] : typeGradients[0],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // Time Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.22 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 11, color: Color(0xFFE11D48)),
                              const SizedBox(width: 3.5),
                              Text(
                                '${rem.formattedTime} • ${_getTimeSlotTitle(rem.timeSlot, s)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE11D48),
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
            ],
          ),

          const SizedBox(height: 10),

          // Glossy Action Buttons: Take Late & Skip
          Row(
            children: [
              // Take Late Button (Glossy Deep Emerald)
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: () async {
                    await provider.markAsTaken(med, rem, dose.scheduledDate);
                  },
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color(0xFF064E3B).withValues(alpha: 0.7),
                                const Color(0xFF022C22).withValues(alpha: 0.85),
                              ]
                            : [
                                const Color(0xFFE6FBF0),
                                const Color(0xFFB7F4D4),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isDark ? const Color(0xFF10B981).withValues(alpha: 0.7) : const Color(0xFF10B981),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: isDark ? 0.3 : 0.18),
                          blurRadius: 6,
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
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.code == 'bn' ? 'দেরিতে খেয়েছি' : (s.code == 'hi' ? 'देर से ली' : 'Take Late'),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Skip Button (Glossy Rich Coral Rose)
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: () async {
                    await provider.markAsSkipped(med, rem, dose.scheduledDate);
                  },
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color(0xFF4C0519).withValues(alpha: 0.65),
                                const Color(0xFF28020D).withValues(alpha: 0.8),
                              ]
                            : [
                                const Color(0xFFFFF1F2),
                                const Color(0xFFFECDD3),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.7) : const Color(0xFFE11D48),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.3 : 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.skipAction,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFDA4AF) : const Color(0xFF9F1239),
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
      ),
    );
  }

  String _formatDateLabel(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) {
      return s.code == 'bn' ? 'আজকের (Today)' : 'Today';
    } else if (diffDays == 1) {
      return s.code == 'bn' ? 'গতকাল (${DateFormat('d MMM').format(date)})' : 'Yesterday (${DateFormat('d MMM').format(date)})';
    } else {
      return DateFormat('EEEE, d MMM').format(date);
    }
  }

  String _getTimeSlotTitle(TimeSlot slot, AppStrings s) {
    if (s.code == 'bn') {
      switch (slot) {
        case TimeSlot.morning:
          return 'সকাল';
        case TimeSlot.lunch:
          return 'দুপুর';
        case TimeSlot.afternoon:
          return 'বিকাল';
        case TimeSlot.evening:
          return 'সন্ধ্যা';
        case TimeSlot.night:
          return 'রাত';
      }
    } else if (s.code == 'hi') {
      switch (slot) {
        case TimeSlot.morning:
          return 'सुबह';
        case TimeSlot.lunch:
          return 'दोपहर (लंच)';
        case TimeSlot.afternoon:
          return 'दोपहर बाद';
        case TimeSlot.evening:
          return 'शाम';
        case TimeSlot.night:
          return 'रात';
      }
    }
    return slot.title;
  }
}
