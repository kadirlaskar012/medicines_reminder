import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import '../models/reminder_time.dart';
import '../providers/auth_provider.dart';
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
  Timer? _sessionValidationTimer;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCloudSession();
      // Periodically check if account was deleted by admin (every 25 seconds while app is in foreground)
      _sessionValidationTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _checkCloudSession();
      });
    });
  }

  void _checkCloudSession() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isSignedIn) {
      auth.validateSessionWithCloud();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCloudSession();
      // Reload medicine data so any dose recorded in the background is immediately updated in the UI
      context.read<MedicineProvider>().loadInitialData();
    }
  }

  @override
  void dispose() {
    _sessionValidationTimer?.cancel();
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
      if (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
      }

      final med = provider.medicines.firstWhere(
        (m) => m.id == medicineId || m.name.toLowerCase() == medicineName.toLowerCase(),
        orElse: () => Medicine(
          id: medicineId ?? 'dose_${DateTime.now().millisecondsSinceEpoch}',
          profileId: 'default_me',
          name: medicineName,
          dosage: dosage,
          type: MedicineType.tablet,
          colorValue: 0xFF0D9488,
          instruction: FoodInstruction.afterMeal,
          createdAt: DateTime.now(),
        ),
      );

      final reminders = provider.getRemindersForMedicine(med.id);
      final rem = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => reminders.isNotEmpty
            ? reminders.first
            : ReminderTime(
                id: reminderId ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
                medicineId: med.id,
                hour: DateTime.now().hour,
                minute: DateTime.now().minute,
                daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
                notificationId: 1001,
              ),
      );

      // Dismiss any lingering active notification for this reminder
      await NotificationService.instance.dismissActiveReminderNotification(
        reminder: rem,
        notificationId: notifId,
      );

      if (actionId == NotificationService.actionTaken) {
        await provider.markAsTaken(med, rem, DateTime.now());
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
                        '${med.name} ($dosage) recorded in your daily streak.',
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
        await provider.markAsSkipped(med, rem, DateTime.now());
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
        // Tapped notification card -> Navigate to full Alarm Ringing Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlarmRingingScreen(medicine: med, reminder: rem),
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
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.8),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
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
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.medication_outlined,
                      activeIcon: Icons.medication_rounded,
                      label: s.medicinesTab,
                      isDark: isDark,
                    ),
                    _buildCenterFab(isDark),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart_rounded,
                      label: s.code == 'bn' ? 'রিপোর্ট' : (s.code == 'hi' ? 'रिपोर्ट' : 'Reports'),
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: s.settingsTab,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? AppColors.primaryTealLight : AppColors.primaryTeal;
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: isDark ? 0.2 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
