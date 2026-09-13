import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/medicine_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization note: $e');
  }

  // Initialize Supabase user session from persistent storage
  try {
    await SupabaseService.instance.initSession();
  } catch (e) {
    debugPrint('Supabase session init note: $e');
  }

  // Initialize notification service and channels
  await NotificationService.instance.initialize();

  // Request Android 13+ Notification & Exact Alarm permissions
  await NotificationService.instance.requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool(WelcomeScreen.prefKeySeenWelcome) ?? false;

  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'MediRemind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: showWelcome ? const WelcomeScreen() : const MainNavigationScreen(),
    );
  }
}
