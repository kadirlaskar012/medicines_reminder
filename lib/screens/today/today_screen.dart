import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/adherence_ring.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/empty_medicines_view.dart';
import '../medicines/add_edit_medicine_screen.dart';
import '../medicines/medicines_cabinet_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/profile_selector_sheet.dart';
import '../../widgets/missed_medicines_sheet.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TimeSlot? _selectedSlotFilter; // null = All
  Timer? _autoSkipTimer;

  static TimeSlot get currentLiveTimeSlot {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return TimeSlot.morning;
    if (hour >= 12 && hour < 17) return TimeSlot.afternoon;
    if (hour >= 17 && hour < 21) return TimeSlot.evening;
    return TimeSlot.night;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        final now = DateTime.now();
        if (!DateUtils.isSameDay(provider.selectedDate, now)) {
          provider.selectDate(now);
        } else {
          provider.autoSkipPastDueDoses();
        }
      }
    });

    // Check periodically every minute for slot transition auto-skipping
    _autoSkipTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        if (DateUtils.isSameDay(provider.selectedDate, DateTime.now())) {
          provider.autoSkipPastDueDoses();
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSkipTimer?.cancel();
    super.dispose();
  }

  bool _isDoseActionable(ScheduledDose dose, bool isViewingToday) {
    if (!isViewingToday) return false;
    if (dose.isTaken || dose.isSkipped) return false;

    final now = DateTime.now();
    final liveSlot = currentLiveTimeSlot;
    final doseDateTime = DateTime(
      dose.scheduledDate.year,
      dose.scheduledDate.month,
      dose.scheduledDate.day,
      dose.reminder.hour,
      dose.reminder.minute,
    );

    // If due now or overdue
    if (now.isAfter(doseDateTime)) return true;

    // If in the current live slot
    if (dose.reminder.timeSlot == liveSlot) return true;

    // If within 30 minutes of scheduled time
    if (doseDateTime.difference(now).inMinutes <= 30) return true;

    return false;
  }

  String _getTimeSlotTitle(TimeSlot slot, AppStrings s) {
    switch (slot) {
      case TimeSlot.morning:
        return s.morning;
      case TimeSlot.afternoon:
        return s.afternoon;
      case TimeSlot.evening:
        return s.evening;
      case TimeSlot.night:
        return s.night;
    }
  }

  String _getTimeBasedGreeting(AppStrings s) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return s.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      return s.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return s.goodEvening;
    } else {
      return s.goodNight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final activeProfile = provider.activeProfile;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final morningDoses = provider.morningDoses;
    final afternoonDoses = provider.afternoonDoses;
    final eveningDoses = provider.eveningDoses;
    final nightDoses = provider.nightDoses;
    final totalDoses = provider.dosesForSelectedDate.length;

    // Filter doses by selected time slot (or all doses by default)
    final allDosesForDate = provider.dosesForSelectedDate;
    final visibleDoses = _selectedSlotFilter == null
        ? allDosesForDate
        : allDosesForDate.where((d) => d.reminder.timeSlot == _selectedSlotFilter).toList();

    // Smart Priority Sorting:
    // 1. Pending doses (overdue / due now / upcoming next) come at the very top.
    // 2. Earliest upcoming/due medicine is index 0.
    // 3. As each medicine is marked taken, it moves down and the next upcoming moves up!
    // 4. Completed doses (taken / skipped) move beneath pending doses.
    final List<ScheduledDose> pendingDoses = [];
    final List<ScheduledDose> completedDoses = [];

    for (final d in visibleDoses) {
      if (d.isTaken || d.isSkipped) {
        completedDoses.add(d);
      } else if (d.isAutoMissed) {
        // Auto-missed doses appear exclusively in the floating Missed Pop-up pill & sheet
      } else {
        pendingDoses.add(d);
      }
    }

    final missedDoses = provider.getMissedDoses();

    final now = DateTime.now();
    final isViewingToday = DateUtils.isSameDay(provider.selectedDate, now);

    pendingDoses.sort((a, b) {
      if (isViewingToday) {
        final aActionable = _isDoseActionable(a, isViewingToday);
        final bActionable = _isDoseActionable(b, isViewingToday);
        if (aActionable && !bActionable) return -1;
        if (!aActionable && bActionable) return 1;
      }
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    final List<ScheduledDose> currentOrDueDoses = [];
    final List<ScheduledDose> upcomingDoses = [];

    for (final dose in pendingDoses) {
      if (_isDoseActionable(dose, isViewingToday)) {
        currentOrDueDoses.add(dose);
      } else {
        upcomingDoses.add(dose);
      }
    }

    // If viewing today, ensure at least the very first pending dose is actionable/current
    if (currentOrDueDoses.isEmpty && pendingDoses.isNotEmpty && isViewingToday) {
      currentOrDueDoses.add(pendingDoses.first);
      upcomingDoses.removeAt(0);
    }

    completedDoses.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    final userName = activeProfile != null
        ? (activeProfile.id == 'default_me' || activeProfile.name.toLowerCase() == 'myself' ? 'Kadir Laskar' : activeProfile.name)
        : 'Kadir Laskar';

    final hasAlerts = provider.dosesForSelectedDate.any(
      (d) => d.isOverdue || (!d.isTaken && !d.isSkipped && d.scheduledDate.isBefore(now)),
    );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Profile Pill & Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Pill
                    InkWell(
                      onTap: () => ProfileSelectorSheet.show(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [Colors.white, const Color(0xFFF8FAFC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF0D9488).withValues(alpha: 0.35)
                                : const Color(0xFF0D9488).withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.2 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0EA5E9), Color(0xFF0D9488)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryTeal.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('👤', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentEmerald,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accentEmerald.withValues(alpha: 0.8),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTimeBasedGreeting(s),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accentEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Actions (Date Picker + Bell)
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: provider.selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              provider.selectDate(picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.35 : 0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.2 : 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 21,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.35 : 0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 22,
                                  color: Color(0xFF3B82F6),
                                ),
                                if (hasAlerts)
                                  Positioned(
                                    top: 10,
                                    right: 11,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentRose,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          width: 1.4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accentRose.withValues(alpha: 0.9),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Hero Adherence Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                child: AdherenceRing(
                  rate: provider.todayAdherenceRate,
                  takenCount: provider.todayTakenCount,
                  totalCount: provider.todayTotalCount,
                  streakDays: provider.currentStreakDays,
                ),
              ),
            ),

            // Sleek Daily Prescription Routine Bar (1 - 0 - 0 - 1)
            SliverToBoxAdapter(
              child: _buildPrescriptionRoutineBar(
                morningCount: morningDoses.length,
                afternoonCount: afternoonDoses.length,
                eveningCount: eveningDoses.length,
                nightCount: nightDoses.length,
                isDark: isDark,
                s: s,
              ),
            ),

            // Section Header: Date status + View All
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.event_note_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedSlotFilter != null
                              ? (s.code == 'bn'
                                  ? '${_getTimeSlotTitle(_selectedSlotFilter!, s)}-এর ওষুধ'
                                  : '${_getTimeSlotTitle(_selectedSlotFilter!, s).toUpperCase()} DOSES')
                              : (isViewingToday
                                  ? (s.code == 'bn' ? 'আজকের ওষুধ' : 'TODAY\'S DOSES')
                                  : (s.code == 'bn'
                                      ? '${provider.selectedDate.day} ${DateFormat('MMMM').format(provider.selectedDate)}-এর ওষুধ'
                                      : '${DateFormat('MMMM d').format(provider.selectedDate).toUpperCase()}\'S DOSES')),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (pendingDoses.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryTeal.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              s.code == 'bn'
                                  ? '${pendingDoses.length}টি বাকি'
                                  : '${pendingDoses.length} pending',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (!isViewingToday) ...[
                          InkWell(
                            onTap: () => provider.selectDate(now),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.today_rounded, size: 13, color: AppColors.primaryTeal),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.code == 'bn' ? 'আজকে ফিরুন' : 'Today',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MedicinesCabinetScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0D9488).withValues(alpha: isDark ? 0.25 : 0.12),
                                  const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.medicinesTab,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Empty State
            if (totalDoses == 0)
              SliverToBoxAdapter(
                child: EmptyMedicinesView(
                  onAdd: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                    );
                  },
                ),
              ),


            // Dose Lists: Smart Priority Direct Rendering
            // 1. Current / Due Doses (Actionable with Take, Snooze, Skip)
            if (currentOrDueDoses.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dose = currentOrDueDoses[index];
                      return DoseCard(
                        dose: dose,
                        isActionable: true,
                        onTake: () {
                          provider.markAsTaken(dose.medicine, dose.reminder, dose.scheduledDate);
                        },
                        onSkip: () {
                          provider.markAsSkipped(dose.medicine, dose.reminder, dose.scheduledDate);
                        },
                        onSnooze: () {
                          provider.snoozeDose(dose.medicine, dose.reminder, minutes: 10);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.snoozedMessage(dose.medicine.name, 10)),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    childCount: currentOrDueDoses.length,
                  ),
                ),
              ),

            // 2. Upcoming Medicines Separator (with subtle Dashed Line and label)
            if (upcomingDoses.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      // Left dashed line
                      Expanded(
                        child: CustomPaint(
                          painter: DashedLinePainter(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          size: const Size(double.infinity, 1),
                        ),
                      ),
                      // Center badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF6366F1)),
                              const SizedBox(width: 5),
                              Text(
                                s.code == 'bn' ? 'পরবর্তী ওষুধসমূহ' : 'UPCOMING MEDICINES',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right dashed line
                      Expanded(
                        child: CustomPaint(
                          painter: DashedLinePainter(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          size: const Size(double.infinity, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Upcoming Scheduled Doses (Scheduled for later today, clean look)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dose = upcomingDoses[index];
                      return DoseCard(
                        dose: dose,
                        isActionable: false,
                        onTake: () {
                          provider.markAsTaken(dose.medicine, dose.reminder, dose.scheduledDate);
                        },
                        onSkip: () {
                          provider.markAsSkipped(dose.medicine, dose.reminder, dose.scheduledDate);
                        },
                        onSnooze: () {
                          provider.snoozeDose(dose.medicine, dose.reminder, minutes: 10);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(s.snoozedMessage(dose.medicine.name, 10)),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    childCount: upcomingDoses.length,
                  ),
                ),
              ),
            ],

            // 2. Completed Doses (taken / skipped) in their dedicated completed section
            if (completedDoses.isNotEmpty)
              ..._buildDoseSection(
                context,
                title: s.code == 'bn' ? 'আজকের সম্পন্ন ওষুধ' : 'Completed Today',
                icon: Icons.check_circle_rounded,
                color: AppColors.accentEmerald,
                doses: completedDoses,
                s: s,
                isCompletedSection: true,
                isViewingToday: isViewingToday,
              ),

            if (_selectedSlotFilter != null && pendingDoses.isEmpty && completedDoses.isEmpty && totalDoses > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _selectedSlotFilter!.icon,
                          size: 44,
                          color: _selectedSlotFilter!.color.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.code == 'bn'
                              ? '${_getTimeSlotTitle(_selectedSlotFilter!, s)}-এ কোনো ওষুধ নির্ধারিত নেই'
                              : 'No medicines scheduled for ${_getTimeSlotTitle(_selectedSlotFilter!, s)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
        if (missedDoses.isNotEmpty)
          Positioned(
            bottom: 16,
            right: 18,
            child: _buildMissedFloatingPill(context, missedDoses, isDark, s),
          ),
      ],
    ),
  ),
);
  }

  Widget _buildMissedFloatingPill(
    BuildContext context,
    List<ScheduledDose> missedDoses,
    bool isDark,
    AppStrings s,
  ) {
    final count = missedDoses.length;
    final label = s.code == 'bn'
        ? 'ছুটে যাওয়া ($count)'
        : (s.code == 'hi' ? 'छूटी हुई ($count)' : 'Missed ($count)');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MissedMedicinesSheet.show(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDoseSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<ScheduledDose> doses,
    required AppStrings s,
    bool isCompletedSection = false,
    bool isViewingToday = true,
  }) {
    final provider = context.read<MedicineProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countLabel = doses.length == 1
        ? (s.code == 'bn' ? '১টি ওষুধ' : '1 medicine')
        : (s.code == 'bn' ? '${doses.length}টি ওষুধ' : '${doses.length} medicines');

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.38),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: isDark ? 0.25 : 0.14),
                      color.withValues(alpha: isDark ? 0.12 : 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  countLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final dose = doses[index];
              final isActionable = _isDoseActionable(dose, isViewingToday);
              return DoseCard(
                dose: dose,
                isActionable: isActionable,
                onTake: () {
                  provider.markAsTaken(dose.medicine, dose.reminder, dose.scheduledDate);
                },
                onSkip: () {
                  provider.markAsSkipped(dose.medicine, dose.reminder, dose.scheduledDate);
                },
                onSnooze: () {
                  provider.snoozeDose(dose.medicine, dose.reminder, minutes: 10);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.snoozedMessage(dose.medicine.name, 10)),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            childCount: doses.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildPrescriptionRoutineBar({
    required int morningCount,
    required int afternoonCount,
    required int eveningCount,
    required int nightCount,
    required bool isDark,
    required AppStrings s,
  }) {
    final liveSlot = currentLiveTimeSlot;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Routine Pill: 💊 1-0-0-1 (Tap to reset filter)
            InkWell(
              onTap: () {
                if (_selectedSlotFilter != null) {
                  setState(() => _selectedSlotFilter = null);
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '$morningCount-$afternoonCount-$eveningCount-$nightCount',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Right: 4 Slot Chips with Connectors
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoutineSlotChip(
                    emoji: '🌅',
                    label: s.code == 'bn' ? 'সকাল' : 'Morn',
                    count: morningCount,
                    slot: TimeSlot.morning,
                    isLive: liveSlot == TimeSlot.morning,
                    isSelected: _selectedSlotFilter == TimeSlot.morning,
                    isDark: isDark,
                  ),
                  _buildRoutineConnector(isDark),
                  _buildRoutineSlotChip(
                    emoji: '☀️',
                    label: s.code == 'bn' ? 'দুপুর' : 'Noon',
                    count: afternoonCount,
                    slot: TimeSlot.afternoon,
                    isLive: liveSlot == TimeSlot.afternoon,
                    isSelected: _selectedSlotFilter == TimeSlot.afternoon,
                    isDark: isDark,
                  ),
                  _buildRoutineConnector(isDark),
                  _buildRoutineSlotChip(
                    emoji: '☕',
                    label: s.code == 'bn' ? 'সন্ধ্যা' : 'Eve',
                    count: eveningCount,
                    slot: TimeSlot.evening,
                    isLive: liveSlot == TimeSlot.evening,
                    isSelected: _selectedSlotFilter == TimeSlot.evening,
                    isDark: isDark,
                  ),
                  _buildRoutineConnector(isDark),
                  _buildRoutineSlotChip(
                    emoji: '🌙',
                    label: s.code == 'bn' ? 'রাত' : 'Night',
                    count: nightCount,
                    slot: TimeSlot.night,
                    isLive: liveSlot == TimeSlot.night,
                    isSelected: _selectedSlotFilter == TimeSlot.night,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineConnector(bool isDark) {
    return Container(
      width: 5,
      height: 1.5,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildRoutineSlotChip({
    required String emoji,
    required String label,
    required int count,
    required TimeSlot slot,
    required bool isLive,
    required bool isSelected,
    required bool isDark,
  }) {
    return Tooltip(
      message: '$label: $count',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSlotFilter = _selectedSlotFilter == slot ? null : slot;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF4F46E5).withValues(alpha: 0.35) : const Color(0xFFEEF2FF))
                : isLive
                    ? (isDark ? const Color(0xFF0D9488).withValues(alpha: 0.22) : const Color(0xFFF0FDFA))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : isLive
                      ? const Color(0xFF0D9488).withValues(alpha: 0.45)
                      : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 11.5)),
              const SizedBox(width: 3),
              Text(
                count.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: count > 0 ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : isLive
                          ? const Color(0xFF0D9488)
                          : (count > 0
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 3,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

