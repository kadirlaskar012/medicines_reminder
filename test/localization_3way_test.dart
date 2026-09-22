import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/core/localization/app_strings.dart';
import 'package:medicines_reminder/models/app_notification.dart';

void main() {
  group('Strict 3-Way Localization Isolation Tests', () {
    final bnRegex = RegExp(r'[\u0980-\u09ff]');
    final hiRegex = RegExp(r'[\u0900-\u097f]');

    test('English (en) must contain zero Bengali or Hindi characters', () {
      final s = AppStrings.en;
      expect(s.code, 'en');

      // Check numbers
      expect(s.formatNumber(12345), '12345');
      expect(s.formatNumber('0123456789'), '0123456789');

      // Sample key strings across features
      final samples = [
        s.tabToday,
        s.tabCabinet,
        s.tabHistory,
        s.tabSettings,
        s.todayDoses,
        s.upcomingMedicines,
        s.taken,
        s.skipped,
        s.missed,
        s.due,
        s.filterByDateTooltip,
        s.stockRefillTitle,
        s.howManyMedsHave,
        s.autoCalculateCourse,
        s.quickSelectLabel,
        s.whenRefillAlertPrompt,
        s.confirmStockAndSetReminders,
        s.skipStockForNow,
        s.appearanceAndThemeHeader,
        s.backupAndRestoreHeader,
        s.adherenceReportTitle,
        s.weeklyPeriod,
        s.monthlyPeriod,
        s.yearlyPeriod,
        s.notifActionMarkTaken,
        s.notifActionSnooze10m,
        s.notifMedAddedMsg('500', 3, 'Bedtime'),
        s.notifMedUpdatedMsg('500', 3, 'Tablets'),
        s.notifRefillMsg(5, 10, 'Tablets'),
        s.notifDoseTakenMsg('500', '10:00 AM'),
        s.notifTimeForMed('Paracetamol', '500mg'),
        s.notifTakeBody('Paracetamol', '500mg'),
        s.notifSnoozedBody('Paracetamol', 10),
        s.notifLowStockBody('Paracetamol', 5),
        s.proposedCourseCount(30),
        s.halfCourseCount(15),
        s.oneMonthCount(60),
        s.morningTimingTitle,
        s.lunchTimingTitle,
        s.eveningTimingTitle,
        s.nightTimingTitle,
        s.optBeforeBreakfastLabel,
        s.optAfterBreakfastLabel,
        s.optEmptyStomachLabel,
      ];

      for (final str in samples) {
        expect(bnRegex.hasMatch(str), isFalse, reason: 'English string "$str" leaked Bengali!');
        expect(hiRegex.hasMatch(str), isFalse, reason: 'English string "$str" leaked Hindi!');
        expect(str.contains('(Start Date)'), isFalse);
        expect(str.contains('(Before Breakfast)'), isFalse);
      }
    });

    test('Bengali (bn) must be 100% Bengali with zero Hindi and pure numerals', () {
      final s = AppStrings.bn;
      expect(s.code, 'bn');

      // Check Bengali numerals
      expect(s.formatNumber(12345), '১২৩৪৫');
      expect(s.formatNumber('0123456789'), '০১২৩৪৫৬৭৮৯');

      final samples = [
        s.tabToday,
        s.tabCabinet,
        s.tabHistory,
        s.tabSettings,
        s.todayDoses,
        s.upcomingMedicines,
        s.taken,
        s.skipped,
        s.missed,
        s.due,
        s.filterByDateTooltip,
        s.stockRefillTitle,
        s.howManyMedsHave,
        s.autoCalculateCourse,
        s.quickSelectLabel,
        s.whenRefillAlertPrompt,
        s.confirmStockAndSetReminders,
        s.skipStockForNow,
        s.appearanceAndThemeHeader,
        s.backupAndRestoreHeader,
        s.adherenceReportTitle,
        s.weeklyPeriod,
        s.monthlyPeriod,
        s.yearlyPeriod,
        s.notifActionMarkTaken,
        s.notifActionSnooze10m,
        s.proposedCourseCount(30),
        s.halfCourseCount(15),
        s.oneMonthCount(60),
        s.morningTimingTitle,
        s.lunchTimingTitle,
        s.eveningTimingTitle,
        s.nightTimingTitle,
        s.optBeforeBreakfastLabel,
        s.optAfterBreakfastLabel,
        s.optEmptyStomachLabel,
      ];

      for (final str in samples) {
        expect(hiRegex.hasMatch(str), isFalse, reason: 'Bengali string "$str" leaked Hindi!');
        expect(str.contains('(Start Date)'), isFalse);
        expect(str.contains('(Before Breakfast)'), isFalse);
        expect(bnRegex.hasMatch(str), isTrue, reason: 'Expected Bengali characters in "$str"');
      }
    });

    test('Hindi (hi) must be 100% Hindi with zero Bengali and pure numerals', () {
      final s = AppStrings.hi;
      expect(s.code, 'hi');

      // Check Hindi Devanagari numerals
      expect(s.formatNumber(12345), '१२३४५');
      expect(s.formatNumber('0123456789'), '०१२३४५६७८९');

      final samples = [
        s.tabToday,
        s.tabCabinet,
        s.tabHistory,
        s.tabSettings,
        s.todayDoses,
        s.upcomingMedicines,
        s.taken,
        s.skipped,
        s.missed,
        s.due,
        s.filterByDateTooltip,
        s.stockRefillTitle,
        s.howManyMedsHave,
        s.autoCalculateCourse,
        s.quickSelectLabel,
        s.whenRefillAlertPrompt,
        s.confirmStockAndSetReminders,
        s.skipStockForNow,
        s.appearanceAndThemeHeader,
        s.backupAndRestoreHeader,
        s.adherenceReportTitle,
        s.weeklyPeriod,
        s.monthlyPeriod,
        s.yearlyPeriod,
        s.notifActionMarkTaken,
        s.notifActionSnooze10m,
        s.proposedCourseCount(30),
        s.halfCourseCount(15),
        s.oneMonthCount(60),
        s.morningTimingTitle,
        s.lunchTimingTitle,
        s.eveningTimingTitle,
        s.nightTimingTitle,
        s.optBeforeBreakfastLabel,
        s.optAfterBreakfastLabel,
        s.optEmptyStomachLabel,
      ];

      for (final str in samples) {
        expect(bnRegex.hasMatch(str), isFalse, reason: 'Hindi string "$str" leaked Bengali!');
        expect(str.contains('(Start Date)'), isFalse);
        expect(str.contains('(Before Breakfast)'), isFalse);
        expect(hiRegex.hasMatch(str), isTrue, reason: 'Expected Hindi characters in "$str"');
      }
    });

    test('Notification messages and legacy conversions must not leak Bengali into English', () {
      final sEn = AppStrings.en;
      final sHi = AppStrings.hi;
      final sBn = AppStrings.bn;

      // Direct message generation
      final addedMsgEn = sEn.notifMedAddedMsg('500', '3 Tablets', 'Bedtime');
      expect(bnRegex.hasMatch(addedMsgEn), isFalse);
      expect(addedMsgEn, 'Dose: 500 • Stock: 3 Tablets • Bedtime');

      final updatedMsgEn = sEn.notifMedUpdatedMsg('500', 3, 'Tablets');
      expect(bnRegex.hasMatch(updatedMsgEn), isFalse);
      expect(updatedMsgEn, 'Dose: 500 • Stock: 3 Tablets');

      // Legacy fallback conversion for existing DB notifications
      final legacyNotif1 = AppNotification(
        id: '1',
        type: NotificationType.medicineUpdated,
        title: 'Medicine Updated: test',
        message: 'Dose: 500 • মজুদ: 3 Tablets',
        timestamp: DateTime.now(),
      );
      expect(legacyNotif1.localizedMessage(sEn), 'Dose: 500 • Stock: 3 Tablets');
      expect(bnRegex.hasMatch(legacyNotif1.localizedMessage(sEn)), isFalse);

      final legacyNotif2 = AppNotification(
        id: '2',
        type: NotificationType.medicineAdded,
        title: 'New Medicine Added: test',
        message: 'Dose: 500 • মজুদ: 3 Tablets • bedtime',
        timestamp: DateTime.now(),
      );
      expect(legacyNotif2.localizedMessage(sEn), 'Dose: 500 • Stock: 3 Tablets • Bedtime');
      expect(bnRegex.hasMatch(legacyNotif2.localizedMessage(sEn)), isFalse);

      final legacyNotif3 = AppNotification(
        id: '3',
        type: NotificationType.medicineAdded,
        title: 'New Medicine Added: test',
        message: 'Dose: 500 • মজুদ: 3 Tablets • afterMeal',
        timestamp: DateTime.now(),
      );
      expect(legacyNotif3.localizedMessage(sEn), 'Dose: 500 • Stock: 3 Tablets • After Meal');
      expect(bnRegex.hasMatch(legacyNotif3.localizedMessage(sEn)), isFalse);

      // Verify Hindi notification conversion
      expect(bnRegex.hasMatch(legacyNotif3.localizedMessage(sHi)), isFalse);
      expect(legacyNotif3.localizedMessage(sHi).contains('स्टॉक:'), isTrue);

      // Verify Bengali notification conversion
      expect(hiRegex.hasMatch(legacyNotif3.localizedMessage(sBn)), isFalse);
      expect(legacyNotif3.localizedMessage(sBn).contains('মজুদ:'), isTrue);

      // Verify new tagline & prompt getters
      expect(bnRegex.hasMatch(sEn.notifPartnerTagline), isFalse);
      expect(bnRegex.hasMatch(sEn.notifMotivationPrompt), isFalse);
      expect(bnRegex.hasMatch(sEn.notifCursiveNote), isFalse);

      expect(hiRegex.hasMatch(sHi.notifPartnerTagline), isTrue);
      expect(bnRegex.hasMatch(sHi.notifPartnerTagline), isFalse);

      expect(bnRegex.hasMatch(sBn.notifPartnerTagline), isTrue);
      expect(hiRegex.hasMatch(sBn.notifPartnerTagline), isFalse);
    });
  });
}
