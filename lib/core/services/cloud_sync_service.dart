import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../../models/user_profile.dart';
import '../../models/intake_record.dart';
import '../database/db_helper.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class CloudSyncService {
  CloudSyncService._internal();
  static final CloudSyncService instance = CloudSyncService._internal();

  SupabaseService get _supabase => SupabaseService.instance;

  String? get _userPhone => _supabase.currentUser?.phoneNumber;

  /// Sync all current local data (profiles, medicines, reminders, records) to Supabase
  Future<bool> syncLocalToCloud({
    required List<UserProfile> profiles,
    required List<Medicine> medicines,
    required Map<String, List<ReminderTime>> remindersByMedicine,
    required List<IntakeRecord> records,
  }) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || phone.isEmpty || client == null) {
      debugPrint('CloudSyncService: Skipping sync - user not logged in or client null');
      return false;
    }

    try {
      // 1. Sync User Profiles
      for (final profile in profiles) {
        await client.from('app_users').upsert(
          {
            'phone_number': phone,
            'name': profile.name,
            'is_verified': true,
            'last_login': DateTime.now().toIso8601String(),
          },
          onConflict: 'phone_number',
        );
      }

      // 2. Sync Medicines with complete reminders JSON to user_medicines table
      for (final med in medicines) {
        final reminders = remindersByMedicine[med.id] ?? [];
        final remindersJson = jsonEncode(reminders.map((r) => r.toMap()).toList());

        await client.from('user_medicines').upsert(
          {
            'id': med.id,
            'phone_number': phone,
            'profile_id': med.profileId,
            'name': med.name,
            'dosage': med.dosage,
            'type': med.type.name,
            'color_value': med.colorValue,
            'instruction': med.instruction.name,
            'current_stock': med.currentStock,
            'refill_threshold': med.refillThreshold,
            'notes': med.notes,
            'is_active': med.isActive,
            'created_at': med.createdAt.toIso8601String(),
            'duration_days': med.durationDays,
            'start_date': med.startDate?.toIso8601String(),
            'end_date': med.endDate?.toIso8601String(),
            'expiry_date': med.expiryDate?.toIso8601String(),
            'photo_path': med.photoPath,
            'reminders_json': remindersJson,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
        );

        // Also upsert each reminder into user_reminders table for normalized queries
        for (final r in reminders) {
          await client.from('user_reminders').upsert(
            {
              'id': r.id,
              'medicine_id': med.id,
              'phone_number': phone,
              'time': '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}',
              'hour': r.hour,
              'minute': r.minute,
              'days_of_week': r.daysOfWeek.join(','),
              'is_alarm': r.isAlarm,
              'notification_id': r.notificationId,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'id',
          );
        }
      }

      // 3. Sync Recent Intake Logs
      final recentRecords = records.length > 50 ? records.sublist(records.length - 50) : records;
      for (final rec in recentRecords) {
        final schedTimeStr = '${rec.scheduledDate}T${rec.scheduledHour.toString().padLeft(2, '0')}:${rec.scheduledMinute.toString().padLeft(2, '0')}:00Z';
        await client.from('user_dose_logs').upsert(
          {
            'id': rec.id,
            'phone_number': phone,
            'medicine_id': rec.medicineId,
            'scheduled_time': schedTimeStr,
            'status': rec.status.name,
            'taken_at': rec.recordedAt.toIso8601String(),
            'synced_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
        );
      }

      debugPrint('CloudSyncService: Local data synced successfully with Supabase for $phone');
      return true;
    } catch (e) {
      debugPrint('CloudSyncService syncLocalToCloud error: $e');
      return false;
    }
  }

  /// RESTORE FROM CLOUD: Pulls all medicines and reminders from Supabase and restores into local SQLite
  Future<int> restoreFromCloud({
    required String phoneNumber,
    required DBHelper db,
    required NotificationService notifications,
  }) async {
    final client = _supabase.client;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (client == null || cleanPhone.isEmpty) {
      debugPrint('CloudSyncService: Cannot restore - Supabase client null or empty phone');
      return 0;
    }

    try {
      debugPrint('CloudSyncService: Restoring cloud data for phone $cleanPhone...');

      // 1. Restore Profile Name if available in Supabase
      try {
        final userRow = await client.from('app_users').select().eq('phone_number', cleanPhone).maybeSingle();
        if (userRow != null && userRow['name'] != null) {
          final cloudName = userRow['name'].toString().trim();
          if (cloudName.isNotEmpty && cloudName != 'User' && cloudName != 'Patient') {
            final profiles = await db.getAllProfiles();
            if (profiles.isNotEmpty) {
              final updatedProfile = profiles.first.copyWith(name: cloudName);
              await db.insertProfile(updatedProfile);
            }
          }
        }
      } catch (e) {
        debugPrint('CloudSyncService: Error restoring user profile: $e');
      }

      // 2. Fetch and restore medicines
      final List<dynamic> rows = await client
          .from('user_medicines')
          .select()
          .eq('phone_number', cleanPhone);

      if (rows.isEmpty) {
        debugPrint('CloudSyncService: No cloud medicines found for $cleanPhone');
        return 0;
      }

      int restoredCount = 0;
      for (final row in rows) {
        final map = row as Map<String, dynamic>;
        
        final med = Medicine(
          id: map['id']?.toString() ?? '',
          profileId: map['profile_id']?.toString() ?? 'default_me',
          name: map['name']?.toString() ?? 'Medicine',
          dosage: map['dosage']?.toString() ?? '',
          type: MedicineType.values.firstWhere(
            (t) => t.name == map['type'],
            orElse: () => MedicineType.tablet,
          ),
          colorValue: (map['color_value'] as num?)?.toInt() ?? 0xFF0D9488,
          instruction: FoodInstruction.values.firstWhere(
            (i) => i.name == map['instruction'],
            orElse: () => FoodInstruction.afterMeal,
          ),
          currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
          refillThreshold: (map['refill_threshold'] as num?)?.toInt() ?? 5,
          isActive: map['is_active'] == true || map['is_active'] == 1,
          notes: map['notes']?.toString() ?? '',
          createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) ?? DateTime.now() : DateTime.now(),
          durationDays: (map['duration_days'] as num?)?.toInt() ?? 0,
          startDate: map['start_date'] != null ? DateTime.tryParse(map['start_date']) : null,
          endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date']) : null,
          expiryDate: map['expiry_date'] != null ? DateTime.tryParse(map['expiry_date']) : null,
          photoPath: map['photo_path']?.toString(),
        );

        // Reconstruct reminders
        List<ReminderTime> reminders = [];
        if (map['reminders_json'] != null && map['reminders_json'].toString().isNotEmpty) {
          try {
            final decoded = jsonDecode(map['reminders_json'].toString()) as List<dynamic>;
            reminders = decoded.map((r) => ReminderTime.fromMap(r as Map<String, dynamic>)).toList();
          } catch (e) {
            debugPrint('CloudSyncService: Error decoding reminders_json: $e');
          }
        }

        // If reminders_json was empty, try fetching from user_reminders table
        if (reminders.isEmpty) {
          try {
            final List<dynamic> remRows = await client
                .from('user_reminders')
                .select()
                .eq('medicine_id', med.id);
            for (final remRow in remRows) {
              final rMap = remRow as Map<String, dynamic>;
              final daysStr = rMap['days_of_week']?.toString() ?? '1,2,3,4,5,6,7';
              final days = daysStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toList();
              reminders.add(ReminderTime(
                id: rMap['id']?.toString() ?? '',
                medicineId: med.id,
                hour: (rMap['hour'] as num?)?.toInt() ?? 8,
                minute: (rMap['minute'] as num?)?.toInt() ?? 0,
                daysOfWeek: days,
                isAlarm: rMap['is_alarm'] == true || rMap['is_alarm'] == 1,
                notificationId: (rMap['notification_id'] as num?)?.toInt() ?? (med.id.hashCode.abs() % 100000),
              ));
            }
          } catch (e) {
            debugPrint('CloudSyncService: Error querying user_reminders: $e');
          }
        }

        // Insert into local SQLite database
        await db.insertMedicine(med, reminders);

        // Reschedule notifications for active medicines
        if (med.isActive) {
          for (final rem in reminders) {
            await notifications.scheduleMedicineReminder(med, rem);
          }
        }

        restoredCount++;
      }

      debugPrint('CloudSyncService: Successfully restored $restoredCount medicines from cloud for $cleanPhone');
      return restoredCount;
    } catch (e) {
      debugPrint('CloudSyncService restoreFromCloud error: $e');
      return 0;
    }
  }

  /// Push a single medicine to Supabase in background
  Future<void> saveMedicine({
    required Medicine medicine,
    required List<ReminderTime> reminders,
  }) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || phone.isEmpty || client == null) return;

    try {
      final remindersJson = jsonEncode(reminders.map((r) => r.toMap()).toList());

      await client.from('user_medicines').upsert({
        'id': medicine.id,
        'phone_number': phone,
        'profile_id': medicine.profileId,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'type': medicine.type.name,
        'color_value': medicine.colorValue,
        'instruction': medicine.instruction.name,
        'current_stock': medicine.currentStock,
        'refill_threshold': medicine.refillThreshold,
        'notes': medicine.notes,
        'is_active': medicine.isActive,
        'created_at': medicine.createdAt.toIso8601String(),
        'duration_days': medicine.durationDays,
        'start_date': medicine.startDate?.toIso8601String(),
        'end_date': medicine.endDate?.toIso8601String(),
        'expiry_date': medicine.expiryDate?.toIso8601String(),
        'photo_path': medicine.photoPath,
        'reminders_json': remindersJson,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      for (final r in reminders) {
        await client.from('user_reminders').upsert({
          'id': r.id,
          'medicine_id': medicine.id,
          'phone_number': phone,
          'time': '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}',
          'hour': r.hour,
          'minute': r.minute,
          'days_of_week': r.daysOfWeek.join(','),
          'is_alarm': r.isAlarm,
          'notification_id': r.notificationId,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      }
    } catch (e) {
      debugPrint('CloudSyncService saveMedicine error: $e');
    }
  }

  /// Remove a medicine from Supabase
  Future<void> deleteMedicine(String medicineId) async {
    final client = _supabase.client;
    if (client == null) return;

    try {
      await client.from('user_reminders').delete().eq('medicine_id', medicineId);
      await client.from('user_medicines').delete().eq('id', medicineId);
    } catch (e) {
      debugPrint('CloudSyncService deleteMedicine error: $e');
    }
  }

  /// Push a single profile to Supabase
  Future<void> saveProfile(UserProfile profile) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || phone.isEmpty || client == null) return;

    try {
      await client.from('app_users').update({
        'name': profile.name,
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', phone);
    } catch (e) {
      debugPrint('CloudSyncService saveProfile error: $e');
    }
  }

  /// Record dose intake event in Supabase
  Future<void> recordDoseIntake(IntakeRecord record) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || phone.isEmpty || client == null) return;

    try {
      final schedTimeStr = '${record.scheduledDate}T${record.scheduledHour.toString().padLeft(2, '0')}:${record.scheduledMinute.toString().padLeft(2, '0')}:00Z';
      await client.from('user_dose_logs').upsert({
        'id': record.id,
        'phone_number': phone,
        'medicine_id': record.medicineId,
        'scheduled_time': schedTimeStr,
        'status': record.status.name,
        'taken_at': record.recordedAt.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('CloudSyncService recordDoseIntake error: $e');
    }
  }
}
