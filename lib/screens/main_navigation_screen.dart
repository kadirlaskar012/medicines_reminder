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
      if (payload.isNotEmpty) {
        try {
          final data = jsonDecode(payload);
          final medicineId = data['medicineId'] as String?;
          final reminderId = data['reminderTimeId'] as String?;

          if (medicineId != null && reminderId != null) {
            final provider = context.read<MedicineProvider>();
            final med = provider.medicines.firstWhere(
              (m) => m.id == medicineId,
              orElse: () => Medicine(
                id: medicineId,
                profileId: 'default_me',
                name: data['medicineName'] ?? 'Medicine',
                dosage: data['dosage'] ?? '',
                type: MedicineType.tablet,
                colorValue: 0xFF0D9488,
                instruction: FoodInstruction.afterMeal,
                createdAt: DateTime.now(),
              ),
            );

            final reminders = provider.getRemindersForMedicine(medicineId);
            final rem = reminders.firstWhere(
              (r) => r.id == reminderId,
              orElse: () => ReminderTime(
                id: reminderId,
                medicineId: medicineId,
                hour: 8,
                minute: 0,
                daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
                notificationId: 1001,
              ),
            );

            if (actionId == NotificationService.actionTaken) {
              provider.markAsTaken(med, rem, DateTime.now());
            } else if (actionId == NotificationService.actionSnooze) {
              provider.snoozeDose(med, rem, minutes: 10);
            } else if (actionId == NotificationService.actionSkip) {
              provider.markAsSkipped(med, rem, DateTime.now());
            } else {
              // Tap on notification opens the full Alarm / Intake confirmation screen!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlarmRingingScreen(medicine: med, reminder: rem),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error handling notification payload: $e');
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded, color: AppColors.primary),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded, color: AppColors.primary),
            label: 'Cabinet',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded, color: AppColors.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
