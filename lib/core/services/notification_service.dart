import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/intake_record.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../database/db_helper.dart';
import '../localization/app_strings.dart';

/// Safely and accurately configures the device's true local timezone
Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezoneInfo.identifier;
    debugPrint('NotificationService: FlutterTimezone detected: $timeZoneName');
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Local location successfully set to $timeZoneName');
      return;
    } catch (locErr) {
      debugPrint('NotificationService: tz.getLocation failed for $timeZoneName: $locErr, trying offset fallback...');
    }
  } catch (e) {
    debugPrint('NotificationService: FlutterTimezone.getLocalTimezone error: $e');
  }

  // Fallback: match by local UTC offset
  final offset = DateTime.now().timeZoneOffset;
  debugPrint('NotificationService: Device UTC offset: $offset');
  if (offset.inMinutes == 330) {
    // IST: UTC+5:30 (India)
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  } else if (offset.inMinutes == 360) {
    // BST: UTC+6:00 (Bangladesh)
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
  } else if (offset.inMinutes == 300) {
    // PKT: UTC+5:00 (Pakistan)
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
  } else if (offset.inMinutes == 345) {
    // NPT: UTC+5:45 (Nepal)
    tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
  } else {
    try {
      bool found = false;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        final nowInLoc = tz.TZDateTime.now(loc);
        if (nowInLoc.timeZoneOffset == offset) {
          tz.setLocalLocation(loc);
          found = true;
          break;
        }
      }
      if (!found) {
        tz.setLocalLocation(tz.local);
      }
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }
  debugPrint('NotificationService: Final configured local timezone is: ${tz.local.name}');
}

