import 'package:flutter/material.dart';

enum IntakeStatus {
  taken('Taken', Icons.check_circle_rounded, Color(0xFF10B981)),
  skipped('Skipped', Icons.cancel_rounded, Color(0xFF94A3B8)),
  snoozed('Snoozed', Icons.snooze_rounded, Color(0xFFF59E0B)),
  missed('Missed', Icons.error_rounded, Color(0xFFEF4444));

  final String label;
  final IconData icon;
  final Color color;
  const IntakeStatus(this.label, this.icon, this.color);

  static IntakeStatus fromString(String val) {
    return IntakeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => IntakeStatus.taken,
    );
  }
}

class IntakeRecord {
  final String id;
  final String medicineId;
  final String reminderTimeId;
  final String scheduledDate; // 'YYYY-MM-DD'
  final int scheduledHour;
  final int scheduledMinute;
  final IntakeStatus status;
  final DateTime recordedAt;
  final String? notes;

  IntakeRecord({
    required this.id,
    required this.medicineId,
    required this.reminderTimeId,
    required this.scheduledDate,
    required this.scheduledHour,
    required this.scheduledMinute,
    required this.status,
    required this.recordedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'reminderTimeId': reminderTimeId,
      'scheduledDate': scheduledDate,
      'scheduledHour': scheduledHour,
      'scheduledMinute': scheduledMinute,
      'status': status.name,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory IntakeRecord.fromMap(Map<String, dynamic> map) {
    return IntakeRecord(
      id: map['id'] as String,
      medicineId: map['medicineId'] as String,
      reminderTimeId: map['reminderTimeId'] as String,
      scheduledDate: map['scheduledDate'] as String,
      scheduledHour: map['scheduledHour'] as int,
      scheduledMinute: map['scheduledMinute'] as int,
      status: IntakeStatus.fromString(map['status'] as String? ?? 'taken'),
      recordedAt: DateTime.tryParse(map['recordedAt'] as String? ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
    );
  }
}
