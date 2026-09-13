import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_strings.dart';

enum TimeSlot {
  morning('Morning', '06:00 AM - 12:00 PM', Icons.wb_sunny_rounded, Color(0xFFF59E0B)),
  afternoon('Afternoon', '12:00 PM - 05:00 PM', Icons.light_mode_rounded, Color(0xFF3B82F6)),
  evening('Evening', '05:00 PM - 09:00 PM', Icons.wb_twilight_rounded, Color(0xFFF97316)),
  night('Night', '09:00 PM - 06:00 AM', Icons.bedtime_rounded, Color(0xFF6366F1));

  final String title;
  final String timeRange;
  final IconData icon;
  final Color color;
  const TimeSlot(this.title, this.timeRange, this.icon, this.color);
}

class ReminderTime {
  final String id;
  final String medicineId;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1 = Mon, 7 = Sun
  final bool isAlarm; // true = loud alarm screen, false = gentle notification
  final int notificationId;

  ReminderTime({
    required this.id,
    required this.medicineId,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isAlarm = true,
    required this.notificationId,
  });

  String get formattedTime {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  TimeSlot get timeSlot {
    if (hour >= 6 && hour < 12) {
      return TimeSlot.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeSlot.afternoon;
    } else if (hour >= 17 && hour < 21) {
      return TimeSlot.evening;
    } else {
      return TimeSlot.night;
    }
  }

  bool get isDaily => daysOfWeek.length == 7;

  String get recurrenceSummary {
    if (isDaily) return 'Everyday';
    if (daysOfWeek.length == 5 && !daysOfWeek.contains(6) && !daysOfWeek.contains(7)) {
      return 'Weekdays';
    }
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  String recurrenceSummaryLocalized(AppStrings s) {
    if (isDaily) return s.everyday;
    if (daysOfWeek.length == 5 && !daysOfWeek.contains(6) && !daysOfWeek.contains(7)) {
      return s.weekdays;
    }
    final sorted = List<int>.from(daysOfWeek)..sort();
    return sorted.map((d) => s.weekdayShort(d)).join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'hour': hour,
      'minute': minute,
      'daysOfWeek': daysOfWeek.join(','),
      'isAlarm': isAlarm ? 1 : 0,
      'notificationId': notificationId,
    };
  }

  factory ReminderTime.fromMap(Map<String, dynamic> map) {
    final rawDays = (map['daysOfWeek'] as String? ?? '1,2,3,4,5,6,7')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s) ?? 1)
        .toList();

    return ReminderTime(
      id: map['id'] as String,
      medicineId: map['medicineId'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      daysOfWeek: rawDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : rawDays,
      isAlarm: (map['isAlarm'] as int? ?? 1) == 1,
      notificationId: map['notificationId'] as int,
    );
  }
}