// Top-level or static background action handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureLocalTimeZone();
  await NotificationService.instance.initialize();

  debugPrint('Notification background response: actionId=${notificationResponse.actionId}, notifId=${notificationResponse.id}');
  final payload = notificationResponse.payload;

  // 1. Immediately dismiss/cancel the notification from the tray if taking action
  final plugin = FlutterLocalNotificationsPlugin();
  int? notifId = notificationResponse.id;
  Map<String, dynamic>? data;

  if (payload != null && payload.isNotEmpty) {
    try {
      data = jsonDecode(payload) as Map<String, dynamic>;
      notifId ??= data['notificationId'] as int?;
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  if (notifId != null) {
    try {
      await plugin.cancel(id: notifId);
      debugPrint('Background notification cancelled: id=$notifId');
    } catch (e) {
      debugPrint('Error cancelling background notification: $e');
    }
  }

  // 2. Process background dose intake
  if (data != null) {
    try {
      final medicineId = data['medicineId'] as String?;
      final reminderId = data['reminderTimeId'] as String?;
      final medicineName = data['medicineName'] as String? ?? 'Medicine';
      final dosage = data['dosage'] as String? ?? '';
      final typeName = data['medicineType'] as String? ?? 'tablet';
      final dayOfWeek = data['dayOfWeek'] as int? ?? DateTime.now().weekday;
      final colorValue = data['colorValue'] as int? ?? 0;
      final photoPath = data['photoPath'] as String?;
      final type = MedicineType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => MedicineType.tablet,
      );

      if (medicineId != null && reminderId != null) {
        final now = DateTime.now();
        final int daysDiff = (now.weekday - dayOfWeek + 7) % 7;
        final targetDate = now.subtract(Duration(days: daysDiff));
        final dateStr = '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
        final int schedHour = data['scheduledHour'] as int? ?? now.hour;
        final int schedMin = data['scheduledMinute'] as int? ?? now.minute;

        if (notificationResponse.actionId == NotificationService.actionTaken) {
          final record = IntakeRecord(
            id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
            medicineId: medicineId,
            reminderTimeId: reminderId,
            scheduledDate: dateStr,
            scheduledHour: schedHour,
            scheduledMinute: schedMin,
            status: IntakeStatus.taken,
            recordedAt: now,
          );
          await DBHelper.instance.recordIntake(record);
          debugPrint('Background dose recorded as TAKEN for $medicineName ($medicineId) on $dateStr');

          // Reschedule weekly alarm for next week so recurring reminders remain intact
          final med = await DBHelper.instance.getMedicineById(medicineId);
          final rem = await DBHelper.instance.getReminderById(reminderId);
          if (med != null && rem != null && med.isActive) {
            await NotificationService.instance.rescheduleSingleDayReminder(
              medicine: med,
              reminder: rem,
              dayOfWeek: dayOfWeek,
            );
          }
        } else if (notificationResponse.actionId == NotificationService.actionSkip) {
          final record = IntakeRecord(
            id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
            medicineId: medicineId,
            reminderTimeId: reminderId,
            scheduledDate: dateStr,
            scheduledHour: schedHour,
            scheduledMinute: schedMin,
            status: IntakeStatus.skipped,
            recordedAt: now,
          );
          await DBHelper.instance.recordIntake(record);
          debugPrint('Background dose recorded as SKIPPED for $medicineName ($medicineId) on $dateStr');

          // Reschedule weekly alarm for next week so recurring reminders remain intact
          final med = await DBHelper.instance.getMedicineById(medicineId);
          final rem = await DBHelper.instance.getReminderById(reminderId);
          if (med != null && rem != null && med.isActive) {
            await NotificationService.instance.rescheduleSingleDayReminder(
              medicine: med,
              reminder: rem,
              dayOfWeek: dayOfWeek,
            );
          }
        } else if (notificationResponse.actionId == NotificationService.actionSnooze) {
          await NotificationService.instance.snoozeReminder(
            medicineName,
            dosage,
            payload!,
            minutes: 10,
            type: type,
            colorValue: colorValue,
            photoPath: photoPath,
            medicineId: medicineId,
            reminderTimeId: reminderId,
          );
          debugPrint('Background dose SNOOZED for 10 min for $medicineName');
        }
      }
    } catch (e) {
      debugPrint('Error in notificationTapBackground: $e');
    }
  }
}

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  // Channels (version 6 with system alarm audio attributes, heads-up prominence, and vibration)
  static const String alarmChannelId = 'med_alarm_channel_v6';
  static const String alarmChannelName = 'Medicine Dose Reminders & Alarms';
  static const String alarmChannelDesc = 'High-priority notifications and alerts for scheduled doses';

  static const String gentleChannelId = 'med_gentle_channel_v4';
  static const String gentleChannelName = 'Gentle Medicine Reminders';
  static const String gentleChannelDesc = 'Reminders for daily vitamins and regular doses';

  static const String refillChannelId = 'med_refill_channel_v4';
  static const String refillChannelName = 'Refill & Low Stock Alerts';
  static const String refillChannelDesc = 'Alerts when medicine stock is running low';

  // Action IDs
  static const String actionTaken = 'action_taken';
  static const String actionSnooze = 'action_snooze';
  static const String actionSkip = 'action_skip';

  // Notification Theme Color
  static const Color brandPrimaryColor = Color(0xFF0D9488);

  // ==================== MEDICINE TYPE ICON MAPPINGS ====================
  /// Returns high-resolution custom PNG icon for the large notification avatar
  static String getLargeIconForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return 'ic_med_tablet';
      case MedicineType.capsule:
        return 'ic_med_capsule';
      case MedicineType.syrup:
        return 'ic_med_syrup';
      case MedicineType.injection:
        return 'ic_med_injection';
      case MedicineType.drops:
        return 'ic_med_drops';
      case MedicineType.inhaler:
        return 'ic_med_inhaler';
      case MedicineType.ointment:
        return 'ic_med_ointment';
      case MedicineType.supplement:
        return 'ic_med_supplement';
      case MedicineType.other:
        return 'ic_med_other';
    }
  }

  /// Returns clean monochrome vector stencil for status bar & small badge matching the medicine type
  static String getSmallIconForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return '@drawable/ic_notif_tablet';
      case MedicineType.capsule:
        return '@drawable/ic_notif_capsule';
      case MedicineType.syrup:
        return '@drawable/ic_notif_syrup';
      case MedicineType.drops:
        return '@drawable/ic_notif_drops';
      case MedicineType.inhaler:
        return '@drawable/ic_notif_inhaler';
      case MedicineType.injection:
        return '@drawable/ic_notif_injection';
      case MedicineType.ointment:
        return '@drawable/ic_notif_ointment';
      case MedicineType.supplement:
        return '@drawable/ic_notif_supplement';
      case MedicineType.other:
        return '@drawable/ic_notif_tablet';
    }
  }

  /// Returns appropriate medicine emoji
  static String getEmojiForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return '💊';
      case MedicineType.capsule:
        return '💊';
      case MedicineType.syrup:
        return '🧪';
      case MedicineType.injection:
        return '💉';
      case MedicineType.drops:
        return '💧';
      case MedicineType.inhaler:
        return '🫁';
      case MedicineType.ointment:
        return '🧴';
      case MedicineType.supplement:
        return '🌿';
      case MedicineType.other:
        return '💊';
    }
  }

  Function(String payload, String? actionId)? _onNotificationAction;
  NotificationResponse? _pendingResponse;

  set onNotificationAction(Function(String payload, String? actionId)? callback) {
    _onNotificationAction = callback;
    if (_onNotificationAction != null && _pendingResponse != null) {
      final res = _pendingResponse!;
      _pendingResponse = null;
      if (res.payload != null && res.payload!.isNotEmpty) {
        _onNotificationAction!(res.payload!, res.actionId);
      }
    }
  }

  Function(String payload, String? actionId)? get onNotificationAction => _onNotificationAction;

  Future<void> initialize({Function(String payload, String? actionId)? onAction}) async {
    if (_isInitialized) return;
    if (onAction != null) {
      onNotificationAction = onAction;
    }

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      debugPrint('NotificationService: Skipping mobile notifications on desktop/web.');
      _isInitialized = true;
      return;
    }

    // 1. Initialize Timezones using device true timezone
    await configureLocalTimeZone();

    // 2. Android Initialization Settings with fallback protection
    bool initSuccess = false;
    for (final iconName in ['@drawable/ic_notification', '@mipmap/ic_launcher']) {
      try {
        final androidSettings = AndroidInitializationSettings(iconName);
        final initSettings = InitializationSettings(android: androidSettings);

        // 3. Initialize plugin
        await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) async {
            if (response.actionId == actionTaken ||
                response.actionId == actionSkip ||
                response.actionId == actionSnooze) {
              if (response.id != null) {
                try {
                  await _notificationsPlugin.cancel(id: response.id!);
                } catch (_) {}
              }
            }
            if (response.payload != null && response.payload!.isNotEmpty) {
              if (_onNotificationAction != null) {
                _onNotificationAction!(response.payload!, response.actionId);
              } else {
                _pendingResponse = response;
              }
            }
          },
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );
        initSuccess = true;
        break;
      } catch (e) {
        debugPrint('Notification init with $iconName failed: $e, trying fallback...');
      }
    }
    if (!initSuccess) {
      debugPrint('Warning: Local notifications could not be initialized with custom icons.');
    }

    // Check if app was launched via notification click
    try {
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp && launchDetails.notificationResponse != null) {
        final res = launchDetails.notificationResponse!;
        if (res.actionId == actionTaken || res.actionId == actionSkip || res.actionId == actionSnooze) {
          if (res.id != null) {
            try {
              await _notificationsPlugin.cancel(id: res.id!);
            } catch (_) {}
          }
        }
        if (res.payload != null && res.payload!.isNotEmpty) {
          if (_onNotificationAction != null) {
            _onNotificationAction!(res.payload!, res.actionId);
          } else {
            _pendingResponse = res;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading notification launch details: $e');
    }

    // 4. Create Notification Channels for Android 8.0+
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          enableLights: true,
          ledColor: brandPrimaryColor,
          audioAttributesUsage: AudioAttributesUsage.alarm,
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
          enableLights: true,
          ledColor: brandPrimaryColor,
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

  /// Completely cancels and purges all notifications, pending intents,
  /// and scheduled alarms from Android's system AlarmManager and tray.
  Future<void> wipeAllDeviceNotificationsAndAlarms() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('NotificationService: All existing device notifications & alarms purged successfully.');
    } catch (e) {
      debugPrint('NotificationService: Error wiping device notifications: $e');
    }
  }

  // ==================== PERMISSIONS ====================
  Future<bool> requestPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // 1. Android 13+ Notification Runtime Permission
    bool notifAllowed = false;
    try {
      final res = await androidPlugin?.requestNotificationsPermission();
      notifAllowed = res ?? false;
    } catch (e) {
      debugPrint('requestNotificationsPermission notice: $e');
    }

    if (!notifAllowed) {
      try {
        final status = await Permission.notification.request();
        notifAllowed = status.isGranted;
      } catch (e) {
        debugPrint('Permission.notification.request notice: $e');
      }
    }

    // 2. Android 12+ / 14+ Exact Alarm Permission
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('Schedule exact alarm check notice: $e');
    }

    // 3. Battery Optimizations Request
    try {
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Battery optimization check notice: $e');
    }

    return notifAllowed;
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

  Future<AppStrings> _getStrings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language_code') ?? 'en';
      return AppStrings.of(lang);
    } catch (_) {
      return AppStrings.en;
    }
  }

  // ==================== SCHEDULING ====================
  Future<void> scheduleMedicineReminder(Medicine medicine, ReminderTime reminder) async {
    final s = await _getStrings();
    final channelId = reminder.isAlarm ? alarmChannelId : gentleChannelId;
    final channelName = reminder.isAlarm ? alarmChannelName : gentleChannelName;

    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);
    final emoji = getEmojiForType(medicine.type);

    final AndroidBitmap<Object> largeIconBitmap;
    if (medicine.photoPath != null &&
        medicine.photoPath!.isNotEmpty &&
        File(medicine.photoPath!).existsSync()) {
      largeIconBitmap = FilePathAndroidBitmap(medicine.photoPath!);
    } else {
      largeIconBitmap = DrawableResourceAndroidBitmap(largeIcon);
    }

    final instructionStr = s.foodInstructionName(medicine.instruction.name);
    final medTitle = s.notifTimeForMed(medicine.name, medicine.dosage);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: reminder.isAlarm ? alarmChannelDesc : gentleChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      showWhen: true,
      fullScreenIntent: reminder.isAlarm,
      category: reminder.isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      icon: smallIcon,
      largeIcon: largeIconBitmap,
      color: medicine.colorValue != 0 ? Color(medicine.colorValue) : brandPrimaryColor,
      ticker: '$emoji $medTitle',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      vibrationPattern: reminder.isAlarm ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000]) : null,
      styleInformation: BigTextStyleInformation(
        s.notifTakeBigText(instructionStr, reminder.formattedTime, medicine.dosage),
        htmlFormatBigText: true,
        contentTitle: '$emoji <b>$medTitle</b>',
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          actionTaken,
          s.notifActionMarkTaken,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          s.notifActionSnooze10m,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          s.notifActionSkip,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final notifTitle = '$emoji $medTitle';
    final notifBody = s.notifTakeBody(instructionStr, reminder.formattedTime, medicine.dosage);

    // Schedule for each day in daysOfWeek
    for (final dayOfWeek in reminder.daysOfWeek) {
      final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, reminder.hour, reminder.minute);
      final uniqueNotificationId = reminder.notificationId * 10 + dayOfWeek;

      final dayPayload = jsonEncode({
        'medicineId': medicine.id,
        'medicineName': medicine.name,
        'dosage': medicine.dosage,
        'medicineType': medicine.type.name,
        'colorValue': medicine.colorValue,
        'photoPath': medicine.photoPath,
        'instruction': instructionStr,
        'reminderTimeId': reminder.id,
        'isAlarm': reminder.isAlarm,
        'notificationId': uniqueNotificationId,
        'dayOfWeek': dayOfWeek,
        'scheduledHour': reminder.hour,
        'scheduledMinute': reminder.minute,
        'reminderBaseNotificationId': reminder.notificationId,
      });

      debugPrint('NotificationService: Scheduling reminder "${medicine.name}" (${reminder.formattedTime}) for day $dayOfWeek at $scheduledDate (ID: $uniqueNotificationId, tz: ${scheduledDate.timeZoneName}, local: ${tz.local.name})');

      try {
        await _notificationsPlugin.zonedSchedule(
          id: uniqueNotificationId,
          title: notifTitle,
          body: notifBody,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: dayPayload,
        );
      } catch (e) {
        debugPrint('Error scheduling exact reminder for ${medicine.name}: $e. Trying inexact fallback...');
        try {
          await _notificationsPlugin.zonedSchedule(
            id: uniqueNotificationId,
            title: notifTitle,
            body: notifBody,
            scheduledDate: scheduledDate,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: dayPayload,
          );
        } catch (fallbackError) {
          debugPrint('Fallback scheduling also failed for ${medicine.name}: $fallbackError');
        }
      }
    }
  }

  Future<void> cancelReminder(ReminderTime reminder) async {
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel(id: reminder.notificationId * 10 + day);
    }
  }

  Future<void> cancelNotificationId(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('Error cancelling notification id $notificationId: $e');
    }
  }

  Future<void> dismissActiveReminderNotification({
    required ReminderTime reminder,
    int? notificationId,
  }) async {
    if (notificationId != null) {
      try {
        await _notificationsPlugin.cancel(id: notificationId);
      } catch (_) {}
    }
    final todayWeekday = DateTime.now().weekday;
    try {
      await _notificationsPlugin.cancel(id: reminder.notificationId * 10 + todayWeekday);
    } catch (_) {}
    final yesterdayWeekday = (todayWeekday == 1) ? 7 : todayWeekday - 1;
    try {
      await _notificationsPlugin.cancel(id: reminder.notificationId * 10 + yesterdayWeekday);
    } catch (_) {}
    try {
      await _notificationsPlugin.cancel(id: 999999); // Snooze ID
    } catch (_) {}
  }

  Future<void> rescheduleSingleDayReminder({
    required Medicine medicine,
    required ReminderTime reminder,
    required int dayOfWeek,
  }) async {
    final s = await _getStrings();
    final scheduledDate = _nextInstanceOfDayAndTime(dayOfWeek, reminder.hour, reminder.minute);
    final uniqueNotificationId = reminder.notificationId * 10 + dayOfWeek;

    final channelId = reminder.isAlarm ? alarmChannelId : gentleChannelId;
    final channelName = reminder.isAlarm ? alarmChannelName : gentleChannelName;
    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);
    final emoji = getEmojiForType(medicine.type);

    final AndroidBitmap<Object> largeIconBitmap;
    if (medicine.photoPath != null &&
        medicine.photoPath!.isNotEmpty &&
        File(medicine.photoPath!).existsSync()) {
      largeIconBitmap = FilePathAndroidBitmap(medicine.photoPath!);
    } else {
      largeIconBitmap = DrawableResourceAndroidBitmap(largeIcon);
    }

    final instructionStr = s.foodInstructionName(medicine.instruction.name);
    final medTitle = s.notifTimeForMed(medicine.name, medicine.dosage);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: reminder.isAlarm ? alarmChannelDesc : gentleChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      showWhen: true,
      fullScreenIntent: reminder.isAlarm,
      category: reminder.isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      icon: smallIcon,
      largeIcon: largeIconBitmap,
      color: medicine.colorValue != 0 ? Color(medicine.colorValue) : brandPrimaryColor,
      ticker: '$emoji $medTitle',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        s.notifTakeBigText(instructionStr, reminder.formattedTime, medicine.dosage),
        htmlFormatBigText: true,
        contentTitle: '$emoji <b>$medTitle</b>',
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          actionTaken,
          s.notifActionMarkTaken,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          s.notifActionSkip,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final dayPayload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dosage': medicine.dosage,
      'medicineType': medicine.type.name,
      'colorValue': medicine.colorValue,
      'photoPath': medicine.photoPath,
      'instruction': instructionStr,
      'reminderTimeId': reminder.id,
      'isAlarm': reminder.isAlarm,
      'notificationId': uniqueNotificationId,
      'dayOfWeek': dayOfWeek,
    });

    try {
      await _notificationsPlugin.zonedSchedule(
        id: uniqueNotificationId,
        title: '$emoji $medTitle',
        body: s.notifTakeBody(instructionStr, reminder.formattedTime, medicine.dosage),
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: dayPayload,
      );
    } catch (e) {
      debugPrint('Error rescheduling single day reminder: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> snoozeReminder(
    String medicineName,
    String dosage,
    String payload, {
    int minutes = 10,
    MedicineType type = MedicineType.tablet,
    int colorValue = 0,
    String? photoPath,
    String? medicineId,
    String? reminderTimeId,
  }) async {
    final s = await _getStrings();
    await configureLocalTimeZone();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: minutes));

    // Unique snooze ID per medicine so multiple medicines can be independently snoozed
    final int snoozeId = 880000 + (medicineId != null ? medicineId.hashCode.abs() % 100000 : medicineName.hashCode.abs() % 100000);

    final smallIcon = getSmallIconForType(type);
    final largeIcon = getLargeIconForType(type);
    final emoji = getEmojiForType(type);

    final AndroidBitmap<Object> largeIconBitmap;
    if (photoPath != null && photoPath.isNotEmpty && File(photoPath).existsSync()) {
      largeIconBitmap = FilePathAndroidBitmap(photoPath);
    } else {
      largeIconBitmap = DrawableResourceAndroidBitmap(largeIcon);
    }

    final snoozedTitle = s.notifSnoozedTitle(medicineName);
    final snoozedBody = s.notifSnoozedBody(dosage);

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: smallIcon,
      largeIcon: largeIconBitmap,
      color: colorValue != 0 ? Color(colorValue) : brandPrimaryColor,
      subText: snoozedTitle,
      ticker: '$emoji $snoozedTitle',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      styleInformation: BigTextStyleInformation(
        '⏱️ <b>$snoozedBody</b>',
        htmlFormatBigText: true,
        contentTitle: '⏰ <b>$emoji $snoozedTitle</b>',
        htmlFormatContentTitle: true,
        summaryText: snoozedTitle,
        htmlFormatSummaryText: true,
      ),
      actions: [
        AndroidNotificationAction(
          actionTaken,
          s.notifActionMarkTaken,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          s.notifActionSnooze10m,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          s.notifActionSkip,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    Map<String, dynamic> payloadMap = {};
    try {
      payloadMap = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {}
    payloadMap['medicineId'] ??= medicineId;
    payloadMap['reminderTimeId'] ??= reminderTimeId;
    payloadMap['medicineName'] ??= medicineName;
    payloadMap['dosage'] ??= dosage;
    payloadMap['medicineType'] ??= type.name;
    payloadMap['colorValue'] ??= colorValue;
    payloadMap['photoPath'] ??= photoPath;
    payloadMap['notificationId'] = snoozeId;
    payloadMap['isAlarm'] = true;
    payloadMap['isSnooze'] = true;

    debugPrint('NotificationService: Scheduling snooze alarm for $medicineName ($snoozeId) at $scheduledDate (in $minutes min, local tz: ${tz.local.name})');

    try {
      await _notificationsPlugin.zonedSchedule(
        id: snoozeId,
        title: '⏰ $emoji $snoozedTitle',
        body: snoozedBody,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(payloadMap),
      );
      debugPrint('NotificationService: Snooze alarm scheduled successfully with exactAllowWhileIdle for $scheduledDate');
    } catch (e) {
      debugPrint('Snooze exact schedule error: $e, falling back to inexactAllowWhileIdle...');
      try {
        await _notificationsPlugin.zonedSchedule(
          id: snoozeId,
          title: '⏰ $emoji $snoozedTitle',
          body: snoozedBody,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode(payloadMap),
        );
        debugPrint('NotificationService: Snooze fallback scheduled successfully for $scheduledDate');
      } catch (fallbackError) {
        debugPrint('NotificationService: Snooze fallback error: $fallbackError');
      }
    }
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


  Future<void> showStockForecastAlert(Medicine medicine, int daysLeft, String runOutDateStr) async {
    final s = await _getStrings();
    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);

    final androidDetails = AndroidNotificationDetails(
      refillChannelId,
      refillChannelName,
      channelDescription: refillChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: s.notifLowStockTitle(medicine.name),
      body: s.notifLowStockBody(medicine.currentStock),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showRefillAlert(Medicine medicine) async {
    final s = await _getStrings();
    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);

    final androidDetails = AndroidNotificationDetails(
      refillChannelId,
      refillChannelName,
      channelDescription: refillChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: s.notifLowStockTitle(medicine.name),
      body: s.notifLowStockBody(medicine.currentStock),
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showTestNotification({MedicineType type = MedicineType.tablet}) async {
    final s = await _getStrings();
    String medName;
    String dosage;
    String instruction = s.foodInstructionName('afterMeal');

    switch (type) {
      case MedicineType.tablet:
        medName = 'Paracetamol';
        dosage = '650 mg (1 ${s.typeTablet})';
        break;
      case MedicineType.syrup:
        medName = 'Cough Relief Syrup';
        dosage = '10 ml (1 ${s.typeSyrup})';
        break;
      case MedicineType.injection:
        medName = 'Insulin Glargine';
        dosage = '15 Units';
        instruction = s.foodInstructionName('beforeMeal');
        break;
      case MedicineType.capsule:
        medName = 'Amoxicillin';
        dosage = '500 mg (1 ${s.typeCapsule})';
        break;
      case MedicineType.drops:
        medName = 'OptiClear Eye Drops';
        dosage = '2 ${s.typeDrops}';
        instruction = s.foodInstructionName('anytime');
        break;
      case MedicineType.inhaler:
        medName = 'Salbutamol Inhaler';
        dosage = '2 ${s.typeInhaler}';
        instruction = s.foodInstructionName('anytime');
        break;
      case MedicineType.ointment:
        medName = 'Hydrocortisone Cream';
        dosage = 'Thin Layer';
        instruction = s.foodInstructionName('anytime');
        break;
      case MedicineType.supplement:
        medName = 'Omega-3 Fish Oil';
        dosage = '1 Softgel';
        instruction = s.foodInstructionName('withMeal');
        break;
      default:
        medName = 'Daily Medicine';
        dosage = '1 Dose';
    }

    final testMedId = 'demo_${type.name}';
    final testRemId = 'demo_rem_${type.name}';
    final testNotifId = 99990 + type.index;
    final payload = jsonEncode({
      'medicineId': testMedId,
      'medicineName': medName,
      'dosage': dosage,
      'instruction': instruction,
      'medicineType': type.name,
      'reminderTimeId': testRemId,
      'notificationId': testNotifId,
      'isAlarm': true,
      'isTest': true,
    });

    final smallIcon = getSmallIconForType(type);
    final largeIcon = getLargeIconForType(type);
    final emoji = getEmojiForType(type);
    final titleStr = '$emoji ${s.notifTimeForMed(medName, dosage)}';
    final bigText = s.notifTakeBigText(instruction, 'Just Now', dosage);

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
      ticker: titleStr,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        bigText,
        htmlFormatBigText: true,
        contentTitle: titleStr,
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          actionTaken,
          s.notifActionMarkTaken,
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          s.notifActionSkip,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.show(
      id: 99990 + type.index,
      title: titleStr,
      body: s.notifTakeBody(instruction, 'Just Now', dosage),
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    if (scheduledDate.weekday == dayOfWeek) {
      if (scheduledDate.isBefore(now.subtract(const Duration(seconds: 15)))) {
        // Scheduled time for today already passed more than 15s ago, schedule for next week
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else if (scheduledDate.isBefore(now)) {
        // User scheduled within the current active minute (e.g. set 3:25 at 3:25:05)
        // Fire 5 seconds from now so the user receives the alarm promptly!
        scheduledDate = now.add(const Duration(seconds: 5));
      }
    } else {
      while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          hour,
          minute,
          0,
        );
      }
    }

    return scheduledDate;
  }

  /// Schedules a quick test alarm that rings with sound, vibration, and full-screen alert
  /// in [secondsFromNow] seconds (defaults to 5 seconds).
  Future<void> scheduleQuickTestAlarm({int secondsFromNow = 5}) async {
    final s = await _getStrings();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: secondsFromNow));
    const int testId = 777777;

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: '@drawable/ic_notification',
      color: brandPrimaryColor,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      ticker: s.notifTestTitle,
      styleInformation: BigTextStyleInformation(
        '🔔 <b>${s.notifTestBody}</b>',
        htmlFormatBigText: true,
        contentTitle: '⏰ <b>${s.notifTestTitle}</b>',
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          actionTaken,
          s.notifActionDismiss,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final payload = jsonEncode({
      'medicineId': 'test_demo',
      'medicineName': 'Test Alarm',
      'dosage': '1 Dose',
      'reminderTimeId': 'test_rem',
      'notificationId': testId,
      'isAlarm': true,
      'isTest': true,
    });

    await _notificationsPlugin.zonedSchedule(
      id: testId,
      title: s.notifTestTitle,
      body: s.notifTestBody,
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint('NotificationService: Quick test alarm scheduled for $scheduledDate (in $secondsFromNow seconds)');
  }
}
