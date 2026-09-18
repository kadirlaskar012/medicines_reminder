import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicines_reminder/providers/language_provider.dart';
import 'package:medicines_reminder/providers/medicine_provider.dart';
import 'package:medicines_reminder/screens/welcome/onboarding_language_screen.dart';
import 'package:medicines_reminder/screens/welcome/user_onboarding_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingLanguageScreen renders 3 languages and navigates to UserOnboardingProfileScreen', (tester) async {
    final langProvider = LanguageProvider();
    final medProvider = MedicineProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
          ChangeNotifierProvider<MedicineProvider>.value(value: medProvider),
        ],
        child: const MaterialApp(
          home: OnboardingLanguageScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify language choices are displayed
    expect(find.text('বাংলা'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    expect(find.text('हिन्दी'), findsWidgets);

    // Verify continue button exists
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Tap on English card
    final englishFinder = find.text('English').first;
    await tester.tap(englishFinder);
    await tester.pumpAndSettle();

    // Tap Continue
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify UserOnboardingProfileScreen is pushed
    expect(find.byType(UserOnboardingProfileScreen), findsOneWidget);
  });
}
