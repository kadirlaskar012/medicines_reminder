import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/database/db_helper.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import '../models/reminder_time.dart';
import '../providers/medicine_provider.dart';
import 'today/today_screen.dart';
import 'medicines/medicines_cabinet_screen.dart';
import 'medicines/add_edit_medicine_screen.dart';
import 'reports/reports_analytics_screen.dart';
import 'settings/settings_screen.dart';
import 'alarm/alarm_ringing_screen.dart';
import '../providers/language_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    MedicinesCabinetScreen(),
    ReportsAnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.requestPermissions();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Silently reload medicine data so any dose recorded in background is immediately updated without spinner
      context.read<MedicineProvider>().reloadDataSilently();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  void _setupNotificationHandler() {
    NotificationService.instance.onNotificationAction = (payload, actionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processNotificationAction(payload, actionId);
      });
    };
  }

  Future<void> _processNotificationAction(String payload, String? actionId) async {
    if (!mounted || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicineId = data['medicineId'] as String?;
      final reminderId = data['reminderTimeId'] as String?;
      final medicineName = data['medicineName'] as String? ?? 'Medicine';
      final dosage = data['dosage'] as String? ?? '';
      final notifId = data['notificationId'] as int?;

      // Immediately dismiss notification from tray
      if (notifId != null) {
        await NotificationService.instance.cancelNotificationId(notifId);
      }
      if (!mounted) return;

      final provider = context.read<MedicineProvider>();

      // Ensure data is loaded
      int retries = 0;
      while (provider.isLoading && mounted && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
      if (!mounted) return;

      Medicine? resolvedMed;
      if (medicineId != null) {
        try {
          resolvedMed = provider.medicines.firstWhere((m) => m.id == medicineId);
        } catch (_) {}
      }
      if (resolvedMed == null) {
        try {
          resolvedMed = provider.medicines.firstWhere(
            (m) => m.name.toLowerCase() == medicineName.toLowerCase(),
          );
        } catch (_) {}
      }
      if (resolvedMed == null && medicineId != null) {
        resolvedMed = await DBHelper.instance.getMedicineById(medicineId);
      }
      final typeStr = data['medicineType'] as String? ?? 'tablet';
      final colorVal = data['colorValue'] as int? ?? 0xFF0D9488;
      final photoPath = data['photoPath'] as String?;
      final medType = MedicineType.fromString(typeStr);

      final med = resolvedMed ??
          Medicine(
            id: medicineId ?? 'dose_${DateTime.now().millisecondsSinceEpoch}',
            profileId: 'default_me',
            name: medicineName,
            dosage: dosage,
            type: medType,
            colorValue: colorVal,
            photoPath: photoPath,
            instruction: FoodInstruction.afterMeal,
            createdAt: DateTime.now(),
          );

      ReminderTime? resolvedRem;
      final reminders = provider.getRemindersForMedicine(med.id);
      if (reminderId != null) {
        try {
          resolvedRem = reminders.firstWhere((r) => r.id == reminderId);
        } catch (_) {}
      }
      if (resolvedRem == null && reminders.isNotEmpty) {
        resolvedRem = reminders.first;
      }
      if (resolvedRem == null && reminderId != null) {
        resolvedRem = await DBHelper.instance.getReminderById(reminderId);
      }
      final rem = resolvedRem ??
          ReminderTime(
            id: reminderId ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
            medicineId: med.id,
            hour: DateTime.now().hour,
            minute: DateTime.now().minute,
            daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
            notificationId: notifId ?? 1001,
          );

      // Dismiss any lingering active notification for this reminder
      await NotificationService.instance.dismissActiveReminderNotification(
        reminder: rem,
        notificationId: notifId,
      );

      final dayOfWeek = data['dayOfWeek'] as int? ?? DateTime.now().weekday;
      final now = DateTime.now();
      final int daysDiff = (now.weekday - dayOfWeek + 7) % 7;
      final targetDate = now.subtract(Duration(days: daysDiff));

      if (actionId == NotificationService.actionTaken) {
        await provider.markAsTaken(med, rem, targetDate);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF059669),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dose Confirmed Taken! 🎉',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        '${med.name} ($dosage) recorded successfully.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (actionId == NotificationService.actionSnooze) {
        await provider.snoozeDose(med, rem, minutes: 10);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFD97706),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.snooze_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dose Snoozed ⏰',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        '${med.name} will alert you again in 10 minutes.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (actionId == NotificationService.actionSkip) {
        await provider.markAsSkipped(med, rem, targetDate);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF475569),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dose Skipped ⏭️',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      Text(
                        '${med.name} marked as skipped for today.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _currentIndex = 0;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlarmRingingScreen(
              medicine: med,
              reminder: rem,
              notificationId: notifId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final s = lang.strings;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1728) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 14,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.glossySheenDark
                        : AppColors.glossySheenLight,
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: SizedBox(
                height: 76,
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_today_rounded,
                      label: s.todayTab,
                      activeColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.medication_outlined,
                      activeIcon: Icons.medication_rounded,
                      label: s.medicinesTab,
                      activeColor: isDark ? const Color(0xFF34D399) : const Color(0xFF0D9488),
                      isDark: isDark,
                    ),
                    _buildCenterFab(isDark),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      label: s.code == 'bn' ? 'রিপোর্ট' : (s.code == 'hi' ? 'रिपोर्ट' : 'Reports'),
                      activeColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: s.settingsTab,
                      activeColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(
                        color: activeColor.withValues(alpha: isDark ? 0.35 : 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isSelected ? 5 : 0,
              height: isSelected ? 5 : 0,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
            );
          },
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0D9488), // Rich Teal
                  Color(0xFF06B6D4), // Vibrant Cyan
                  Color(0xFF3B82F6), // Electric Sky Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
