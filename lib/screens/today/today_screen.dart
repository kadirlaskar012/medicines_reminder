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
import '../../widgets/rotary_time_slot_carousel.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  TimeSlot? _selectedSlotFilter; // null = All
  Timer? _autoSkipTimer;

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
    final liveSlot = RotaryTimeSlotCarousel.currentLiveTimeSlot;
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
      } else {
        pendingDoses.add(d);
      }
    }

    pendingDoses.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    completedDoses.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    final userName = activeProfile != null
        ? (activeProfile.id == 'default_me' || activeProfile.name.toLowerCase() == 'myself' ? 'Kadir Laskar' : activeProfile.name)
        : 'Kadir Laskar';

    final now = DateTime.now();
    final isViewingToday = DateUtils.isSameDay(provider.selectedDate, now);

    final hasAlerts = provider.dosesForSelectedDate.any(
      (d) => d.isOverdue || (!d.isTaken && !d.isSkipped && d.scheduledDate.isBefore(now)),
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
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

            // Rotary Time Slot Carousel & All Doses Master Filter
            SliverToBoxAdapter(
              child: RotaryTimeSlotCarousel(
                selectedSlot: _selectedSlotFilter,
                totalDosesCount: totalDoses,
                doseCounts: {
                  TimeSlot.morning: morningDoses.length,
                  TimeSlot.afternoon: afternoonDoses.length,
                  TimeSlot.evening: eveningDoses.length,
                  TimeSlot.night: nightDoses.length,
                },
                onSlotChanged: (slot) {
                  setState(() => _selectedSlotFilter = slot);
                },
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


            // Dose Lists: Smart Priority Rendering
            // Dose Lists: Smart Priority Direct Rendering
            // 1. Pending doses (actionable or scheduled) rendered directly without duplicate header
            if (pendingDoses.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dose = pendingDoses[index];
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
                    childCount: pendingDoses.length,
                  ),
                ),
              ),

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
}

