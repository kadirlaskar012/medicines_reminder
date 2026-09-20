import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/models/medicine.dart';
import 'package:medicines_reminder/models/reminder_time.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  test('ReminderTime isDaily and recurrenceSummary test', () {
    final rem = ReminderTime(
      id: 'rem_custom',
      medicineId: 'med_test_1',
      hour: 20,
      minute: 0,
      daysOfWeek: [1, 3, 5],
      notificationId: 5432,
    );

    expect(rem.isDaily, false);
    expect(rem.recurrenceSummary, 'Mon, Wed, Fri');
  });

  test('Course-based stock calculation and 50% refill alert threshold test', () {
    // 10 days course, 2 doses per day (Lunch and Afternoon)
    const int durationDays = 10;
    const int dailyDoseCount = 2;

    final int calculatedStock = durationDays * dailyDoseCount;
    expect(calculatedStock, 20);

    // 50% threshold calculation
    final int refillThreshold = (calculatedStock * 0.5).round();
    expect(refillThreshold, 10);

    // 7 days course, 3 doses per day
    const int duration7Days = 7;
    const int dailyDoses3 = 3;
    final int stock21 = duration7Days * dailyDoses3;
    expect(stock21, 21);
    final int threshold11 = (stock21 * 0.5).round();
    expect(threshold11, 11);
  });

  test('PDF document creation test', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Text('MediRemind Report Test'),
        ),
      ),
    );
    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
  });
}
