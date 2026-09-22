import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/core/localization/app_strings.dart';
import 'package:medicines_reminder/models/intake_record.dart';
import 'package:medicines_reminder/models/medicine.dart';
import 'package:medicines_reminder/models/reminder_time.dart';
import 'package:medicines_reminder/models/scheduled_dose.dart';
import 'package:medicines_reminder/models/app_notification.dart';
import 'package:medicines_reminder/widgets/luxury_notification_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testMedicine = Medicine(
    id: 'med_test_1',
    profileId: 'default_me',
    name: 'Paracetamol',
    dosage: '500 mg',
    type: MedicineType.tablet,
    colorValue: 0xFF0D9488,
    instruction: FoodInstruction.afterMeal,
    currentStock: 20,
    refillThreshold: 5,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  );

  test('ScheduledDose doseDateTime is computed accurately', () {
    final now = DateTime.now();
    final rem = ReminderTime(
      id: 'rem_1',
      medicineId: 'med_test_1',
      hour: 9,
      minute: 30,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      notificationId: 101,
    );

    final dose = ScheduledDose(
      medicine: testMedicine,
      reminder: rem,
      scheduledDate: DateTime(now.year, now.month, now.day),
    );

    expect(dose.doseDateTime.year, now.year);
    expect(dose.doseDateTime.month, now.month);
    expect(dose.doseDateTime.day, now.day);
    expect(dose.doseDateTime.hour, 9);
    expect(dose.doseDateTime.minute, 30);
  });

  test('ScheduledDose overdue check evaluates correctly', () {
    final now = DateTime.now();
    // Dose scheduled 1 hour ago
    final pastTime = now.subtract(const Duration(hours: 1));
    final remPast = ReminderTime(
      id: 'rem_past',
      medicineId: 'med_test_1',
      hour: pastTime.hour,
      minute: pastTime.minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      notificationId: 102,
    );

    final overdueDose = ScheduledDose(
      medicine: testMedicine,
      reminder: remPast,
      scheduledDate: DateTime(pastTime.year, pastTime.month, pastTime.day),
    );

    expect(overdueDose.isOverdue, true);

    // Dose marked as taken is no longer overdue
    final takenDose = ScheduledDose(
      medicine: testMedicine,
      reminder: remPast,
      scheduledDate: DateTime(pastTime.year, pastTime.month, pastTime.day),
      record: IntakeRecord(
        id: 'rec_1',
        medicineId: testMedicine.id,
        reminderTimeId: remPast.id,
        scheduledDate: '${pastTime.year}-${pastTime.month.toString().padLeft(2, '0')}-${pastTime.day.toString().padLeft(2, '0')}',
        scheduledHour: pastTime.hour,
        scheduledMinute: pastTime.minute,
        status: IntakeStatus.taken,
        recordedAt: now,
      ),
    );

    expect(takenDose.isOverdue, false);
  });

  test('Notification bell unread dot logic handles read timestamp and future alerts', () {
    final now = DateTime.now();

    // Past dose from 2 hours ago
    final past2Hours = now.subtract(const Duration(hours: 2));
    final rem1 = ReminderTime(
      id: 'rem_1',
      medicineId: testMedicine.id,
      hour: past2Hours.hour,
      minute: past2Hours.minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      notificationId: 201,
    );
    final dose1 = ScheduledDose(
      medicine: testMedicine,
      reminder: rem1,
      scheduledDate: DateTime(now.year, now.month, now.day),
    );

    // Initial state: user visited hub 10 minutes ago
    final lastViewedAt = now.subtract(const Duration(minutes: 10));

    // dose1 was scheduled 2 hours ago, which is before lastViewedAt (10 mins ago)
    // Therefore, dose1 is already seen and should NOT trigger an unread alert
    final hasNewAlertOldDose = [dose1].any((d) {
      if (d.isTaken || d.isSkipped) return false;
      return d.doseDateTime.isAfter(lastViewedAt) &&
          (d.doseDateTime.isBefore(now) || d.doseDateTime.isAtSameMomentAs(now));
    });

    expect(hasNewAlertOldDose, false);

    // New dose scheduled 5 minutes ago (AFTER lastViewedAt which was 10 mins ago)
    final past5Minutes = now.subtract(const Duration(minutes: 5));
    final rem2 = ReminderTime(
      id: 'rem_2',
      medicineId: testMedicine.id,
      hour: past5Minutes.hour,
      minute: past5Minutes.minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      notificationId: 202,
    );
    final dose2 = ScheduledDose(
      medicine: testMedicine,
      reminder: rem2,
      scheduledDate: DateTime(now.year, now.month, now.day),
    );

    // Now evaluates to true because dose2 arrived after the user last viewed the hub
    final hasNewAlertNewDose = [dose1, dose2].any((d) {
      if (d.isTaken || d.isSkipped) return false;
      return d.doseDateTime.isAfter(lastViewedAt) &&
          (d.doseDateTime.isBefore(now) || d.doseDateTime.isAtSameMomentAs(now));
    });

    expect(hasNewAlertNewDose, true);

    // After user visits hub now, lastViewedAt updates to now
    final updatedLastViewedAt = DateTime.now();
    final hasAlertAfterRevisiting = [dose1, dose2].any((d) {
      if (d.isTaken || d.isSkipped) return false;
      return d.doseDateTime.isAfter(updatedLastViewedAt) &&
          (d.doseDateTime.isBefore(now) || d.doseDateTime.isAtSameMomentAs(now));
    });

    expect(hasAlertAfterRevisiting, false);
  });

  test('AppNotification toMap and fromMap serialization maintains integrity', () {
    final now = DateTime.now();
    final notif = AppNotification(
      id: 'notif_test_1',
      type: NotificationType.doseTaken,
      title: 'প্যারাসিটামল গ্রহণ সম্পন্ন',
      message: '৫০০ মিগ্রা • সকাল ০৯:৩০ এর ডোজ গ্রহণ করা হয়েছে',
      medicineId: 'med_test_1',
      medicineName: 'Paracetamol',
      profileName: 'Myself',
      timestamp: now,
      isRead: false,
      metadata: {'doseKey': 'med_1_rem_1_2026-09-20'},
    );

    final map = notif.toMap();
    expect(map['id'], 'notif_test_1');
    expect(map['type'], 'doseTaken');
    expect(map['isRead'], 0);

    final restored = AppNotification.fromMap(map);
    expect(restored.id, notif.id);
    expect(restored.type, NotificationType.doseTaken);
    expect(restored.title, notif.title);
    expect(restored.message, notif.message);
    expect(restored.medicineId, notif.medicineId);
    expect(restored.medicineName, notif.medicineName);
    expect(restored.isRead, false);
    expect(restored.metadata?['doseKey'], 'med_1_rem_1_2026-09-20');

    final updated = restored.copyWith(isRead: true);
    expect(updated.isRead, true);
    expect(updated.toMap()['isRead'], 1);
  });

  test('Notification category filtering correctly partitions activity types', () {
    final notifs = [
      AppNotification(id: '1', type: NotificationType.doseTaken, title: 'Taken', message: '', timestamp: DateTime.now()),
      AppNotification(id: '2', type: NotificationType.doseSkipped, title: 'Skipped', message: '', timestamp: DateTime.now()),
      AppNotification(id: '3', type: NotificationType.refillAdded, title: 'Refilled', message: '', timestamp: DateTime.now()),
      AppNotification(id: '4', type: NotificationType.lowStock, title: 'Low Stock', message: '', timestamp: DateTime.now()),
      AppNotification(id: '5', type: NotificationType.medicineAdded, title: 'Added', message: '', timestamp: DateTime.now()),
      AppNotification(id: '6', type: NotificationType.medicineUpdated, title: 'Updated', message: '', timestamp: DateTime.now()),
    ];

    final doses = notifs.where((n) =>
        n.type == NotificationType.doseTaken ||
        n.type == NotificationType.doseSkipped ||
        n.type == NotificationType.doseSnoozed ||
        n.type == NotificationType.doseMissed ||
        n.type == NotificationType.reminderDue).toList();
    expect(doses.length, 2);

    final stock = notifs.where((n) =>
        n.type == NotificationType.refillAdded ||
        n.type == NotificationType.lowStock).toList();
    expect(stock.length, 2);

    final medicines = notifs.where((n) =>
        n.type == NotificationType.medicineAdded ||
        n.type == NotificationType.medicineUpdated).toList();
    expect(medicines.length, 2);
  });

  testWidgets('LuxuryNotificationCard renders with brand, medicine info and horizontal action buttons', (tester) async {
    bool takenCalled = false;
    bool snoozeCalled = false;
    bool skipCalled = false;

    final notif = AppNotification(
      id: 'notif_due_1',
      type: NotificationType.reminderDue,
      title: 'Time to take Paracetamol',
      message: '1 tablet • After Meal',
      medicineName: 'Paracetamol',
      metadata: {
        'dosage': '500 mg',
        'instruction': 'afterMeal',
        'medicineType': 'tablet',
      },
      timestamp: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LuxuryNotificationCard(
            notification: notif,
            s: AppStrings.en,
            isDark: false,
            onTake: () => takenCalled = true,
            onSnooze: () => snoozeCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('500 mg'), findsOneWidget);
    expect(find.text(AppStrings.en.iTookMyMedicine), findsOneWidget);
    expect(find.text(AppStrings.en.snooze10m), findsOneWidget);
    expect(find.text(AppStrings.en.skip), findsOneWidget);

    await tester.tap(find.text(AppStrings.en.iTookMyMedicine));
    expect(takenCalled, isTrue);

    await tester.tap(find.text(AppStrings.en.snooze10m));
    expect(snoozeCalled, isTrue);

    await tester.tap(find.text(AppStrings.en.skip));
    expect(skipCalled, isTrue);
  });
}
