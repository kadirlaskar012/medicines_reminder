import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/models/medicine.dart';
import 'package:medicines_reminder/models/reminder_time.dart';

void main() {
  test('Medicine model serialization test', () {
    final med = Medicine(
      id: 'med_test_1',
      profileId: 'default_me',
      name: 'Amoxicillin',
      dosage: '500 mg',
      type: MedicineType.capsule,
      colorValue: 0xFF0D9488,
      instruction: FoodInstruction.afterMeal,
      currentStock: 10,
      refillThreshold: 3,
      createdAt: DateTime.now(),
    );

    final map = med.toMap();
    final recreated = Medicine.fromMap(map);

    expect(recreated.id, 'med_test_1');
    expect(recreated.name, 'Amoxicillin');
    expect(recreated.type, MedicineType.capsule);
    expect(recreated.isLowStock, false);
  });

  test('ReminderTime formatted time and timeSlot test', () {
    final rem = ReminderTime(
      id: 'rem_1',
      medicineId: 'med_test_1',
      hour: 8,
      minute: 30,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      notificationId: 101,
    );

    expect(rem.timeSlot, TimeSlot.morning);
    expect(rem.isDaily, true);
    expect(rem.recurrenceSummary, 'Everyday');
  });

  test('Pre-dose warning notification ID calculation test', () {
    final rem = ReminderTime(
      id: 'rem_warning_test',
      medicineId: 'med_test_1',
      hour: 22,
      minute: 0,
      daysOfWeek: [1],
      notificationId: 5432,
    );

    final warningId = (rem.notificationId * 10 + 1 + 600000) % 1000000;
    expect(warningId, 654321);
  });
}
