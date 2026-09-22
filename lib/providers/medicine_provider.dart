import 'dart:async';
import 'dart:convert';
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
import '../models/app_notification.dart';
import '../core/localization/app_strings.dart';

enum DateComplianceStatus {
  allTaken,      // 🟢 All scheduled medicines taken on this date
  partialTaken,  // 🟡 At least 1 taken, some remaining/pending
  hasMissed,     // 🔴 Any dose skipped or unrecorded in the past
  noneScheduled, // No medicines scheduled on this weekday
  futurePending, // Future date with pending doses
}

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
  List<ScheduledDose>? _cachedMissedDoses;
  List<ScheduledDose>? _cachedDosesForSelectedDate;
  final Map<String, List<ScheduledDose>> _dosesByDateCache = {};
  int? _cachedCurrentStreak;
  int? _cachedBestStreak;
  DateTime? _lastNotificationHubViewedAt;
  List<AppNotification> _notificationsList = [];

  void _invalidateCaches() {
    _cachedDosesForSelectedDate = null;
    _dosesByDateCache.clear();
    _cachedMissedDoses = null;
    _cachedCurrentStreak = null;
    _cachedBestStreak = null;
  }

  // Getters
  List<UserProfile> get profiles => _profiles;
  UserProfile? get activeProfile => _activeProfile;
  List<Medicine> get medicines => _medicines;
  Map<String, List<ReminderTime>> get remindersByMedicine => _remindersByMedicine;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  List<IntakeRecord> get intakeRecords => _recordsByDoseKey.values.toList();
  List<ScheduledDose> get missedDoses => getMissedDoses();
  List<AppNotification> get notificationsList => _notificationsList;
  int get unreadNotificationsCount => _notificationsList.where((n) => !n.isRead).length;

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

  /// Checks whether a medicine is active and within its start/end treatment window on [date]
  bool isMedicineActiveOnDate(Medicine med, DateTime date) {
    if (!med.isActive) return false;
    final target = DateTime(date.year, date.month, date.day);
    final startDt = med.startDate ?? med.createdAt;
    final start = DateTime(startDt.year, startDt.month, startDt.day);
    if (target.isBefore(start)) return false;
    if (med.endDate != null) {
      final end = DateTime(med.endDate!.year, med.endDate!.month, med.endDate!.day);
      if (target.isAfter(end)) return false;
    }
    return true;
  }

  // Doses for selected date (memoized for fast 120fps UI rendering)
  List<ScheduledDose> get dosesForSelectedDate {
    if (_cachedDosesForSelectedDate != null) return _cachedDosesForSelectedDate!;
    _cachedDosesForSelectedDate = getDosesForDate(_selectedDate);
    return _cachedDosesForSelectedDate!;
  }

  // Grouped by time slots
  List<ScheduledDose> get morningDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.morning).toList();

  List<ScheduledDose> get lunchDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.lunch).toList();

  List<ScheduledDose> get afternoonDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.afternoon).toList();

  List<ScheduledDose> get eveningDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.evening).toList();

  List<ScheduledDose> get nightDoses =>
      dosesForSelectedDate.where((d) => d.reminder.timeSlot == TimeSlot.night).toList();

  // Adherence Calculations
  double get todayAdherenceRate {
    final total = dosesForSelectedDate.length;
    if (total == 0) return 0.0;
    final taken = dosesForSelectedDate.where((d) => d.isTaken).length;
    return taken / total;
  }

  int get todayTakenCount => dosesForSelectedDate.where((d) => d.isTaken).length;
  int get todayTotalCount => dosesForSelectedDate.length;
  DateTime? get lastNotificationHubViewedAt => _lastNotificationHubViewedAt;

  /// Whether there are new unread notification alerts since the user last visited the notification hub
  bool get hasUnreadNotificationAlerts {
    if (_notificationsList.any((n) => !n.isRead)) return true;
    final now = DateTime.now();
    final todayDoses = getDosesForDate(now);

    // If user has never visited the notification hub, show dot if any dose is overdue/elapsed today
    if (_lastNotificationHubViewedAt == null) {
      return todayDoses.any(
        (d) => d.isOverdue || (!d.isTaken && !d.isSkipped && d.doseDateTime.isBefore(now)),
      );
    }

    // Defensive check: if last viewed timestamp is somehow in the future, reset to now
    final lastViewed = _lastNotificationHubViewedAt!.isAfter(now) ? now : _lastNotificationHubViewedAt!;

    // If user visited the notification hub before, only show the dot if a new dose alert arrived
    // after their last visit (i.e. doseDateTime > lastViewed and <= now)
    // and is still pending (not taken, not skipped)
    return todayDoses.any((d) {
      if (d.isTaken || d.isSkipped) return false;
      final doseTime = d.doseDateTime;
      return doseTime.isAfter(lastViewed) &&
          (doseTime.isBefore(now) || doseTime.isAtSameMomentAs(now));
    });
  }

  /// Get scheduled doses for any specific date (memoized for O(1) repeated queries)
  List<ScheduledDose> getDosesForDate(DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_dosesByDateCache.containsKey(dateStr)) {
      return _dosesByDateCache[dateStr]!;
    }

    final weekday = date.weekday;
    final List<ScheduledDose> list = [];

    for (final med in filteredMedicines) {
      if (!isMedicineActiveOnDate(med, date)) continue;
      final reminders = _remindersByMedicine[med.id] ?? [];
      for (final rem in reminders) {
        if (rem.daysOfWeek.contains(weekday)) {
          final key = '${med.id}_${rem.id}_$dateStr';
          final record = _recordsByDoseKey[key];
          list.add(ScheduledDose(
            medicine: med,
            reminder: rem,
            record: record,
            scheduledDate: date,
          ));
        }
      }
    }

    list.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    _dosesByDateCache[dateStr] = list;
    return list;
  }

  /// Real adherence rate for any specific date (0.0 to 1.0)
  double getAdherenceRateForDate(DateTime date) {
    final doses = getDosesForDate(date);
    if (doses.isEmpty) return 0.0;
    final taken = doses.where((d) => d.isTaken).length;
    return taken / doses.length;
  }

  /// Compliance status indicator for calendar timeline dot
  DateComplianceStatus getDateComplianceStatus(DateTime date) {
    final doses = getDosesForDate(date);
    if (doses.isEmpty) {
      return DateComplianceStatus.noneScheduled;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final isTargetToday = targetDate.isAtSameMomentAs(today);
    final isTargetPast = targetDate.isBefore(today);

    final takenCount = doses.where((d) => d.isTaken).length;
    final totalCount = doses.length;

    // 1. All scheduled doses taken -> Green
    if (takenCount == totalCount) {
      return DateComplianceStatus.allTaken;
    }

    // 2. Some taken, some not (e.g. 3 of 4, 2 of 4, 1 of 4) -> Yellow (Partial)
    if (takenCount > 0) {
      return DateComplianceStatus.partialTaken;
    }

    // 3. Past dates: zero taken -> Red (All Missed / Skipped)
    if (isTargetPast) {
      return DateComplianceStatus.hasMissed;
    }

    // 4. Today: zero taken so far, check if any is already overdue or skipped
    if (isTargetToday) {
      final hasOverdueOrSkipped = doses.any((d) => d.isOverdue || d.isSkipped);
      if (hasOverdueOrSkipped) {
        return DateComplianceStatus.hasMissed;
      }
      return DateComplianceStatus.futurePending;
    }

    // 5. Future dates
    return DateComplianceStatus.futurePending;
  }

  /// Earliest start or creation date among all medicines
  DateTime? get _earliestMedicineDate {
    if (_medicines.isEmpty) return null;
    DateTime? earliest;
    for (final med in _medicines) {
      final d = med.startDate ?? med.createdAt;
      if (earliest == null || d.isBefore(earliest)) {
        earliest = d;
      }
    }
    return earliest != null ? DateTime(earliest.year, earliest.month, earliest.day) : null;
  }

  /// Real consecutive adherence streak (in days) based on real intake records (memoized)
  int get currentStreakDays {
    if (_cachedCurrentStreak != null) return _cachedCurrentStreak!;
    if (_medicines.isEmpty) return 0;
    final earliest = _earliestMedicineDate;
    if (earliest == null) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayDoses = getDosesForDate(now);
    if (todayDoses.isNotEmpty && todayDoses.every((d) => d.isTaken)) {
      streak++;
    }

    for (int i = 1; i <= 365; i++) {
      final prevDate = today.subtract(Duration(days: i));
      if (prevDate.isBefore(earliest)) {
        break;
      }
      final prevDoses = getDosesForDate(prevDate);
      if (prevDoses.isEmpty) {
        continue;
      }
      if (prevDoses.every((d) => d.isTaken)) {
        streak++;
      } else {
        break;
      }
    }
    _cachedCurrentStreak = streak;
    return streak;
  }

  /// Best consecutive adherence streak (in days) based on real intake records (memoized)
  int get bestStreakDays {
    if (_cachedBestStreak != null) return _cachedBestStreak!;
    if (_medicines.isEmpty) return 0;
    final earliest = _earliestMedicineDate;
    if (earliest == null) return 0;

    int best = 0;
    int current = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totalDays = today.difference(earliest).inDays;
    if (totalDays < 0) {
      _cachedBestStreak = currentStreakDays;
      return _cachedBestStreak!;
    }

    for (int i = totalDays; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final doses = getDosesForDate(date);
      if (doses.isEmpty) continue;
      if (doses.every((d) => d.isTaken)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    final result = best > currentStreakDays ? best : currentStreakDays;
    _cachedBestStreak = result;
    return result;
  }

  // ==================== INITIALIZATION ====================
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHubViewedStr = prefs.getString('last_notification_hub_viewed_at');
      if (savedHubViewedStr != null) {
        _lastNotificationHubViewedAt = DateTime.tryParse(savedHubViewedStr);
      }

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
          colorValue: 0xFF0D9488,
          avatarEmoji: savedAvatar ?? '👤',
          age: savedAge,
        );
        await _db.insertProfile(me);
        _profiles = [me];
      }
      _activeProfile = null; // null represents "All Family"

      await _refreshMedicinesAndReminders();
      await _refreshRecords();
      await refreshNotifications();
      _invalidateCaches();
    } catch (e) {
      debugPrint('SQLite notice: loading initial fallback: $e');
      _seedInMemoryFallback();
    } finally {
      _isLoading = false;
      _invalidateCaches();
      notifyListeners();
      // Perform platform-channel alarms scheduling and past checks in background
      unawaited(_backgroundStartupMaintenance());
    }
  }

  Future<void> _backgroundStartupMaintenance() async {
    try {
      await autoSkipPastDueDoses(checkPastDays: true);
    } catch (e) {
      debugPrint('autoSkipPastDueDoses notice: $e');
    }
    try {
      await rescheduleAllActiveReminders();
    } catch (e) {
      debugPrint('rescheduleAllActiveReminders notice: $e');
    }
  }

  /// Silently refreshes local medicines, reminders, and intake records
  /// without resetting _isLoading or re-scheduling all system alarms.
  Future<void> reloadDataSilently() async {
    try {
      _profiles = await _db.getAllProfiles();
      await _refreshMedicinesAndReminders();
      await _refreshRecords();
      await refreshNotifications();
      _cachedMissedDoses = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Silent reload notice: $e');
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
    _invalidateCaches();
  }

  Future<void> rescheduleAllActiveReminders() async {
    try {
      await _notifications.wipeAllDeviceNotificationsAndAlarms();
      int scheduledCount = 0;
      for (final med in _medicines) {
        if (!med.isActive) continue;
        final reminders = _remindersByMedicine[med.id] ?? [];
        for (final rem in reminders) {
          await _notifications.scheduleMedicineReminder(med, rem);
          scheduledCount++;
        }
      }
      debugPrint('MedicineProvider: Rescheduled $scheduledCount active reminder alarms across ${_medicines.length} medicines.');
    } catch (e) {
      debugPrint('MedicineProvider: Error in rescheduleAllActiveReminders: $e');
    }
  }

  Future<void> _refreshRecords() async {
    final records = await _db.getAllRecords(limit: 5000);
    _recordsByDoseKey.clear();
    for (final r in records) {
      final key = '${r.medicineId}_${r.reminderTimeId}_${r.scheduledDate}';
      _recordsByDoseKey[key] = r;
    }
    _invalidateCaches();
  }

  // ==================== APP NOTIFICATIONS & ACTIVITY HUB ====================
  Future<void> refreshNotifications({String? filterType}) async {
    try {
      var notifs = await _db.getAllNotifications(limit: 300, filterType: filterType);
      if (notifs.isEmpty && (filterType == null || filterType == 'all')) {
        await _backfillNotificationsIfEmpty();
        notifs = await _db.getAllNotifications(limit: 300);
      }
      _notificationsList = notifs;
      notifyListeners();
    } catch (e) {
      debugPrint('Notice refreshing notifications: $e');
    }
  }

  Future<AppStrings> _getStrings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language_code') ?? 'en';
      return AppStrings.of(lang);
    } catch (_) {
      return AppStrings.en;
    }
  }

  Future<void> _backfillNotificationsIfEmpty() async {
    try {
      final existingNotifs = await _db.getAllNotifications(limit: 1);
      if (existingNotifs.isNotEmpty) return;

      final s = await _getStrings();

      // Backfill from medicines
      for (final med in _medicines) {
        final addNotif = AppNotification(
          id: _uuid.v4(),
          type: NotificationType.medicineAdded,
          title: s.notifMedAddedTitle(med.name),
          message: s.notifMedAddedMsg(med.dosage, '${med.currentStock} ${med.unit}', s.foodInstructionName(med.instruction.name)),
          medicineId: med.id,
          medicineName: med.name,
          timestamp: med.createdAt,
          isRead: true,
          metadata: {
            'dosage': med.dosage,
            'stock': med.currentStock,
            'unit': med.unit,
            'instruction': med.instruction.name,
          },
        );
        await _db.insertNotification(addNotif);

        if (med.isLowStock || med.isOutOfStock) {
          final lowStockNotif = AppNotification(
            id: _uuid.v4(),
            type: NotificationType.lowStock,
            title: s.notifLowStockTitle(med.name),
            message: s.notifLowStockWarningMsg(med.currentStock, med.unit),
            medicineId: med.id,
            medicineName: med.name,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: true,
            metadata: {
              'stock': med.currentStock,
              'unit': med.unit,
            },
          );
          await _db.insertNotification(lowStockNotif);
        }
      }

      // Backfill from intake records
      final allRecords = _recordsByDoseKey.values.toList();
      for (final rec in allRecords) {
        final med = _medicines.cast<Medicine?>().firstWhere(
          (m) => m?.id == rec.medicineId,
          orElse: () => null,
        );
        final medName = med?.name ?? 'Medicine';
        final timeStr = '${rec.scheduledHour.toString().padLeft(2, '0')}:${rec.scheduledMinute.toString().padLeft(2, '0')}';

        if (rec.status == IntakeStatus.taken) {
          final n = AppNotification(
            id: _uuid.v4(),
            type: NotificationType.doseTaken,
            title: s.notifDoseTakenTitle(medName),
            message: s.notifDoseTakenMsg(med?.dosage ?? '', timeStr),
            medicineId: rec.medicineId,
            medicineName: medName,
            timestamp: rec.recordedAt,
            isRead: true,
            metadata: {
              'dosage': med?.dosage ?? '',
              'time': timeStr,
            },
          );
          await _db.insertNotification(n);
        } else if (rec.status == IntakeStatus.skipped) {
          final n = AppNotification(
            id: _uuid.v4(),
            type: NotificationType.doseSkipped,
            title: s.notifDoseSkippedTitle(medName),
            message: s.notifDoseSkippedMsg(med?.dosage ?? '', timeStr),
            medicineId: rec.medicineId,
            medicineName: medName,
            timestamp: rec.recordedAt,
            isRead: true,
            metadata: {
              'dosage': med?.dosage ?? '',
              'time': timeStr,
            },
          );
          await _db.insertNotification(n);
        } else if (rec.status == IntakeStatus.missed) {
          final n = AppNotification(
            id: _uuid.v4(),
            type: NotificationType.doseMissed,
            title: s.notifDoseMissedTitle(medName),
            message: s.notifDoseMissedMsg(med?.dosage ?? '', timeStr),
            medicineId: rec.medicineId,
            medicineName: medName,
            timestamp: rec.recordedAt,
            isRead: true,
            metadata: {
              'dosage': med?.dosage ?? '',
              'time': timeStr,
            },
          );
          await _db.insertNotification(n);
        }
      }
    } catch (e) {
      debugPrint('Backfill notice: $e');
    }
  }

  Future<void> logAppNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? medicineId,
    String? medicineName,
    String? profileName,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notif = AppNotification(
        id: _uuid.v4(),
        type: type,
        title: title,
        message: message,
        medicineId: medicineId,
        medicineName: medicineName,
        profileName: profileName ?? _activeProfile?.name,
        timestamp: timestamp ?? DateTime.now(),
        isRead: false,
        metadata: metadata,
      );
      await _db.insertNotification(notif);
      _notificationsList.insert(0, notif);
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }

  /// Mark notification hub as viewed/read, resetting the notification bell alert dot
  Future<void> markNotificationHubAsRead() async {
    _lastNotificationHubViewedAt = DateTime.now();
    try {
      await _db.markAllNotificationsAsRead();
      _notificationsList = _notificationsList.map((n) => n.copyWith(isRead: true)).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_notification_hub_viewed_at',
        _lastNotificationHubViewedAt!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Notice persisting notification hub viewed timestamp: $e');
    }
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    try {
      await _db.clearAllNotifications();
      _notificationsList.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  // ==================== ACTIONS ====================

  void switchProfile(UserProfile? profile) {
    _activeProfile = profile;
    _invalidateCaches();
    notifyListeners();
  }

  void selectDate(DateTime date) async {
    _selectedDate = date;
    _cachedDosesForSelectedDate = null;
    await _refreshRecords();
    if (DateUtils.isSameDay(date, DateTime.now())) {
      await autoSkipPastDueDoses();
    }
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
    String? unit,
    required String notes,
    required List<ReminderTime> reminderTimes,
    String? profileId,
    int durationDays = 0,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? expiryDate,
    String? photoPath,
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
      unit: unit ?? type.defaultUnit,
      notes: notes,
      createdAt: DateTime.now(),
      durationDays: durationDays,
      startDate: startDate,
      endDate: endDate,
      expiryDate: expiryDate,
      photoPath: photoPath,
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
    final s = await _getStrings();
    await logAppNotification(
      type: NotificationType.medicineAdded,
      title: s.notifMedAddedTitle(name),
      message: s.notifMedAddedMsg(dosage, '$currentStock ${unit ?? type.defaultUnit}', s.foodInstructionName(instruction.name)),
      medicineId: medId,
      medicineName: name,
      metadata: {
        'dosage': dosage,
        'stock': currentStock,
        'unit': unit ?? type.defaultUnit,
        'instruction': instruction.name,
      },
    );
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
    final s = await _getStrings();
    await logAppNotification(
      type: NotificationType.medicineUpdated,
      title: s.notifMedUpdatedTitle(medicine.name),
      message: s.notifMedUpdatedMsg(medicine.dosage, medicine.currentStock, medicine.unit),
      medicineId: medicine.id,
      medicineName: medicine.name,
      metadata: {
        'dosage': medicine.dosage,
        'stock': medicine.currentStock,
        'unit': medicine.unit,
      },
    );
    notifyListeners();
  }

  Future<void> updateReminderTime({
    required Medicine medicine,
    required ReminderTime oldReminder,
    required int newHour,
    required int newMinute,
    List<int>? daysOfWeek,
    bool? isAlarm,
  }) async {
    final currentReminders = List<ReminderTime>.from(_remindersByMedicine[medicine.id] ?? []);
    final idx = currentReminders.indexWhere((r) => r.id == oldReminder.id);
    if (idx >= 0) {
      currentReminders[idx] = ReminderTime(
        id: oldReminder.id,
        medicineId: medicine.id,
        hour: newHour,
        minute: newMinute,
        daysOfWeek: daysOfWeek ?? oldReminder.daysOfWeek,
        isAlarm: isAlarm ?? oldReminder.isAlarm,
        notificationId: oldReminder.notificationId,
      );
      currentReminders.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      await updateMedicine(medicine: medicine, reminders: currentReminders);
    }
  }

  Future<void> addReminderTimeToMedicine({
    required Medicine medicine,
    required int hour,
    required int minute,
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    bool isAlarm = true,
  }) async {
    final currentReminders = List<ReminderTime>.from(_remindersByMedicine[medicine.id] ?? []);
    final newRem = ReminderTime(
      id: _uuid.v4(),
      medicineId: medicine.id,
      hour: hour,
      minute: minute,
      daysOfWeek: daysOfWeek,
      isAlarm: isAlarm,
      notificationId: DateTime.now().millisecondsSinceEpoch % 100000,
    );
    currentReminders.add(newRem);
    currentReminders.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    await updateMedicine(medicine: medicine, reminders: currentReminders);
  }

  Future<void> deleteReminderTimeFromMedicine({
    required Medicine medicine,
    required ReminderTime reminder,
  }) async {
    final currentReminders = List<ReminderTime>.from(_remindersByMedicine[medicine.id] ?? []);
    currentReminders.removeWhere((r) => r.id == reminder.id);
    await updateMedicine(medicine: medicine, reminders: currentReminders);
  }

  Future<void> toggleMedicineActive(Medicine medicine) async {
    final updated = medicine.copyWith(isActive: !medicine.isActive);
    final reminders = _remindersByMedicine[medicine.id] ?? [];
    await updateMedicine(medicine: updated, reminders: reminders);
  }

  Future<void> updateMedicineStock(Medicine medicine, int newStock) async {
    final updated = medicine.copyWith(currentStock: newStock);
    final reminders = _remindersByMedicine[medicine.id] ?? [];
    await updateMedicine(medicine: updated, reminders: reminders);
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

  Future<void> clearIntakeHistory() async {
    await _db.clearAllHistory();
    await _refreshRecords();
    notifyListeners();
  }

  Future<void> deleteAllAppData() async {
    // Cancel all alarms
    await _notifications.cancelAll();
    await _db.deleteAllData();
    await _refreshMedicinesAndReminders();
    await _refreshRecords();
    notifyListeners();
  }

  /// Refreshes all data and schedules after a local JSON backup is restored
  Future<void> reloadAfterRestore() async {
    _profiles = await _db.getAllProfiles();
    await _refreshMedicinesAndReminders();
    await rescheduleAllActiveReminders();
    await _refreshRecords();
    await refreshNotifications();
    _invalidateCaches();
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
        final s = await _getStrings();
        await logAppNotification(
          type: NotificationType.lowStock,
          title: s.notifLowStockTitle(updatedMed.name),
          message: s.notifLowStockWarningMsg(updatedMed.currentStock, updatedMed.unit),
          medicineId: updatedMed.id,
          medicineName: updatedMed.name,
          metadata: {
            'stock': updatedMed.currentStock,
            'unit': updatedMed.unit,
          },
        );
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
    _cachedMissedDoses = null;

    // Dismiss active reminders for this dose
    await _notifications.dismissActiveReminderNotification(reminder: reminder);

    final s = await _getStrings();
    await logAppNotification(
      type: NotificationType.doseTaken,
      title: s.notifDoseTakenTitle(medicine.name),
      message: s.notifDoseTakenMsg(medicine.dosage, reminder.formattedTime),
      medicineId: medicine.id,
      medicineName: medicine.name,
      metadata: {
        'dosage': medicine.dosage,
        'time': reminder.formattedTime,
      },
    );

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
      await _refreshMedicinesAndReminders();
    } catch (_) {}
    _recordsByDoseKey[key] = record;
    _cachedMissedDoses = null;

    // Dismiss active reminders for this dose
    await _notifications.dismissActiveReminderNotification(reminder: reminder);

    final s = await _getStrings();
    await logAppNotification(
      type: NotificationType.doseSkipped,
      title: s.notifDoseSkippedTitle(medicine.name),
      message: s.notifDoseSkippedMsg(medicine.dosage, reminder.formattedTime),
      medicineId: medicine.id,
      medicineName: medicine.name,
      metadata: {
        'dosage': medicine.dosage,
        'time': reminder.formattedTime,
      },
    );

    notifyListeners();
  }

  Future<void> resetDoseToPending(Medicine medicine, ReminderTime reminder, DateTime date) async {
    NotificationService.triggerHaptic(isSuccess: true);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = '${medicine.id}_${reminder.id}_$dateStr';

    try {
      await _db.deleteIntakeRecord(medicine.id, reminder.id, dateStr);
      await _refreshMedicinesAndReminders();
    } catch (_) {}
    _recordsByDoseKey.remove(key);
    _cachedMissedDoses = null;

    if (medicine.isActive) {
      await _notifications.scheduleMedicineReminder(medicine, reminder);
    }

    notifyListeners();
  }

  Future<void> snoozeDose(Medicine medicine, ReminderTime reminder, {int minutes = 10}) async {
    NotificationService.triggerHaptic(isSuccess: false);
    try {
      final payload = jsonEncode({
        'medicineId': medicine.id,
        'medicineName': medicine.name,
        'dosage': medicine.dosage,
        'medicineType': medicine.type.name,
        'colorValue': medicine.colorValue,
        'photoPath': medicine.photoPath,
        'reminderTimeId': reminder.id,
        'isAlarm': reminder.isAlarm,
        'isSnooze': true,
        'dayOfWeek': DateTime.now().weekday,
      });

      await _notifications.snoozeReminder(
        medicine.name,
        medicine.dosage,
        payload,
        minutes: minutes,
        type: medicine.type,
        colorValue: medicine.colorValue,
        photoPath: medicine.photoPath,
        medicineId: medicine.id,
        reminderTimeId: reminder.id,
      );
      final s = await _getStrings();
      await logAppNotification(
        type: NotificationType.doseSnoozed,
        title: s.notifDoseSnoozedTitle(medicine.name),
        message: s.notifDoseSnoozedMsg(minutes, reminder.formattedTime),
        medicineId: medicine.id,
        medicineName: medicine.name,
        metadata: {
          'minutes': minutes,
          'time': reminder.formattedTime,
        },
      );
    } catch (e) {
      debugPrint('Error in snoozeDose: $e');
    }
  }


  Future<void> refillStock(String medicineId, int addedQuantity) async {
    try {
      final med = await _db.getMedicineById(medicineId);
      if (med != null) {
        final newStock = med.currentStock + addedQuantity;
        await _db.updateStock(medicineId, newStock);
        final s = await _getStrings();
        await logAppNotification(
          type: NotificationType.refillAdded,
          title: s.notifRefillAddedTitle(med.name),
          message: s.notifRefillMsg(addedQuantity, newStock, med.unit),
          medicineId: med.id,
          medicineName: med.name,
          metadata: {
            'added': addedQuantity,
            'stock': newStock,
            'unit': med.unit,
          },
        );
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
      colorValue: colorValue ?? 0xFF0D9488,
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

  /// Calculates the time when a time slot officially finishes for a given date
  DateTime getSlotEndTime(TimeSlot slot, DateTime date) {
    switch (slot) {
      case TimeSlot.morning:
        return DateTime(date.year, date.month, date.day, 12, 0);
      case TimeSlot.lunch:
        return DateTime(date.year, date.month, date.day, 15, 30);
      case TimeSlot.afternoon:
        return DateTime(date.year, date.month, date.day, 18, 0);
      case TimeSlot.evening:
        return DateTime(date.year, date.month, date.day, 20, 30);
      case TimeSlot.night:
        return DateTime(date.year, date.month, date.day, 5, 0).add(const Duration(days: 1));
    }
  }

  /// Automatically marks past unrecorded doses as skipped:
  /// 1. Past unrecorded doses from earlier dates (up to 7 days prior) when [checkPastDays] is true.
  /// 2. Today's doses whose time slot has ended, OR where a subsequent scheduled dose's time has arrived.
  Future<void> autoSkipPastDueDoses({bool checkPastDays = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool changed = false;

    // 1. Sweep past dates (yesterday and earlier unrecorded doses) only on initial launch / date change
    if (checkPastDays) {
      for (int i = 1; i <= 7; i++) {
        final pastDate = today.subtract(Duration(days: i));
        final pastDoses = getDosesForDate(pastDate);
        for (final dose in pastDoses) {
          if (dose.isTaken || dose.isSkipped) continue;

          final dateStr = DateFormat('yyyy-MM-dd').format(pastDate);
          final key = '${dose.medicine.id}_${dose.reminder.id}_$dateStr';
          final record = IntakeRecord(
            id: _uuid.v4(),
            medicineId: dose.medicine.id,
            reminderTimeId: dose.reminder.id,
            scheduledDate: dateStr,
            scheduledHour: dose.reminder.hour,
            scheduledMinute: dose.reminder.minute,
            status: IntakeStatus.missed,
            notes: 'auto_missed',
            recordedAt: now,
          );

          try {
            await _db.recordIntake(record);
          } catch (_) {}
          _recordsByDoseKey[key] = record;
          await _notifications.dismissActiveReminderNotification(reminder: dose.reminder);
          changed = true;
        }
      }
    }

    // 2. Today's doses
    final todayDoses = getDosesForDate(today);
    // Sort chronologically by hour and minute
    todayDoses.sort((a, b) {
      final compHour = a.reminder.hour.compareTo(b.reminder.hour);
      if (compHour != 0) return compHour;
      return a.reminder.minute.compareTo(b.reminder.minute);
    });

    for (int i = 0; i < todayDoses.length; i++) {
      final dose = todayDoses[i];
      if (dose.isTaken || dose.isSkipped || dose.isAutoMissed) continue;

      final slotEnd = getSlotEndTime(dose.reminder.timeSlot, today);
      final shouldAutoSkip = now.isAfter(slotEnd);

      if (shouldAutoSkip) {
        final dateStr = DateFormat('yyyy-MM-dd').format(today);
        final key = '${dose.medicine.id}_${dose.reminder.id}_$dateStr';
        final record = IntakeRecord(
          id: _uuid.v4(),
          medicineId: dose.medicine.id,
          reminderTimeId: dose.reminder.id,
          scheduledDate: dateStr,
          scheduledHour: dose.reminder.hour,
          scheduledMinute: dose.reminder.minute,
          status: IntakeStatus.missed,
          notes: 'auto_missed',
          recordedAt: now,
        );

        try {
          await _db.recordIntake(record);
        } catch (_) {}
        _recordsByDoseKey[key] = record;
        await _notifications.dismissActiveReminderNotification(reminder: dose.reminder);
        final s = await _getStrings();
        await logAppNotification(
          type: NotificationType.doseMissed,
          title: s.notifDoseMissedTitle(dose.medicine.name),
          message: s.notifDoseMissedMsg(dose.medicine.dosage, dose.reminder.formattedTime),
          medicineId: dose.medicine.id,
          medicineName: dose.medicine.name,
          metadata: {
            'dosage': dose.medicine.dosage,
            'time': dose.reminder.formattedTime,
          },
        );
        changed = true;
      }
    }

    if (changed) {
      _invalidateCaches();
      notifyListeners();
    }
  }

  /// Returns all missed doses across the past 7 days and today (elapsed/missed doses)
  /// that have not been manually taken or skipped. Memoized for high performance during build.
  List<ScheduledDose> getMissedDoses({int daysBack = 7}) {
    if (daysBack == 7 && _cachedMissedDoses != null) {
      return _cachedMissedDoses!;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<ScheduledDose> missed = [];

    // 1. Check today's doses that are missed
    final todayDoses = getDosesForDate(today);
    for (final dose in todayDoses) {
      if (!dose.medicine.isActive) continue;
      if (dose.isAutoMissed) {
        missed.add(dose);
      }
    }

    // 2. Check past dates (yesterday and earlier up to daysBack)
    for (int i = 1; i <= daysBack; i++) {
      final pastDate = today.subtract(Duration(days: i));
      final pastDoses = getDosesForDate(pastDate);
      for (final dose in pastDoses) {
        if (!dose.medicine.isActive) continue;
        if (dose.isAutoMissed || (dose.record == null && !dose.isTaken && !dose.isSkipped)) {
          missed.add(dose);
        }
      }
    }

    // Sort: most recent first
    missed.sort((a, b) {
      final compDate = b.scheduledDate.compareTo(a.scheduledDate);
      if (compDate != 0) return compDate;
      final compHour = b.reminder.hour.compareTo(a.reminder.hour);
      if (compHour != 0) return compHour;
      return b.reminder.minute.compareTo(a.reminder.minute);
    });

    if (daysBack == 7) {
      _cachedMissedDoses = missed;
    }
    return missed;
  }
}
