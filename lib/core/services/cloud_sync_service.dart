import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/medicine.dart';
import '../../models/user_profile.dart';
import '../../models/intake_record.dart';
import 'auth_service.dart';

class CloudSyncService {
  CloudSyncService._internal();
  static final CloudSyncService instance = CloudSyncService._internal();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized: $e');
      return null;
    }
  }

  String? get _currentUserId => AuthService.instance.userId;

  /// Sync all current local data (profiles, medicines, records) to Firestore
  Future<void> syncLocalToCloud({
    required List<UserProfile> profiles,
    required List<Medicine> medicines,
    required List<IntakeRecord> records,
  }) async {
    final uid = _currentUserId;
    final db = _firestore;
    if (uid == null || db == null) return;

    try {
      final userDoc = db.collection('users').doc(uid);

      // 1. Update user root document
      await userDoc.set({
        'lastSync': FieldValue.serverTimestamp(),
        'phoneNumber': AuthService.instance.userPhoneNumber ?? '',
      }, SetOptions(merge: true));

      final batch = db.batch();

      // 2. Profiles
      for (final profile in profiles) {
        final ref = userDoc.collection('profiles').doc(profile.id);
        batch.set(ref, profile.toMap(), SetOptions(merge: true));
      }

      // 3. Medicines
      for (final medicine in medicines) {
        final ref = userDoc.collection('medicines').doc(medicine.id);
        batch.set(ref, medicine.toMap(), SetOptions(merge: true));
      }

      // 4. Intake Records (recent 100 records)
      final recentRecords = records.length > 100 ? records.sublist(records.length - 100) : records;
      for (final record in recentRecords) {
        final ref = userDoc.collection('intake_records').doc(record.id);
        batch.set(ref, record.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('CloudSyncService: Successfully uploaded local data to Cloud Firestore.');
    } catch (e) {
      debugPrint('CloudSyncService error syncing local to cloud: $e');
    }
  }

  /// Push a single medicine to Firestore
  Future<void> saveMedicine(Medicine medicine) async {
    final uid = _currentUserId;
    final db = _firestore;
    if (uid == null || db == null) return;

    try {
      await db.collection('users').doc(uid).collection('medicines').doc(medicine.id).set(
        medicine.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('CloudSyncService saveMedicine error: $e');
    }
  }

  /// Remove a medicine from Firestore
  Future<void> deleteMedicine(String medicineId) async {
    final uid = _currentUserId;
    final db = _firestore;
    if (uid == null || db == null) return;

    try {
      await db.collection('users').doc(uid).collection('medicines').doc(medicineId).delete();
    } catch (e) {
      debugPrint('CloudSyncService deleteMedicine error: $e');
    }
  }

  /// Push a single profile to Firestore
  Future<void> saveProfile(UserProfile profile) async {
    final uid = _currentUserId;
    final db = _firestore;
    if (uid == null || db == null) return;

    try {
      await db.collection('users').doc(uid).collection('profiles').doc(profile.id).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('CloudSyncService saveProfile error: $e');
    }
  }

  /// Record an intake record to Firestore
  Future<void> saveIntakeRecord(IntakeRecord record) async {
    final uid = _currentUserId;
    final db = _firestore;
    if (uid == null || db == null) return;

    try {
      await db.collection('users').doc(uid).collection('intake_records').doc(record.id).set(
        record.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('CloudSyncService saveIntakeRecord error: $e');
    }
  }
}
