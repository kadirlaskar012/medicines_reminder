import 'package:flutter_test/flutter_test.dart';
import 'package:medicines_reminder/core/localization/app_strings.dart';

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
  });
}
