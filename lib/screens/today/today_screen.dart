import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/calendar_timeline_bar.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/dual_tone_capsule.dart';
import '../../widgets/empty_medicines_view.dart';
import '../medicines/add_edit_medicine_screen.dart';
import '../medicines/medicines_cabinet_screen.dart';
import '../notifications/notifications_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

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

    final userName = activeProfile != null
        ? (activeProfile.id == 'default_me' || activeProfile.name.toLowerCase() == 'myself' ? 'Kadir' : activeProfile.name)
        : 'Kadir';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Profile Header (Screen 07: Good Morning, Kadir + Bell icon)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: Color(0xFF2563EB), size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good Morning,',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '$userName 👋',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, size: 26),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Health Motivation Banner (Screen 07: Take care today for a healthier tomorrow)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF047857) : const Color(0xFFC8E6C9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Take care today\nfor a healthier\ntomorrow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            child: const Icon(Icons.eco_rounded, color: Color(0xFF10B981), size: 22),
                          ),
                          const SizedBox(width: 8),
                          DualToneCapsule.paracetamol(size: 42),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Calendar Timeline Strip
            SliverToBoxAdapter(
              child: CalendarTimelineBar(
                selectedDate: provider.selectedDate,
                onDateSelected: (date) => provider.selectDate(date),
              ),
            ),

            // Today's Medicines Header + View All
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MedicinesCabinetScreen()),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // If empty, show motivational EmptyMedicinesView (Screen 18)
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

            // Time Slots
            if (morningDoses.isNotEmpty)
              ..._buildTimeSlotSection(context, TimeSlot.morning, morningDoses, s),

            if (afternoonDoses.isNotEmpty)
              ..._buildTimeSlotSection(context, TimeSlot.afternoon, afternoonDoses, s),

            if (eveningDoses.isNotEmpty)
              ..._buildTimeSlotSection(context, TimeSlot.evening, eveningDoses, s),

            if (nightDoses.isNotEmpty)
              ..._buildTimeSlotSection(context, TimeSlot.night, nightDoses, s),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeSlotSection(
    BuildContext context,
    TimeSlot slot,
    List<ScheduledDose> doses,
    AppStrings s,
  ) {
    final provider = context.read<MedicineProvider>();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: slot.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(slot.icon, size: 16, color: slot.color),
              ),
              const SizedBox(width: 10),
              Text(
                _getTimeSlotTitle(slot, s),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '(${doses.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextMuted),
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
                    ),
                  );
                },
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
            },
            childCount: doses.length,
          ),
        ),
      ),
    ];
  }
}
