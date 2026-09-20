import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/database/db_helper.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run independent initializations in parallel for instant cold startup
  final initTasks = await Future.wait([
    if (Platform.isAndroid)
      FlutterDisplayMode.setHighRefreshRate().catchError((e) {
        debugPrint('High refresh rate setup notice: $e');
      })
    else
      Future.value(null),
    NotificationService.instance.initialize().catchError((e) {
      debugPrint('Notification init notice: $e');
    }),
    SharedPreferences.getInstance(),
    () async {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.projectUrl,
          // ignore: deprecated_member_use
          anonKey: SupabaseConfig.anonKey,
        );
        await SupabaseService.instance.initSession();
      } catch (e) {
        debugPrint('Supabase init notice: $e');
      }
    }(),
  ]);

  final prefs = initTasks[2] as SharedPreferences;
  bool hasSeenWelcome = prefs.getBool(WelcomeScreen.prefKeySeenWelcome) ?? false;

  // If user updated or installed over a previous version, verify SQLite DB
  if (!hasSeenWelcome) {
    try {
      final existingMeds = await DBHelper.instance.getAllMedicines();
      if (existingMeds.isNotEmpty) {
        hasSeenWelcome = true;
        await prefs.setBool(WelcomeScreen.prefKeySeenWelcome, true);
      }
    } catch (_) {}
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicineProvider()..loadInitialData(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MediRemindApp(showWelcome: !hasSeenWelcome),
    ),
  );
}

class MediRemindApp extends StatelessWidget {
  final bool showWelcome;
  const MediRemindApp({super.key, this.showWelcome = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'MediRemind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },
      home: showWelcome ? const WelcomeScreen() : const MainNavigationScreen(),
    );
  }
}

