import 'medicine.dart';
import 'reminder_time.dart';
import 'intake_record.dart';

class ScheduledDose {
  final Medicine medicine;
  final ReminderTime reminder;
  final IntakeRecord? record;
  final DateTime scheduledDate;

  ScheduledDose({
    required this.medicine,
    required this.reminder,
    this.record,
    required this.scheduledDate,
  });

  bool get isTaken => record?.status == IntakeStatus.taken;
  bool get isSkipped => record?.status == IntakeStatus.skipped;
  bool get isSnoozed => record?.status == IntakeStatus.snoozed;
  bool get isAutoMissed => record?.status == IntakeStatus.missed || record?.notes == 'auto_missed';
  bool get isPending => record == null;

  bool get isOverdue {
    if (isTaken || isSkipped || isAutoMissed) return false;
    final now = DateTime.now();
    final doseTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      reminder.hour,
      reminder.minute,
    );
    return now.isAfter(doseTime);
  }

  /// Whether the scheduled time has arrived/passed or the dose was already recorded
  bool get isDueOrElapsed {
    if (isTaken || isSkipped || isAutoMissed) return true;
    return isOverdue;
  }

  /// Whether this dose is considered missed (scheduled time elapsed and not taken)
  bool get isMissed {
    if (isTaken || isSkipped) return false;
    if (isAutoMissed) return true;
    return isOverdue;
  }

  /// Whether this dose is scheduled for the future and not yet due
  bool get isUpcoming => !isTaken && !isMissed && !isSkipped;
}
