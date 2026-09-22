import 'dart:convert';
import '../core/localization/app_strings.dart';

enum NotificationType {
  doseTaken,
  doseSkipped,
  doseSnoozed,
  doseMissed,
  reminderDue,
  medicineAdded,
  medicineUpdated,
  refillAdded,
  lowStock,
  testAlarm,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? medicineId;
  final String? medicineName;
  final String? profileName;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.medicineId,
    this.medicineName,
    this.profileName,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  String localizedTitle(AppStrings s) {
    final med = medicineName ?? (metadata?['medicineName'] as String?) ?? '';
    switch (type) {
      case NotificationType.doseTaken:
        return s.notifDoseTakenTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.doseSkipped:
        return s.notifDoseSkippedTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.doseSnoozed:
        return s.notifDoseSnoozedTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.doseMissed:
        return s.notifDoseMissedTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.medicineAdded:
        return s.notifMedAddedTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.medicineUpdated:
        return s.notifMedUpdatedTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.refillAdded:
        return s.notifRefillTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.lowStock:
        return s.notifLowStockWarningTitle(med.isNotEmpty ? med : s.appName);
      case NotificationType.testAlarm:
        return s.notifTestTitle;
      case NotificationType.reminderDue:
        return s.notifTimeForMed(med.isNotEmpty ? med : s.appName, metadata?['dosage'] as String? ?? '');
    }
  }

  String localizedMessage(AppStrings s) {
    if (metadata != null && metadata!.isNotEmpty) {
      final dosage = metadata!['dosage'] as String? ?? '';
      final time = metadata!['time'] as String? ?? '';
      final instruction = metadata!['instruction'] as String? ?? '';
      final stock = metadata!['stock'] as int? ?? 0;
      final unit = metadata!['unit'] as String? ?? '';
      final minutes = metadata!['minutes'] as int? ?? 10;
      final added = metadata!['added'] as int? ?? 0;

      switch (type) {
        case NotificationType.doseTaken:
          return s.notifDoseTakenMsg(dosage, time);
        case NotificationType.doseSkipped:
          return s.notifDoseSkippedMsg(dosage, time);
        case NotificationType.doseSnoozed:
          return s.notifDoseSnoozedMsg(minutes, time);
        case NotificationType.doseMissed:
          return s.notifDoseMissedMsg(dosage, time);
        case NotificationType.medicineAdded:
          return s.notifMedAddedMsg(dosage, '${s.formatNumber(stock)} $unit', instruction);
        case NotificationType.medicineUpdated:
          return s.notifMedUpdatedMsg(dosage, stock, unit);
        case NotificationType.refillAdded:
          return s.notifRefillMsg(added, stock, unit);
        case NotificationType.lowStock:
          return s.notifLowStockWarningMsg(stock, unit);
        case NotificationType.testAlarm:
          return s.notifTestBody;
        case NotificationType.reminderDue:
          return s.notifTakeBody(instruction, time, dosage);
      }
    }

    // Fallback: If message contains legacy Bengali or English text, cleanly translate it
    String msg = message;
    if (s.code == 'en') {
      msg = msg.replaceAll('ডোজ:', 'Dose:')
               .replaceAll('মজুদ:', 'Stock:')
               .replaceAll('এর ডোজ গ্রহণ করা হয়েছে', 'dose taken')
               .replaceAll('এর ডোজ বাদ দেওয়া হয়েছে', 'dose skipped')
               .replaceAll('এর ডোজ মিস হয়েছে', 'dose missed')
               .replaceAll('এর ডোজ সময়মতো নেওয়া হয়নি', 'dose was not taken on time')
               .replaceAll('মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে', 'minutes reminder snoozed')
               .replaceAll('যোগ করা হয়েছে (মোট মজুদ:', 'added (Total stock:')
               .replaceAll('বর্তমান মজুদ মাত্র', 'Current stock only')
               .replaceAll('। দ্রুত রিফিল করুন।', '. Please refill soon.')
               .replaceAll('লকস্ক্রিন ও সিস্টেম নোটিফিকেশন টেস্ট সফলভাবে যাচাই করা হয়েছে।', 'Lock screen & system notification test verified.');
    } else if (s.code == 'hi') {
      msg = msg.replaceAll('ডোজ:', 'खुराक:')
               .replaceAll('মজুদ:', 'स्टॉक:')
               .replaceAll('এর ডোজ গ্রহণ করা হয়েছে', 'की खुराक ली गई')
               .replaceAll('এর ডোজ বাদ দেওয়া হয়েছে', 'की खुराक छोड़ दी गई')
               .replaceAll('এর ডোজ মিস হয়েছে', 'की खुराक छूट गई')
               .replaceAll('এর ডোজ সময়মতো নেওয়া হয়নি', 'की खुराक समय पर नहीं ली गई')
               .replaceAll('মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে', 'मिनट के लिए रिमाइंडर स्थगित किया गया')
               .replaceAll('যোগ করা হয়েছে (মোট মজুদ:', 'जोड़े गए (कुल स्टॉक:')
               .replaceAll('বর্তমান মজুদ মাত্র', 'वर्तमान स्टॉक केवल')
               .replaceAll('। দ্রুত রিফিল করুন।', '। कृपया शीघ्र रीफिल करें।')
               .replaceAll('লকস্ক্রিন ও সিস্টেম নোটিফিকেশন টেস্ট সফলভাবে যাচাই করা হয়েছে।', 'लॉकस्क्रीन और सिस्टम नोटिफिकेशन टेस्ट सफलतापूर्वक सत्यापित हुआ।');
    }
    return msg;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'profileName': profileName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    NotificationType nType = NotificationType.doseTaken;
    try {
      nType = NotificationType.values.byName(map['type'] as String? ?? 'doseTaken');
    } catch (_) {
      nType = NotificationType.doseTaken;
    }

    Map<String, dynamic>? meta;
    if (map['metadata'] != null && map['metadata'] is String && (map['metadata'] as String).isNotEmpty) {
      try {
        meta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AppNotification(
      id: map['id'] as String,
      type: nType,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      medicineId: map['medicineId'] as String?,
      medicineName: map['medicineName'] as String?,
      profileName: map['profileName'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      isRead: (map['isRead'] as int? ?? 0) == 1,
      metadata: meta,
    );
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? medicineId,
    String? medicineName,
    String? profileName,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      profileName: profileName ?? this.profileName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
