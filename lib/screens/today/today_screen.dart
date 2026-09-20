import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final minute = DateTime.now().minute;
    final totalMinutes = hour * 60 + minute;
    if (totalMinutes >= 300 && totalMinutes < 720) return TimeSlot.morning;
    if (totalMinutes >= 720 && totalMinutes < 930) return TimeSlot.lunch;
    if (totalMinutes >= 930 && totalMinutes < 1080) return TimeSlot.afternoon;
    if (totalMinutes >= 1080 && totalMinutes < 1230) return TimeSlot.evening;
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
      case TimeSlot.lunch:
        return s.lunchSlot;
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

  Widget _buildLoadingSkeleton(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Profile Pill Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 150,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Adherence Ring / Hero Banner Skeleton
              Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),
              // Section Header Skeleton
              Container(
                width: 140,
                height: 20,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 14),
              // Dose Cards Skeleton
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final s = context.watch<LanguageProvider>().strings;
    final activeProfile = provider.activeProfile;

    if (provider.isLoading && provider.medicines.isEmpty) {
      return _buildLoadingSkeleton(isDark);
    }

    final morningDoses = provider.morningDoses;
    final lunchDoses = provider.lunchDoses;
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

    final missedDoses = provider.missedDoses;

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

    final effectiveSlot = _selectedSlotFilter ?? currentLiveTimeSlot;
    final currentSlotDoses = visibleDoses.where((d) => d.reminder.timeSlot == effectiveSlot).toList();
    final currentSlotTaken = currentSlotDoses.where((d) => d.isTaken).length;
    final currentSlotSkipped = currentSlotDoses.where((d) => d.isSkipped).length;

    completedDoses.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    final userName = activeProfile != null
        ? (activeProfile.id == 'default_me' || activeProfile.name.toLowerCase() == 'myself' ? 'Kadir Laskar' : activeProfile.name)
        : 'Kadir Laskar';

    final hasAlerts = provider.hasUnreadNotificationAlerts;

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

                    // Right Action (Bell)
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            context.read<MedicineProvider>().markNotificationHubAsRead();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                            if (context.mounted) {
                              context.read<MedicineProvider>().markNotificationHubAsRead();
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

            // Sleek Daily Prescription Routine Bar (1 - 0 - 0 - 0 - 1)
            SliverToBoxAdapter(
              child: _buildPrescriptionRoutineBar(
                morningCount: morningDoses.length,
                lunchCount: lunchDoses.length,
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
            if (currentOrDueDoses.isNotEmpty) ...[
              if (isViewingToday && (currentSlotTaken > 0 || currentSlotSkipped > 0))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(effectiveSlot.icon, size: 15, color: effectiveSlot.color),
                              const SizedBox(width: 7),
                              Text(
                                s.code == 'bn' ? _getTimeSlotTitle(effectiveSlot, s) : effectiveSlot.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (currentSlotTaken > 0) ...[
                                const Icon(Icons.check_rounded, size: 13, color: AppColors.accentEmerald),
                                const SizedBox(width: 3),
                                Text(
                                  '$currentSlotTaken Take',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentEmerald,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (currentSlotSkipped > 0) ...[
                                const Icon(Icons.close_rounded, size: 13, color: AppColors.accentRose),
                                const SizedBox(width: 3),
                                Text(
                                  '$currentSlotSkipped Skip',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentRose,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: effectiveSlot.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.code == 'bn' ? '${currentOrDueDoses.length}টি বাকি' : '${currentOrDueDoses.length} due',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: effectiveSlot.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dose = currentOrDueDoses[index];
                      final isCompleted = dose.isTaken || dose.isSkipped;
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
                        onLongPress: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
                        onStatusTap: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
                      );
                    },
                    childCount: currentOrDueDoses.length,
                  ),
                ),
              ),
            ] else if (isViewingToday && totalDoses > 0) ...[
              _buildCurrentSlotStatusCard(
                context: context,
                slot: effectiveSlot,
                slotDoses: currentSlotDoses,
                hasUpcoming: upcomingDoses.isNotEmpty,
                isDark: isDark,
                s: s,
              ),
            ],

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
                      final isCompleted = dose.isTaken || dose.isSkipped;
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
                        onLongPress: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
                        onStatusTap: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
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
        ? 'ছুটে যাওয়া'
        : (s.code == 'hi' ? 'छूटी हुई' : 'Missed');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MissedMedicinesSheet.show(context),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
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
              const SizedBox(width: 8),
              // Dedicated Count Badge Number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE11D48),
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
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

  Widget _buildCurrentSlotStatusCard({
    required BuildContext context,
    required TimeSlot slot,
    required List<ScheduledDose> slotDoses,
    required bool hasUpcoming,
    required bool isDark,
    required AppStrings s,
  }) {
    final takenCount = slotDoses.where((d) => d.isTaken).length;
    final skippedCount = slotDoses.where((d) => d.isSkipped).length;
    final totalCount = slotDoses.length;

    // Slot Title localized
    String slotHeading;
    if (s.code == 'bn') {
      switch (slot) {
        case TimeSlot.morning:
          slotHeading = 'সকালের ওষুধ';
          break;
        case TimeSlot.lunch:
          slotHeading = 'দুপুরের ওষুধ';
          break;
        case TimeSlot.afternoon:
          slotHeading = 'বিকেলের ওষুধ';
          break;
        case TimeSlot.evening:
          slotHeading = 'সন্ধ্যার ওষুধ';
          break;
        case TimeSlot.night:
          slotHeading = 'রাতের ওষুধ';
          break;
      }
    } else if (s.code == 'hi') {
      slotHeading = '${_getTimeSlotTitle(slot, s)} की दवाएं';
    } else {
      slotHeading = '${slot.title} Medicines';
    }

    if (totalCount == 0) {
      if (!hasUpcoming) return const SliverToBoxAdapter(child: SizedBox.shrink());
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        slot.color.withValues(alpha: isDark ? 0.25 : 0.15),
                        slot.color.withValues(alpha: isDark ? 0.15 : 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: slot.color.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(slot.icon, color: slot.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slotHeading,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.code == 'bn'
                            ? 'এই সময়ে কোনো ওষুধ নির্ধারিত নেই'
                            : 'No medicines scheduled for this time',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allCompleted = (takenCount + skippedCount == totalCount);
    if (!allCompleted) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      slot.color.withValues(alpha: 0.15),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      slot.color.withValues(alpha: 0.08),
                      Colors.white,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: slot.color.withValues(alpha: isDark ? 0.4 : 0.3),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: slot.color.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Slot Icon + Title + Status Icon
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          slot.color.withValues(alpha: isDark ? 0.35 : 0.2),
                          slot.color.withValues(alpha: isDark ? 0.2 : 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: slot.color.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(slot.icon, color: slot.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              slotHeading,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (takenCount > 0 ? AppColors.accentEmerald : AppColors.accentRose)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.code == 'bn' ? 'সম্পন্ন' : 'Completed',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: takenCount > 0 ? AppColors.accentEmerald : AppColors.accentRose,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.code == 'bn'
                              ? 'নির্ধারিত সময়: ${slot.timeRange}'
                              : 'Window: ${slot.timeRange}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (takenCount > 0 ? AppColors.accentEmerald : const Color(0xFFF43F5E))
                          .withValues(alpha: isDark ? 0.25 : 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (takenCount > 0 ? AppColors.accentEmerald : const Color(0xFFF43F5E))
                            .withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        takenCount > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: takenCount > 0 ? AppColors.accentEmerald : const Color(0xFFF43F5E),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Badges Row: Take & Skip count (Matching User Request Exactly)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (takenCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF064E3B).withValues(alpha: 0.7), const Color(0xFF022C22).withValues(alpha: 0.8)]
                              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.45 : 0.38),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          Text(
                            skippedCount == 0
                                ? (s.code == 'bn' ? 'Take $takenCount' : 'Take $takenCount')
                                : '$takenCount Take',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (skippedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF4C0519).withValues(alpha: 0.7), const Color(0xFF28020D).withValues(alpha: 0.8)]
                              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.45 : 0.38),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.2 : 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded, size: 15, color: Color(0xFFF43F5E)),
                          const SizedBox(width: 5),
                          Text(
                            takenCount == 0
                                ? (s.code == 'bn' ? 'Skip $skippedCount' : 'Skip $skippedCount')
                                : '$skippedCount Skip',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFB7185) : const Color(0xFF9F1239),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (hasUpcoming) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.south_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        s.code == 'bn'
                            ? 'পরবর্তী ওষুধ নিচে দেখুন (নির্ধারিত সময়ে সক্রিয় হবে)'
                            : 'Upcoming medicines will activate below at due time',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
              final isCompleted = dose.isTaken || dose.isSkipped;
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
                onLongPress: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
                onStatusTap: isCompleted ? () => _showDoseStatusCorrectionSheet(context, dose) : null,
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
    required int lunchCount,
    required int afternoonCount,
    required int eveningCount,
    required int nightCount,
    required bool isDark,
    required AppStrings s,
  }) {
    final liveSlot = currentLiveTimeSlot;
    final routinePattern = lunchCount > 0
        ? '$morningCount-$lunchCount-$afternoonCount-$eveningCount-$nightCount'
        : '$morningCount-$afternoonCount-$eveningCount-$nightCount';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
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
                    const Text('💊', style: TextStyle(fontSize: 10.5)),
                    const SizedBox(width: 3),
                    Text(
                      routinePattern,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Right: 5 Slot Chips with Connectors
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
                    emoji: '🍽️',
                    label: s.code == 'bn' ? 'দুপুর' : 'Lunch',
                    count: lunchCount,
                    slot: TimeSlot.lunch,
                    isLive: liveSlot == TimeSlot.lunch,
                    isSelected: _selectedSlotFilter == TimeSlot.lunch,
                    isDark: isDark,
                  ),
                  _buildRoutineConnector(isDark),
                  _buildRoutineSlotChip(
                    emoji: '☀️',
                    label: s.code == 'bn' ? 'বিকাল' : 'Aft',
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

  void _showDoseStatusCorrectionSheet(BuildContext context, ScheduledDose dose) {
    final s = context.read<LanguageProvider>().strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTaken = dose.isTaken;
    final isSkipped = dose.isSkipped;
    final med = dose.medicine;
    final rem = dose.reminder;
    final provider = context.read<MedicineProvider>();
    final isViewingToday = DateUtils.isSameDay(provider.selectedDate, DateTime.now());
    final isCurrentSlot = isViewingToday && (dose.reminder.timeSlot == currentLiveTimeSlot);

    // Subtle tactile feedback on trigger
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header with icon
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isTaken
                              ? [const Color(0xFFEA580C), const Color(0xFFF59E0B)]
                              : [const Color(0xFF0D9488), const Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isTaken ? const Color(0xFFEA580C) : const Color(0xFF0D9488)).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.published_with_changes_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.changeStatusTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.changeStatusSub,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Medicine preview badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('💊', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '${med.dosage.isNotEmpty ? '${med.dosage} • ' : ''}${DateFormat('h:mm a').format(DateTime(2026, 1, 1, rem.hour, rem.minute))}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Current status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isTaken
                              ? AppColors.accentEmerald.withValues(alpha: isDark ? 0.25 : 0.12)
                              : AppColors.accentRose.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 13,
                              color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTaken ? s.taken : (s.code == 'bn' ? 'স্কিপড' : 'Skipped'),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isTaken ? AppColors.accentEmerald : AppColors.accentRose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Primary Alternate Option Button
                if (isTaken) ...[
                  _buildStatusActionButton(
                    context: context,
                    icon: Icons.cancel_rounded,
                    title: s.markAsSkippedOption,
                    subtitle: s.code == 'bn'
                        ? 'ওষুধটি গ্রহণ করা হয়নি, স্কিপ হিসেবে চিহ্নিত করুন'
                        : 'Change status to Skipped and restore 1 stock',
                    color: const Color(0xFFE11D48),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmAndExecuteStatusChange(
                        context: context,
                        dose: dose,
                        actionType: 'skip',
                        title: s.confirmChangeTitle,
                        message: s.confirmSkipMsg(med.name),
                        confirmColor: const Color(0xFFE11D48),
                      );
                    },
                  ),
                ] else if (isSkipped) ...[
                  _buildStatusActionButton(
                    context: context,
                    icon: Icons.check_circle_rounded,
                    title: s.markAsTakenOption,
                    subtitle: s.code == 'bn'
                        ? 'ওষুধটি নেওয়া হয়েছে, সম্পন্ন হিসেবে চিহ্নিত করুন'
                        : 'Change status to Taken and deduct 1 stock',
                    color: const Color(0xFF0D9488),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmAndExecuteStatusChange(
                        context: context,
                        dose: dose,
                        actionType: 'take',
                        title: s.confirmChangeTitle,
                        message: s.confirmTakeMsg(med.name),
                        confirmColor: const Color(0xFF0D9488),
                      );
                    },
                  ),
                ],
                // Reset to Pending Option (Strictly available only for current live session)
                if (isCurrentSlot) ...[
                  const SizedBox(height: 10),
                  _buildStatusActionButton(
                    context: context,
                    icon: Icons.restart_alt_rounded,
                    title: s.resetToPendingOption,
                    subtitle: s.code == 'bn'
                        ? 'স্ট্যাটাস মুছে দিয়ে বর্তমান পেন্ডিং তালিকায় ফিরিয়ে নিন'
                        : 'Clear status and return to current pending schedule',
                    color: const Color(0xFF4F46E5),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmAndExecuteStatusChange(
                        context: context,
                        dose: dose,
                        actionType: 'reset',
                        title: s.confirmChangeTitle,
                        message: s.confirmResetMsg(med.name),
                        confirmColor: const Color(0xFF4F46E5),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      s.cancelBtn,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndExecuteStatusChange({
    required BuildContext context,
    required ScheduledDose dose,
    required String actionType,
    required String title,
    required String message,
    required Color confirmColor,
  }) {
    final s = context.read<LanguageProvider>().strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: confirmColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  actionType == 'take'
                      ? Icons.check_circle_rounded
                      : (actionType == 'skip' ? Icons.cancel_rounded : Icons.restart_alt_rounded),
                  color: confirmColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.4,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                s.cancelBtn,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [confirmColor, confirmColor.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: confirmColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final provider = context.read<MedicineProvider>();
                  if (actionType == 'take') {
                    await provider.markAsTaken(dose.medicine, dose.reminder, dose.scheduledDate);
                  } else if (actionType == 'skip') {
                    await provider.markAsSkipped(dose.medicine, dose.reminder, dose.scheduledDate);
                  } else if (actionType == 'reset') {
                    await provider.resetDoseToPending(dose.medicine, dose.reminder, dose.scheduledDate);
                    if (_selectedSlotFilter != null && _selectedSlotFilter != dose.reminder.timeSlot) {
                      setState(() {
                        _selectedSlotFilter = null;
                      });
                    }
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              actionType == 'take'
                                  ? Icons.check_circle_rounded
                                  : (actionType == 'skip' ? Icons.cancel_rounded : Icons.replay_rounded),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.statusUpdatedMsg,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: confirmColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  s.confirmBtn,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

