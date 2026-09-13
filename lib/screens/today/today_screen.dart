import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../models/reminder_time.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/adherence_ring.dart';
import '../../widgets/calendar_timeline_bar.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/profile_selector_sheet.dart';
import '../medicines/add_edit_medicine_screen.dart';

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

  Widget _buildCareCircleChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? avatarSvg,
    Widget? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : const Color(0xFFF0FDF4)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFBBF7D0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatarSvg != null)
              AppSvgIcons.render(avatarSvg, width: 20, height: 20)
            else
              ?icon,

            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : const Color(0xFF065F46)),
              ),
            ),
          ],
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

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final morningDoses = provider.morningDoses;
    final afternoonDoses = provider.afternoonDoses;
    final eveningDoses = provider.eveningDoses;
    final nightDoses = provider.nightDoses;
    final totalDoses = provider.dosesForSelectedDate.length;
    final completedDoses = provider.todayTakenCount;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar / Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.formatHeaderDate(provider.selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.dailySchedule,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    // Quick Adherence Score Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            completedDoses == totalDoses && totalDoses > 0
                                ? Icons.verified_rounded
                                : Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalDoses > 0 ? '$completedDoses / $totalDoses' : '0',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Care Circle Horizontal Switcher Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 42,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildCareCircleChip(
                          context,
                          label: s.allFamily,
                          isSelected: activeProfile == null,
                          onTap: () => provider.switchProfile(null),
                          icon: Icon(
                            Icons.people_alt_rounded,
                            size: 17,
                            color: activeProfile == null ? Colors.white : AppColors.primary,
                          ),
                        ),
                        ...provider.profiles.map((p) {
                          final isSelected = activeProfile?.id == p.id;
                          final pName = (p.id == 'default_me' || p.name.toLowerCase() == 'myself') ? s.myself : p.name;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildCareCircleChip(
                              context,
                              label: pName,
                              isSelected: isSelected,
                              onTap: () => provider.switchProfile(p),
                              avatarSvg: p.svgAvatar,
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            avatar: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                            label: Text(s.addMember, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
                            side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFBBF7D0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onPressed: () => ProfileSelectorSheet.show(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),



            // Adherence Progress Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: AdherenceRing(
                  rate: provider.todayAdherenceRate,
                  takenCount: provider.todayTakenCount,
                  totalCount: provider.todayTotalCount,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Calendar Timeline Strip
            SliverToBoxAdapter(
              child: CalendarTimelineBar(
                selectedDate: provider.selectedDate,
                onDateSelected: (date) => provider.selectDate(date),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 100% Adherence Celebration Banner
            if (totalDoses > 0 && completedDoses == totalDoses)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                            : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.6 : 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F766E) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🎉', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.allDosesCompletedTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.allDosesCompletedSub,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // If empty, show motivational empty state
            if (totalDoses == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle_outline_rounded, size: 44, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.noDosesScheduled,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.tapToAddFirst,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(s.addMedicine),
                        ),
                      ],
                    ),
                  ),
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
