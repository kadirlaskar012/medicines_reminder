import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../models/medicine.dart';
import '../models/reminder_time.dart';
import '../providers/medicine_provider.dart';
import 'today/today_screen.dart';
import 'medicines/medicines_cabinet_screen.dart';
import 'medicines/add_edit_medicine_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';
import 'alarm/alarm_ringing_screen.dart';
import '../providers/language_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    MedicinesCabinetScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationHandler();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 68,
        elevation: 10,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today_rounded, color: AppColors.primary),
            label: s.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication_rounded, color: AppColors.primary),
            label: s.tabCabinet,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded, color: AppColors.primary),
            label: s.tabHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            label: s.tabSettings,
          ),
        ],
      ),
    );
  }
}
