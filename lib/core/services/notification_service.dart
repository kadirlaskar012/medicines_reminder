import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';

// Top-level or static background action handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Notification background response: ${notificationResponse.actionId}');
  // Handled by system or database if needed
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  // Channels
  static const String alarmChannelId = 'med_alarm_channel_v1';
  static const String alarmChannelName = 'Medicine Alarms (Loud)';
  static const String alarmChannelDesc = 'Critical alarms for timely medicine intake';

  static const String gentleChannelId = 'med_gentle_channel_v1';
  static const String gentleChannelName = 'Medicine Notifications';
  static const String gentleChannelDesc = 'Gentle reminders for vitamins & supplements';

  static const String refillChannelId = 'med_refill_channel_v1';
  static const String refillChannelName = 'Refill & Stock Alerts';
  static const String refillChannelDesc = 'Alerts when your medicine stock is running low';

  // Action IDs
  static const String actionTaken = 'action_taken';
  static const String actionSnooze = 'action_snooze';
  static const String actionSkip = 'action_skip';

  Function(String payload, String? actionId)? onNotificationAction;

  Future<void> initialize({Function(String payload, String? actionId)? onAction}) async {
    if (_isInitialized) return;
    onNotificationAction = onAction;

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      debugPrint('NotificationService: Skipping mobile notifications on desktop/web.');
      _isInitialized = true;
      return;
    }

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = DateTime.now().timeZoneName;
      // In flutter, if local cannot be found by string, default to local
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (_) {
      // Fallback
      tz.setLocalLocation(tz.local);
    }

    // 2. Android Initialization Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    // 3. Initialize plugin
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          onNotificationAction?.call(response.payload!, response.actionId);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 4. Create Notification Channels for Android 8.0+
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          gentleChannelId,
          gentleChannelName,
          description: gentleChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          refillChannelId,
          refillChannelName,
          description: refillChannelDesc,
          importance: Importance.defaultImportance,
        ),
      );
    }

    _isInitialized = true;
  }

  // ==================== PERMISSIONS ====================
  Future<bool> requestPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    // 1. Android 13+ Notification Runtime Permission
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) return false;
    }

    // 2. Android 12+ / 14+ Exact Alarm Permission
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('Schedule exact alarm permission check skipped: $e');
    }

    // 3. Battery Optimizations Request
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Battery optimization ignore check skipped: $e');
    }

    return true;
  }

  // Check current permission statuses
  Future<Map<String, bool>> checkPermissionStatuses() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return {
        'notification': true,
        'exactAlarm': true,
        'batteryOptimization': true,
      };
    }

    final notifGranted = await Permission.notification.isGranted;
    bool exactAlarmGranted = true;
    try {
      exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {}

    bool batteryIgnored = false;
    try {
      batteryIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {}

    return {
      'notification': notifGranted,
      'exactAlarm': exactAlarmGranted,
      'batteryOptimization': batteryIgnored,
    };
  }

  // ==================== SCHEDULING ====================
  Future<void> scheduleMedicineReminder(Medicine medicine, ReminderTime reminder) async {
    final channelId = reminder.isAlarm ? alarmChannelId : gentleChannelId;
    final channelName = reminder.isAlarm ? alarmChannelName : gentleChannelName;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: reminder.isAlarm ? alarmChannelDesc : gentleChannelDesc,
      importance: reminder.isAlarm ? Importance.max : Importance.high,
      priority: reminder.isAlarm ? Priority.max : Priority.high,
      fullScreenIntent: reminder.isAlarm,
      category: reminder.isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      actions: const [
        AndroidNotificationAction(
          actionTaken,
          'TAKE',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          'SNOOZE 10M',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          'SKIP',
          cancelNotification: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final payload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dosage': medicine.dosage,
      'instruction': medicine.instruction.title,
      'reminderTimeId': reminder.id,
      'isAlarm': reminder.isAlarm,
    });

    // Schedule for each day in daysOfWeek
    for (final dayOfWeek in reminder.daysOfWeek) {
      final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, reminder.hour, reminder.minute);
      final uniqueNotificationId = reminder.notificationId * 10 + dayOfWeek;

      try {
        await _notificationsPlugin.zonedSchedule(
          id: uniqueNotificationId,
          title: 'Time for ${medicine.name} (${medicine.dosage})',
          body: 'Instruction: ${medicine.instruction.title}. Tap to confirm your dose.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Error scheduling exact reminder: $e');
        // Fallback to inexact allow while idle if exact alarm permission was not granted
        try {
          await _notificationsPlugin.zonedSchedule(
            id: uniqueNotificationId,
            title: 'Time for ${medicine.name} (${medicine.dosage})',
            body: 'Instruction: ${medicine.instruction.title}. Tap to confirm your dose.',
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        } catch (fallbackError) {
          debugPrint('Fallback scheduling also failed: $fallbackError');
        }
      }
    }
  }

  Future<void> cancelReminder(ReminderTime reminder) async {
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id: reminder.notificationId * 10 + day);
    }
  }

  Future<void> snoozeReminder(String medicineName, String dosage, String payload, {int minutes = 10}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: minutes));
    const snoozeId = 999999;

    const androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          actionTaken,
          'TAKE',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      id: snoozeId,
      title: 'Snoozed: $medicineName ($dosage)',
      body: 'Time to take your snoozed medicine dose now!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ==================== HAPTICS & SOUND ====================
  static void triggerHaptic({bool isSuccess = false}) {
    if (isSuccess) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.mediumImpact();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> showUpcomingCountdownNotification({
    required Medicine medicine,
    required ReminderTime reminder,
    required int minutesUntilDose,
  }) async {
    triggerHaptic(isSuccess: false);
    final payload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dosage': medicine.dosage,
      'instruction': medicine.instruction.title,
      'reminderTimeId': reminder.id,
      'isAlarm': reminder.isAlarm,
    });

    final androidDetails = AndroidNotificationDetails(
      gentleChannelId,
      gentleChannelName,
      channelDescription: gentleChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Ongoing notification for live countdown feel
      autoCancel: false,
      actions: const [
        AndroidNotificationAction(actionTaken, 'TAKE NOW', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction(actionSnooze, 'SNOOZE 10M', showsUserInterface: false),
      ],
    );

    await _notificationsPlugin.show(
      id: (medicine.name.hashCode.abs() % 10000) + 70000,
      title: '⏳ Upcoming in $minutesUntilDose min: ${medicine.name}',
      body: '${medicine.dosage} scheduled at ${reminder.formattedTime} (${medicine.instruction.title})',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> showStockForecastAlert(Medicine medicine, int daysLeft, String runOutDateStr) async {
    const androidDetails = AndroidNotificationDetails(
      refillChannelId,
      refillChannelName,
      channelDescription: refillChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: '📦 Refill Alert: ${medicine.name}',
      body: 'Will run out in $daysLeft days ($runOutDateStr). Remaining: ${medicine.currentStock} units.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showRefillAlert(Medicine medicine) async {
    const androidDetails = AndroidNotificationDetails(
      refillChannelId,
      refillChannelName,
      channelDescription: refillChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: '⚠️ Low Stock: ${medicine.name}',
      body: 'Only ${medicine.currentStock} doses remaining! Please refill soon.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }


  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      actions: [
        AndroidNotificationAction(actionTaken, 'TAKE'),
        AndroidNotificationAction(actionSnooze, 'SNOOZE'),
      ],
    );

    await _notificationsPlugin.show(
      id: 1001,
      title: '🔔 MediRemind Test Alarm',
      body: 'Exact notifications and alarms are working properly!',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
