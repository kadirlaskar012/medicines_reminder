import 'dart:convert';

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
