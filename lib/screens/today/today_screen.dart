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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        final now = DateTime.now();
        if (!DateUtils.isSameDay(provider.selectedDate, now)) {
          provider.selectDate(now);
        }
      }
    });
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
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 21,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                if (hasAlerts)
                                  Positioned(
                                    top: 10,
                                    right: 11,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentRose,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? AppColors.darkCard : Colors.white,
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accentRose.withValues(alpha: 0.8),
                                            blurRadius: 4,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isViewingToday
                          ? (s.code == 'bn' ? 'আজকের ওষুধ' : 'TODAY\'S DOSES')
                          : (s.code == 'bn'
                              ? '${provider.selectedDate.day} ${DateFormat('MMMM').format(provider.selectedDate)}-এর ওষুধ'
                              : '${DateFormat('MMMM d').format(provider.selectedDate).toUpperCase()}\'S DOSES'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Row(
                      children: [
                        if (!isViewingToday) ...[
                          InkWell(
                            onTap: () => provider.selectDate(now),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.today_rounded, size: 14, color: AppColors.primaryTeal),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.code == 'bn' ? 'আজকে ফিরুন' : 'Today',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
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
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              '${s.medicinesTab} →',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.primaryTealLight : AppColors.primaryTeal,
                              ),
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
            if (_selectedSlotFilter == null) ...[
              // Master "All Doses" View:
              // 1. Upcoming & Due Now Doses (urgency sorted, topmost)
              if (pendingDoses.isNotEmpty)
                ..._buildDoseSection(
                  context,
                  title: s.code == 'bn' ? 'আসন্ন ও প্রয়োজনীয় ওষুধ' : 'Upcoming & Due Doses',
                  icon: Icons.access_time_filled_rounded,
                  color: AppColors.primaryTeal,
                  doses: pendingDoses,
                  s: s,
                ),

              // 2. Completed Doses (taken / skipped)
              if (completedDoses.isNotEmpty)
                ..._buildDoseSection(
                  context,
                  title: s.code == 'bn' ? 'আজকের সম্পন্ন ওষুধ' : 'Completed Today',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.accentEmerald,
                  doses: completedDoses,
                  s: s,
                  isCompletedSection: true,
                ),
            ] else ...[
              // Slot Filtered View:
              if (pendingDoses.isNotEmpty)
                ..._buildDoseSection(
                  context,
                  title: s.code == 'bn'
                      ? '${_getTimeSlotTitle(_selectedSlotFilter!, s)} - আসন্ন ও করণীয়'
                      : '${_getTimeSlotTitle(_selectedSlotFilter!, s)} - Upcoming',
                  icon: _selectedSlotFilter!.icon,
                  color: _selectedSlotFilter!.color,
                  doses: pendingDoses,
                  s: s,
                ),

              if (completedDoses.isNotEmpty)
                ..._buildDoseSection(
                  context,
                  title: s.code == 'bn'
                      ? '${_getTimeSlotTitle(_selectedSlotFilter!, s)} - সম্পন্ন'
                      : '${_getTimeSlotTitle(_selectedSlotFilter!, s)} - Completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.accentEmerald,
                  doses: completedDoses,
                  s: s,
                  isCompletedSection: true,
                ),

              if (pendingDoses.isEmpty && completedDoses.isEmpty && totalDoses > 0)
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
            ],

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
  }) {
    final provider = context.read<MedicineProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countLabel = doses.length == 1
        ? (s.code == 'bn' ? '১টি ওষুধ' : '1 medicine')
        : (s.code == 'bn' ? '${doses.length}টি ওষুধ' : '${doses.length} medicines');

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  countLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
              return DoseCard(
                dose: dose,
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

