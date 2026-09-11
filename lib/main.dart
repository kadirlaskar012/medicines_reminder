import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/medicine_provider.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for Web or Desktop
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize notification service and channels
  try {
    await NotificationService.instance.initialize();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint('Notification init notice: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicineProvider()..loadInitialData(),
        ),
      ],
      child: const MediRemindApp(),
    ),
  );
}

class MediRemindApp extends StatelessWidget {
  const MediRemindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}
