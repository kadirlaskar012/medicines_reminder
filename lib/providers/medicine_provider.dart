import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/database/db_helper.dart';
import '../core/services/notification_service.dart';
import '../models/user_profile.dart';
import '../models/medicine.dart';
import '../models/reminder_time.dart';
import '../models/intake_record.dart';
import '../models/scheduled_dose.dart';

class MedicineProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper.instance;
  final NotificationService _notifications = NotificationService.instance;
  final Uuid _uuid = const Uuid();

  List<UserProfile> _profiles = [];
  UserProfile? _activeProfile; // null = all
  List<Medicine> _medicines = [];
  final Map<String, List<ReminderTime>> _remindersByMedicine = {};
  final Map<String, IntakeRecord> _recordsByDoseKey = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  // Getters
  List<UserProfile> get profiles => _profiles;
  UserProfile? get activeProfile => _activeProfile;
  List<Medicine> get medicines => _medicines;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  List<IntakeRecord> get intakeRecords => _recordsByDoseKey.values.toList();

  String get selectedDateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // Filtered medicines by active profile
  List<Medicine> get filteredMedicines {
    if (_activeProfile == null) return _medicines;
    return _medicines.where((m) => m.profileId == _activeProfile!.id).toList();
  }

  // Low stock medicines
  List<Medicine> get lowStockMedicines {
    return _medicines.where((m) => m.isLowStock || m.isOutOfStock).toList();
  }

  // Doses for selected date
  List<ScheduledDose> get dosesForSelectedDate {
    final weekday = _selectedDate.weekday; // 1 = Mon .. 7 = Sun
    final List<ScheduledDose> list = [];

    for (final med in filteredMedicines) {
      if (!med.isActive) continue;
      final reminders = _remindersByMedicine[med.id] ?? [];
      for (final rem in reminders) {
        if (rem.daysOfWeek.contains(weekday)) {
          final key = '${med.id}_${rem.id}_$selectedDateStr';
          final record = _recordsByDoseKey[key];
          list.add(ScheduledDose(
            medicine: med,
            reminder: rem,
            record: record,
            scheduledDate: _selectedDate,
          ));
        }
      }
    }

    // Sort chronologically by hour and minute
    list.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    return list;
  }

  // Grouped by time slots
  List<ScheduledDose> get morningDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.morning).toList();

  List<ScheduledDose> get afternoonDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.afternoon).toList();

  List<ScheduledDose> get eveningDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.evening).toList();

  List<ScheduledDose> get nightDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.night).toList();

  // Adherence Calculations
  double get todayAdherenceRate {
    final total = dosesForSelectedDate.length;
    if (total == 0) return 1.0;
    final taken = dosesForSelectedDate.where((d) => d.isTaken).length;
    return taken / total;
  }

  int get todayTakenCount => dosesForSelectedDate.where((d) => d.isTaken).length;
  int get todayTotalCount => dosesForSelectedDate.length;

  // ==================== INITIALIZATION ====================
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profiles = await _db.getAllProfiles();
      if (_profiles.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('user_profile_name');
        final savedAge = prefs.getInt('user_profile_age');
        final savedAvatar = prefs.getString('user_profile_avatar');

        final me = UserProfile(
          id: 'default_me',
          name: (savedName != null && savedName.trim().isNotEmpty) ? savedName.trim() : 'Myself',
          relation: 'Myself',
          colorValue: 0xFFFF6B35,
          avatarEmoji: savedAvatar ?? '👤',
          age: savedAge,
        );
        await _db.insertProfile(me);
        _profiles = [me];
      }
      _activeProfile = null; // null represents "All Family"

      await _refreshMedicinesAndReminders();
      await rescheduleAllActiveReminders();
      await _refreshRecords();
    } catch (e) {
      debugPrint('SQLite notice: loading initial fallback: $e');
      _seedInMemoryFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _seedInMemoryFallback() {
    final me = UserProfile.defaultProfile;
    _profiles = [me];
    _activeProfile = null;
    _medicines = [];
    _remindersByMedicine.clear();
  }

  Future<void> _refreshMedicinesAndReminders() async {
    _medicines = await _db.getAllMedicines();
    _remindersByMedicine.clear();

    for (final med in _medicines) {
      final rems = await _db.getRemindersForMedicine(med.id);
      _remindersByMedicine[med.id] = rems;
    }
  }

  Future<void> rescheduleAllActiveReminders() async {
    for (final med in _medicines) {
      if (!med.isActive) continue;
      final reminders = _remindersByMedicine[med.id] ?? [];
      for (final rem in reminders) {
        await _notifications.scheduleMedicineReminder(med, rem);
      }
    }
  }

  Future<void> _refreshRecords() async {
    final records = await _db.getRecordsForDate(selectedDateStr);
    _recordsByDoseKey.clear();
    for (final r in records) {
      final key = '${r.medicineId}_${r.reminderTimeId}_${r.scheduledDate}';
      _recordsByDoseKey[key] = r;
    }
  }

  // ==================== ACTIONS ====================
  void switchProfile(UserProfile? profile) {
    _activeProfile = profile;
    notifyListeners();
  }

  void selectDate(DateTime date) async {
    _selectedDate = date;
    await _refreshRecords();
    notifyListeners();
  }

  Future<void> addMedicine({
    required String name,
    required String dosage,
    required MedicineType type,
    required int colorValue,
    required FoodInstruction instruction,
    required int currentStock,
    required int refillThreshold,
    required String notes,
    required List<ReminderTime> reminderTimes,
    String? profileId,
  }) async {
    final medId = _uuid.v4();
    final targetProfileId = profileId ?? _activeProfile?.id ?? UserProfile.defaultProfile.id;

    final newMedicine = Medicine(
      id: medId,
      profileId: targetProfileId,
      name: name,
      dosage: dosage,
      type: type,
      colorValue: colorValue,
      instruction: instruction,
      currentStock: currentStock,
      refillThreshold: refillThreshold,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Ensure reminder medicine IDs match
    final updatedReminders = reminderTimes.map((r) {
      return ReminderTime(
        id: _uuid.v4(),
        medicineId: medId,
        hour: r.hour,
        minute: r.minute,
        daysOfWeek: r.daysOfWeek,
        isAlarm: r.isAlarm,
        notificationId: (_uuid.v4().hashCode.abs()) % 100000,
      );
    }).toList();

    await _db.insertMedicine(newMedicine, updatedReminders);

    // Schedule Android local notifications
    for (final rem in updatedReminders) {
      await _notifications.scheduleMedicineReminder(newMedicine, rem);
    }

    await _refreshMedicinesAndReminders();
    await _refreshRecords();
    notifyListeners();
  }

  Future<void> updateMedicine({
    required Medicine medicine,
    required List<ReminderTime> reminders,
  }) async {
    // Cancel old alarms
    final oldReminders = _remindersByMedicine[medicine.id] ?? [];
    for (final oldRem in oldReminders) {
      await _notifications.cancelReminder(oldRem);
    }

    // Update in DB
    await _db.updateMedicine(medicine, reminders);

    // Schedule new alarms if active
    if (medicine.isActive) {
      for (final rem in reminders) {
        await _notifications.scheduleMedicineReminder(medicine, rem);
      }
    }

    await _refreshMedicinesAndReminders();
    await _refreshRecords();
    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    final oldReminders = _remindersByMedicine[id] ?? [];
    for (final oldRem in oldReminders) {
      await _notifications.cancelReminder(oldRem);
    }

    await _db.deleteMedicine(id);
    await _refreshMedicinesAndReminders();
    await _refreshRecords();
    notifyListeners();
  }

  int getDailyDoseCount(String medicineId) {
    return (_remindersByMedicine[medicineId] ?? []).length;
  }

  // Dose Intake Confirmation
  Future<void> markAsTaken(Medicine medicine, ReminderTime reminder, DateTime date) async {
    NotificationService.triggerHaptic(isSuccess: true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${medicine.id}_${reminder.id}_$dateStr';

    final record = IntakeRecord(
      id: _uuid.v4(),
      medicineId: medicine.id,
      reminderTimeId: reminder.id,
      scheduledDate: dateStr,
      scheduledHour: reminder.hour,
      scheduledMinute: reminder.minute,
      status: IntakeStatus.taken,
      recordedAt: DateTime.now(),
    );

    try {
      await _db.recordIntake(record);
      final updatedMed = await _db.getMedicineById(medicine.id);
      if (updatedMed != null && updatedMed.isLowStock) {
        await _notifications.showRefillAlert(updatedMed);
      }
      await _refreshMedicinesAndReminders();
    } catch (_) {
      final idx = _medicines.indexWhere((m) => m.id == medicine.id);
      if (idx != -1 && _medicines[idx].currentStock > 0) {
        _medicines[idx] = _medicines[idx].copyWith(
          currentStock: _medicines[idx].currentStock - 1,
        );
      }
    }
    _recordsByDoseKey[key] = record;
    notifyListeners();
  }

  Future<void> markAsSkipped(Medicine medicine, ReminderTime reminder, DateTime date) async {
    NotificationService.triggerHaptic(isSuccess: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${medicine.id}_${reminder.id}_$dateStr';

    final record = IntakeRecord(
      id: _uuid.v4(),
      medicineId: medicine.id,
      reminderTimeId: reminder.id,
      scheduledDate: dateStr,
      scheduledHour: reminder.hour,
      scheduledMinute: reminder.minute,
      status: IntakeStatus.skipped,
      recordedAt: DateTime.now(),
    );

    try {
      await _db.recordIntake(record);
    } catch (_) {}
    _recordsByDoseKey[key] = record;
    notifyListeners();
  }

  Future<void> snoozeDose(Medicine medicine, ReminderTime reminder, {int minutes = 10}) async {
    NotificationService.triggerHaptic(isSuccess: false);
    try {
      await _notifications.snoozeReminder(
        medicine.name,
        medicine.dosage,
        'snooze_${medicine.id}',
        minutes: minutes,
      );
    } catch (_) {}
  }


  Future<void> refillStock(String medicineId, int addedQuantity) async {
    try {
      final med = await _db.getMedicineById(medicineId);
      if (med != null) {
        final newStock = med.currentStock + addedQuantity;
        await _db.updateStock(medicineId, newStock);
        await _refreshMedicinesAndReminders();
      }
    } catch (_) {
      final idx = _medicines.indexWhere((m) => m.id == medicineId);
      if (idx != -1) {
        _medicines[idx] = _medicines[idx].copyWith(
          currentStock: _medicines[idx].currentStock + addedQuantity,
        );
      }
    }
    notifyListeners();
  }

  // Profile Management
  UserProfile get primaryProfile {
    return _profiles.firstWhere(
      (p) => p.id == 'default_me',
      orElse: () => UserProfile.defaultProfile,
    );
  }

  Future<void> saveInitialUserProfile({
    required String name,
    required int? age,
    String? avatarEmoji,
    int? colorValue,
  }) async {
    final cleanName = name.trim().isEmpty ? 'Myself' : name.trim();
    final profile = UserProfile(
      id: 'default_me',
      name: cleanName,
      relation: 'Myself',
      colorValue: colorValue ?? 0xFFFF6B35,
      avatarEmoji: avatarEmoji ?? '👤',
      age: age,
    );
    await _db.insertProfile(profile);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile_name', cleanName);
    if (age != null) {
      await prefs.setInt('user_profile_age', age);
    } else {
      await prefs.remove('user_profile_age');
    }
    if (avatarEmoji != null) {
      await prefs.setString('user_profile_avatar', avatarEmoji);
    }

    _profiles = await _db.getAllProfiles();
    _activeProfile = _profiles.firstWhere((p) => p.id == 'default_me', orElse: () => profile);
    notifyListeners();
  }

  Future<void> addProfile(String name, String relation, int colorValue, String emoji) async {
    final profile = UserProfile(
      id: _uuid.v4(),
      name: name,
      relation: relation,
      colorValue: colorValue,
      avatarEmoji: emoji,
    );
    await _db.insertProfile(profile);
    _profiles = await _db.getAllProfiles();
    _activeProfile = profile;
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    if (id == 'default_me') return;
    await _db.deleteProfile(id);
    _profiles = await _db.getAllProfiles();
    _activeProfile = _profiles.first;
    await _refreshMedicinesAndReminders();
    notifyListeners();
  }

  List<ReminderTime> getRemindersForMedicine(String medicineId) {
    return _remindersByMedicine[medicineId] ?? [];
  }
}
