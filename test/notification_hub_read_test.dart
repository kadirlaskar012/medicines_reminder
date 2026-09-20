import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/models/intake_record.dart';
import 'package:medicines_reminder/models/medicine.dart';
import 'package:medicines_reminder/models/reminder_time.dart';
import 'package:medicines_reminder/models/scheduled_dose.dart';

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
}
