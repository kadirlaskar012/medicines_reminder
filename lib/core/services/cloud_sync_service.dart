import 'package:flutter/foundation.dart';
import '../../models/medicine.dart';
import '../../models/user_profile.dart';
import '../../models/intake_record.dart';
import 'supabase_service.dart';

class CloudSyncService {
  CloudSyncService._internal();
  static final CloudSyncService instance = CloudSyncService._internal();

  SupabaseService get _supabase => SupabaseService.instance;

  String? get _userPhone => _supabase.currentUser?.phoneNumber;

  /// Sync all current local data (medicines, reminders, records) to Supabase
  Future<void> syncLocalToCloud({
    required List<UserProfile> profiles,
    required List<Medicine> medicines,
    required List<IntakeRecord> records,
  }) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || client == null) return;

    try {
      // 1. Sync Medicines to Supabase user_medicines table
      for (final med in medicines) {
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
            'is_active': med.isActive,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
        );
      }

      // 2. Sync Recent Intake Logs
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

      debugPrint('CloudSyncService: Local data synced successfully with Supabase.');
    } catch (e) {
      debugPrint('CloudSyncService Supabase sync note: $e');
    }
  }

  /// Push a single medicine to Supabase
  Future<void> saveMedicine(Medicine medicine) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || client == null) return;

    try {
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
        'is_active': medicine.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('CloudSyncService saveMedicine note: $e');
    }
  }

  /// Remove a medicine from Supabase
  Future<void> deleteMedicine(String medicineId) async {
    final client = _supabase.client;
    if (client == null) return;

    try {
      await client.from('user_medicines').delete().eq('id', medicineId);
    } catch (e) {
      debugPrint('CloudSyncService deleteMedicine note: $e');
    }
  }

  /// Push a single profile to Supabase
  Future<void> saveProfile(UserProfile profile) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || client == null) return;

    try {
      await client.from('app_users').update({
        'name': profile.name,
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', phone);
    } catch (e) {
      debugPrint('CloudSyncService saveProfile note: $e');
    }
  }

  /// Record dose intake event in Supabase
  Future<void> recordDoseIntake(IntakeRecord record) async {
    final phone = _userPhone;
    final client = _supabase.client;
    if (phone == null || client == null) return;

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
      debugPrint('CloudSyncService recordDoseIntake note: $e');
    }
  }
}
