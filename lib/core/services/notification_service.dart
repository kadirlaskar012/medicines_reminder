import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/intake_record.dart';
import '../../models/medicine.dart';
import '../../models/reminder_time.dart';
import '../database/db_helper.dart';

// Top-level or static background action handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  debugPrint('Notification background response: actionId=${notificationResponse.actionId}');
  final payload = notificationResponse.payload;
  if (payload != null && payload.isNotEmpty) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final medicineId = data['medicineId'] as String?;
      final reminderId = data['reminderTimeId'] as String?;
      if (medicineId != null && reminderId != null) {
        final now = DateTime.now();
        final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        if (notificationResponse.actionId == NotificationService.actionTaken) {
          final record = IntakeRecord(
            id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
            medicineId: medicineId,
            reminderTimeId: reminderId,
            scheduledDate: dateStr,
            scheduledHour: now.hour,
            scheduledMinute: now.minute,
            status: IntakeStatus.taken,
            recordedAt: now,
          );
          await DBHelper.instance.recordIntake(record);
        } else if (notificationResponse.actionId == NotificationService.actionSkip) {
          final record = IntakeRecord(
            id: 'bg_${DateTime.now().millisecondsSinceEpoch}',
            medicineId: medicineId,
            reminderTimeId: reminderId,
            scheduledDate: dateStr,
            scheduledHour: now.hour,
            scheduledMinute: now.minute,
            status: IntakeStatus.skipped,
            recordedAt: now,
          );
          await DBHelper.instance.recordIntake(record);
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

  // Channels (version 2 with max importance and heads-up banner support)
  static const String alarmChannelId = 'med_alarm_channel_v2';
  static const String alarmChannelName = 'Medicine Alarms & Urgent Reminders';
  static const String alarmChannelDesc = 'Critical alarms and heads-up popups for scheduled doses';

  static const String gentleChannelId = 'med_gentle_channel_v2';
  static const String gentleChannelName = 'Medicine Reminders & Supplements';
  static const String gentleChannelDesc = 'Reminders for daily vitamins and regular doses';

  static const String refillChannelId = 'med_refill_channel_v2';
  static const String refillChannelName = 'Refill & Low Stock Alerts';
  static const String refillChannelDesc = 'Smart alerts when medicine stock is running low';

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
        return 'ic_med_capsule';
    }
  }

  /// Returns clean monochrome vector stencil for status bar & small badge
  static String getSmallIconForType(MedicineType type) {
    switch (type) {
      case MedicineType.tablet:
        return '@drawable/ic_notif_tablet';
      case MedicineType.capsule:
        return '@drawable/ic_notif_capsule';
      case MedicineType.syrup:
        return '@drawable/ic_notif_syrup';
      case MedicineType.injection:
        return '@drawable/ic_notif_injection';
      case MedicineType.drops:
        return '@drawable/ic_notif_drops';
      case MedicineType.inhaler:
        return '@drawable/ic_notif_inhaler';
      case MedicineType.ointment:
        return '@drawable/ic_notif_ointment';
      case MedicineType.supplement:
        return '@drawable/ic_notif_supplement';
      case MedicineType.other:
        return '@drawable/ic_notification';
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

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final String currentTimeZone = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    // 2. Android Initialization Settings with fallback protection
    bool initSuccess = false;
    for (final iconName in ['@drawable/ic_notification', '@mipmap/ic_launcher']) {
      try {
        final androidSettings = AndroidInitializationSettings(iconName);
        final initSettings = InitializationSettings(android: androidSettings);

        // 3. Initialize plugin
        await _notificationsPlugin.initialize(
          settings: initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
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
        const AndroidNotificationChannel(
          alarmChannelId,
          alarmChannelName,
          description: alarmChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: brandPrimaryColor,
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

    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);
    final emoji = getEmojiForType(medicine.type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: reminder.isAlarm ? alarmChannelDesc : gentleChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: reminder.isAlarm,
      category: reminder.isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
      subText: '${medicine.type.label} Reminder',
      ticker: '$emoji Time for ${medicine.name} (${medicine.dosage})',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        'Take <b>${medicine.dosage}</b> (${medicine.instruction.title})<br>Medicine Type: <b>${medicine.type.label}</b>. Tap to confirm your dose.',
        htmlFormatBigText: true,
        contentTitle: '$emoji <b>Time for ${medicine.name}</b> (${medicine.dosage})',
        htmlFormatContentTitle: true,
        summaryText: '${medicine.type.label} Reminder',
        htmlFormatSummaryText: true,
      ),
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
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          'SKIP',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final payload = jsonEncode({
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'dosage': medicine.dosage,
      'medicineType': medicine.type.name,
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
          title: '$emoji Time for ${medicine.name} (${medicine.dosage})',
          body: 'Instruction: ${medicine.instruction.title}. Tap to confirm your dose.',
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      } catch (e) {
        debugPrint('Error scheduling exact reminder: $e');
        try {
          await _notificationsPlugin.zonedSchedule(
            id: uniqueNotificationId,
            title: '$emoji Time for ${medicine.name} (${medicine.dosage})',
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

  Future<void> snoozeReminder(
    String medicineName,
    String dosage,
    String payload, {
    int minutes = 10,
    MedicineType type = MedicineType.tablet,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(minutes: minutes));
    const snoozeId = 999999;

    final smallIcon = getSmallIconForType(type);
    final largeIcon = getLargeIconForType(type);
    final emoji = getEmojiForType(type);

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
      subText: '${type.label} Snoozed Dose',
      ticker: '$emoji Snoozed: $medicineName ($dosage)',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        'Snooze time elapsed! Please take <b>$dosage</b> now.<br>Tap to log your dose.',
        htmlFormatBigText: true,
        contentTitle: '⏰ <b>$emoji Snoozed: $medicineName</b> ($dosage)',
        htmlFormatContentTitle: true,
        summaryText: '${type.label} Snoozed Dose',
        htmlFormatSummaryText: true,
      ),
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
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          'SKIP',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      id: snoozeId,
      title: '⏰ $emoji Snoozed: $medicineName ($dosage)',
      body: 'Time to take your snoozed dose now!',
      scheduledDate: scheduledDate,
      notificationDetails: NotificationDetails(android: androidDetails),
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
      'medicineType': medicine.type.name,
      'instruction': medicine.instruction.title,
      'reminderTimeId': reminder.id,
      'isAlarm': reminder.isAlarm,
    });

    final smallIcon = getSmallIconForType(medicine.type);
    final largeIcon = getLargeIconForType(medicine.type);
    final emoji = getEmojiForType(medicine.type);

    final androidDetails = AndroidNotificationDetails(
      gentleChannelId,
      gentleChannelName,
      channelDescription: gentleChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
      subText: '${medicine.type.label} Upcoming',
      actions: const [
        AndroidNotificationAction(
          actionTaken,
          'TAKE NOW',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze,
          'SNOOZE 10M',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.show(
      id: (medicine.name.hashCode.abs() % 10000) + 70000,
      title: '⏳ Upcoming in $minutesUntilDose min: $emoji ${medicine.name}',
      body: '${medicine.dosage} scheduled at ${reminder.formattedTime} (${medicine.instruction.title})',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> showStockForecastAlert(Medicine medicine, int daysLeft, String runOutDateStr) async {
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
      subText: '📦 Low Stock Alert',
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: '📦 Refill Alert: ${medicine.name}',
      body: 'Will run out in $daysLeft days ($runOutDateStr). Remaining: ${medicine.currentStock} units.',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showRefillAlert(Medicine medicine) async {
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
      subText: '⚠️ Refill Reminder',
    );

    await _notificationsPlugin.show(
      id: medicine.name.hashCode.abs() % 100000 + 800000,
      title: '⚠️ Low Stock: ${medicine.name}',
      body: 'Only ${medicine.currentStock} doses remaining! Please refill soon.',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showTestNotification({MedicineType type = MedicineType.tablet}) async {
    String medName;
    String dosage;
    String instruction = 'After Meal';

    switch (type) {
      case MedicineType.tablet:
        medName = 'Paracetamol';
        dosage = '650 mg (1 Tablet)';
        break;
      case MedicineType.syrup:
        medName = 'Cough Relief Syrup';
        dosage = '10 ml (1 Spoon)';
        break;
      case MedicineType.injection:
        medName = 'Insulin Glargine';
        dosage = '15 Units';
        instruction = 'Before Meal';
        break;
      case MedicineType.capsule:
        medName = 'Amoxicillin';
        dosage = '500 mg (1 Capsule)';
        break;
      case MedicineType.drops:
        medName = 'OptiClear Eye Drops';
        dosage = '2 Drops';
        instruction = 'Anytime';
        break;
      case MedicineType.inhaler:
        medName = 'Salbutamol Inhaler';
        dosage = '2 Puffs';
        instruction = 'Anytime';
        break;
      case MedicineType.ointment:
        medName = 'Hydrocortisone Cream';
        dosage = 'Thin Layer';
        instruction = 'Anytime';
        break;
      case MedicineType.supplement:
        medName = 'Omega-3 Fish Oil';
        dosage = '1 Softgel';
        instruction = 'With Meal';
        break;
      default:
        medName = 'Daily Medicine';
        dosage = '1 Dose';
    }

    final testMedId = 'demo_${type.name}';
    final testRemId = 'demo_rem_${type.name}';
    final payload = jsonEncode({
      'medicineId': testMedId,
      'medicineName': medName,
      'dosage': dosage,
      'instruction': instruction,
      'medicineType': type.name,
      'reminderTimeId': testRemId,
      'isAlarm': true,
      'isTest': true,
    });

    final smallIcon = getSmallIconForType(type);
    final largeIcon = getLargeIconForType(type);
    final emoji = getEmojiForType(type);

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      color: brandPrimaryColor,
      subText: '${type.label} Dose Reminder',
      ticker: '$emoji Time for $medName ($dosage)',
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      styleInformation: BigTextStyleInformation(
        'Take <b>$dosage</b> ($instruction)<br>Form: <b>${type.label}</b>. Tap to confirm your dose.',
        htmlFormatBigText: true,
        contentTitle: '$emoji <b>Time for $medName</b> ($dosage)',
        htmlFormatContentTitle: true,
        summaryText: '${type.label} Dose Reminder',
        htmlFormatSummaryText: true,
      ),
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
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSkip,
          'SKIP',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.show(
      id: 99990 + type.index,
      title: '$emoji Time for $medName ($dosage)',
      body: 'Instruction: $instruction. Tap to confirm your dose.',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: payload,
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
