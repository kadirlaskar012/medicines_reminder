import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../models/scheduled_dose.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../medicines/add_edit_medicine_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all'; // all, action, upcoming, stock, completed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>().languageCode;
    final medProvider = context.watch<MedicineProvider>();

    final now = DateTime.now();
    final todayDoses = medProvider.dosesForSelectedDate;
    final lowStockMeds = medProvider.lowStockMedicines;

    // Categorize today's doses
    final overdueDoses = todayDoses.where((d) => d.isOverdue).toList();
    final upcomingDoses = todayDoses.where((d) {
      if (d.isTaken || d.isSkipped) return false;
      final doseTime = DateTime(now.year, now.month, now.day, d.reminder.hour, d.reminder.minute);
      return doseTime.isAfter(now);
    }).toList();
    final completedDoses = todayDoses.where((d) => d.isTaken).toList();

    final totalAlerts = overdueDoses.length + lowStockMeds.length + upcomingDoses.length;
    final adherenceRate = medProvider.todayAdherenceRate;
    final adherencePercent = (adherenceRate * 100).toInt();

    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang == 'bn' ? 'বিজ্ঞপ্তি ও অ্যাক্টিভিটি' : 'Notifications & Hub',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
            if (totalAlerts > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalAlerts',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          // Live Test Alarm Button
          IconButton(
            tooltip: lang == 'bn' ? 'টেস্ট নোটিফিকেশন পাঠান' : 'Test Live Notification',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
            ),
            onPressed: () async {
              await NotificationService.instance.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentMint, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang == 'bn'
                                ? 'লকস্ক্রিন ও সিস্টেম নোটিফিকেশন টেস্ট পাঠানো হয়েছে!'
                                : 'Live test notification triggered on your phone!',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HERO ADHERENCE & STREAK CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: _buildHeroAdherenceCard(
                context,
                isDark: isDark,
                lang: lang,
                adherencePercent: adherencePercent,
                takenCount: medProvider.todayTakenCount,
                totalCount: medProvider.todayTotalCount,
                textPrimary: textPrimary,
              ),
            ),
          ),

          // 2. FILTER PILLS
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  _buildFilterPill(
                    label: lang == 'bn' ? 'সকল' : 'All',
                    count: totalAlerts + completedDoses.length,
                    filterKey: 'all',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: lang == 'bn' ? 'অ্যাকশন চাই' : 'Action Needed',
                    count: overdueDoses.length,
                    filterKey: 'action',
                    isDark: isDark,
                    badgeColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: lang == 'bn' ? 'আসন্ন' : 'Upcoming',
                    count: upcomingDoses.length,
                    filterKey: 'upcoming',
                    isDark: isDark,
                    badgeColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: lang == 'bn' ? 'স্টক এলার্ট' : 'Stock Alert',
                    count: lowStockMeds.length,
                    filterKey: 'stock',
                    isDark: isDark,
                    badgeColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterPill(
                    label: lang == 'bn' ? 'নেওয়া ওষুধ' : 'Completed',
                    count: completedDoses.length,
                    filterKey: 'completed',
                    isDark: isDark,
                    badgeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ),

          // 3. NOTIFICATION LIST CONTENT
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            sliver: _buildNotificationItems(
              context,
              medProvider: medProvider,
              isDark: isDark,
              lang: lang,
              overdueDoses: overdueDoses,
              upcomingDoses: upcomingDoses,
              lowStockMeds: lowStockMeds,
              completedDoses: completedDoses,
              textPrimary: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HERO ADHERENCE & STREAK CARD ====================
  Widget _buildHeroAdherenceCard(
    BuildContext context, {
    required bool isDark,
    required String lang,
    required int adherencePercent,
    required int takenCount,
    required int totalCount,
    required Color textPrimary,
  }) {
    final progress = totalCount > 0 ? (takenCount / totalCount).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF0FDF4)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Circular Adherence Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    adherencePercent >= 80
                        ? const Color(0xFF10B981)
                        : (adherencePercent >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$adherencePercent%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Title & Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'bn' ? 'আজকের ওষুধ নিয়মনিষ্ঠা' : "Today's Dose Adherence",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang == 'bn'
                      ? '$totalCount টি ডোজের মধ্যে $takenCount টি সম্পূর্ণ'
                      : '$takenCount of $totalCount doses completed',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                // Streak Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        lang == 'bn' ? 'ধারাবাহিকতা: ৭ দিন চালু' : '7-Day Streak Active',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILTER PILL ====================
  Widget _buildFilterPill({
    required String label,
    required int count,
    required String filterKey,
    required bool isDark,
    Color? badgeColor,
  }) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextMuted : const Color(0xFF475569)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? const Color(0xFF64748B)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (badgeColor ?? const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== NOTIFICATION ITEMS LIST ====================
  Widget _buildNotificationItems(
    BuildContext context, {
    required MedicineProvider medProvider,
    required bool isDark,
    required String lang,
    required List<ScheduledDose> overdueDoses,
    required List<ScheduledDose> upcomingDoses,
    required List<Medicine> lowStockMeds,
    required List<ScheduledDose> completedDoses,
    required Color textPrimary,
  }) {
    final List<Widget> items = [];

    // 1. Overdue / Action Needed Cards
    if (_selectedFilter == 'all' || _selectedFilter == 'action') {
      for (final dose in overdueDoses) {
        items.add(_buildOverdueCard(context, dose, medProvider, isDark: isDark, lang: lang, textPrimary: textPrimary));
      }
    }

    // 2. Low Stock Alerts
    if (_selectedFilter == 'all' || _selectedFilter == 'stock') {
      for (final med in lowStockMeds) {
        items.add(_buildStockAlertCard(context, med, isDark: isDark, lang: lang, textPrimary: textPrimary));
      }
    }

    // 3. Upcoming Cards
    if (_selectedFilter == 'all' || _selectedFilter == 'upcoming') {
      for (final dose in upcomingDoses) {
        items.add(_buildUpcomingCard(context, dose, isDark: isDark, lang: lang, textPrimary: textPrimary));
      }
    }

    // 4. Completed Cards
    if (_selectedFilter == 'all' || _selectedFilter == 'completed') {
      for (final dose in completedDoses) {
        items.add(_buildCompletedCard(context, dose, isDark: isDark, lang: lang, textPrimary: textPrimary));
      }
    }

    // Empty state
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang == 'bn' ? 'কোন নতুন নোটিফিকেশন নেই' : 'All Caught Up!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == 'bn'
                      ? 'আপনার সব ওষুধের সময়সূচী ঠিকমতো চলছে।'
                      : 'All scheduled medicines and stock alerts are up to date.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: items[index],
          );
        },
        childCount: items.length,
      ),
    );
  }

  // ==================== OVERDUE / ACTION NEEDED CARD ====================
  Widget _buildOverdueCard(
    BuildContext context,
    ScheduledDose dose,
    MedicineProvider medProvider, {
    required bool isDark,
    required String lang,
    required Color textPrimary,
  }) {
    final med = dose.medicine;
    final rem = dose.reminder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 12),

              // Title & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lang == 'bn' ? 'বাকি রয়েছে' : 'OVERDUE',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          rem.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${med.name} • ${med.dosage}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${med.type.label} • ${med.instruction.title}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: [Take Now] and [Snooze 10m]
          Row(
            children: [
              // Take Now Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await medProvider.markAsTaken(dose.medicine, dose.reminder, dose.scheduledDate);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.accentMint, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lang == 'bn'
                                      ? '${med.name} ডোজ সম্পূর্ণ হিসেবে রেকর্ড করা হয়েছে!'
                                      : '${med.name} marked as taken!',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  label: Text(
                    lang == 'bn' ? 'খেয়েছি' : 'Take Now',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Snooze 10m Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await medProvider.snoozeDose(dose.medicine, dose.reminder, minutes: 10);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0F172A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Text(
                            lang == 'bn'
                                ? '১০ মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে!'
                                : 'Snoozed for 10 minutes!',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.schedule_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  label: Text(
                    lang == 'bn' ? '১০ মি. পরে' : 'Snooze 10m',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    elevation: 0,
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UPCOMING CARD ====================
  Widget _buildUpcomingCard(
    BuildContext context,
    ScheduledDose dose, {
    required bool isDark,
    required String lang,
    required Color textPrimary,
  }) {
    final med = dose.medicine;
    final rem = dose.reminder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lang == 'bn' ? 'আসন্ন রিমাইন্ডার' : 'Upcoming Reminder',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rem.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${med.name} (${med.dosage})',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  med.instruction.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STOCK ALERT CARD ====================
  Widget _buildStockAlertCard(
    BuildContext context,
    Medicine med, {
    required bool isDark,
    required String lang,
    required Color textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'bn' ? 'স্টক শেষ এলার্ট' : 'Low Stock Warning',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  med.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang == 'bn'
                      ? 'মাত্র ${med.currentStock} টি ওষুধ অবশিষ্ট আছে।'
                      : 'Only ${med.currentStock} doses left! Refill soon.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditMedicineScreen(medicineToEdit: med),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              lang == 'bn' ? 'রিফিল' : 'Refill',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COMPLETED CARD ====================
  Widget _buildCompletedCard(
    BuildContext context,
    ScheduledDose dose, {
    required bool isDark,
    required String lang,
    required Color textPrimary,
  }) {
    final med = dose.medicine;
    final rem = dose.reminder;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lang == 'bn' ? 'সম্পন্ন ডোজ' : 'Dose Completed',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      rem.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${med.name} (${med.dosage})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang == 'bn' ? 'সফলভাবে নেওয়া হয়েছে' : 'Confirmed taken on time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
