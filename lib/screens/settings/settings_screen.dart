import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/local_backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/profile_selector_sheet.dart';
import '../family/family_members_screen.dart';
import '../welcome/user_onboarding_profile_screen.dart';
import '../welcome/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> _permissionStatuses = {
    'notification': true,
    'exactAlarm': true,
    'batteryOptimization': true,
  };
  bool _isChecking = true;

  // User-facing reminder preferences
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _snoozeMinutes = 10;
  String _reminderBehavior = 'persistent'; // 'persistent' or 'normal'
  String? _lastBackupFormatted;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkPermissions();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('reminder_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('reminder_vibration_enabled') ?? true;
      _snoozeMinutes = prefs.getInt('reminder_snooze_minutes') ?? 10;
      _reminderBehavior = prefs.getString('reminder_behavior') ?? 'persistent';
      _lastBackupFormatted = prefs.getString('last_backup_time');
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _checkPermissions() async {
    final statuses = await NotificationService.instance.checkPermissionStatuses();
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
        _isChecking = false;
      });
    }
  }

  void _requestAllPermissions() async {
    await NotificationService.instance.requestPermissions();
    _checkPermissions();
  }

  void _showBatteryOptimizationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            _buildSquircleIcon(
              icon: Icons.battery_alert_rounded,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFFB923C)],
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Reliable Alarms',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Android battery saver can sometimes delay background alarms.\n\nTo ensure your medicine reminders ring on time, allow MediRemind background activity.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Permission.ignoreBatteryOptimizations.request();
              } catch (_) {}
              _checkPermissions();
            },
            child: Text('Allow Background Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildSquircleIcon({
    required IconData icon,
    required List<Color> gradientColors,
    double size = 40,
    double iconSize = 20,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildCardContainer({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? accentGlow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? (accentGlow != null
                  ? accentGlow.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12))
              : (accentGlow != null
                  ? accentGlow.withValues(alpha: 0.22)
                  : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: AppColors.glossyCardShadow(isDark, glowColor: accentGlow),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.glossySheenDark
                        : AppColors.glossySheenLight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    IconData? icon,
    Color? accentColor,
    bool isDark = false,
  }) {
    final color = accentColor ?? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488));
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final lang = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final s = lang.strings;

    final isNotifGranted = _permissionStatuses['notification'] ?? false;
    final isAlarmGranted = _permissionStatuses['exactAlarm'] ?? false;
    final isBatteryGranted = _permissionStatuses['batteryOptimization'] ?? false;
    final hasMissingPermission = !isNotifGranted || !isAlarmGranted || !isBatteryGranted;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          s.settingsAndDiagnostics,
          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // 0. APPEARANCE & THEME (Light / Dark Switcher)
          _buildSectionHeader(
            s.appearanceAndThemeHeader,
            icon: Icons.palette_rounded,
            accentColor: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildThemeCard(context, themeProvider, s, isDark),

          const SizedBox(height: 24),

          // 1. LOCAL DATA BACKUP & RESTORE
          _buildSectionHeader(
            s.backupAndRestoreHeader,
            icon: Icons.backup_rounded,
            accentColor: const Color(0xFF0D9488),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildLocalBackupCard(context, provider, s, isDark),

          const SizedBox(height: 24),

          // 2. FAMILY & PROFILES
          _buildSectionHeader(
            s.familyMembersProfiles,
            icon: Icons.badge_rounded,
            accentColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildFamilyCard(context, provider, s, isDark),

          const SizedBox(height: 24),

          // 3. REMINDERS (Sound, Vibration, Snooze, Behavior)
          _buildSectionHeader(
            s.remindersAndAlarmsHeader,
            icon: Icons.alarm_rounded,
            accentColor: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildReminderControlsCard(isDark, s),

          const SizedBox(height: 24),

          // 4. SYSTEM PERMISSIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                s.systemPermissionsHeader,
                icon: Icons.security_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              if (_isChecking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Recheck permissions',
                  onPressed: _checkPermissions,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (hasMissingPermission) ...[
            _buildPermissionAttentionBanner(isDark, s),
            const SizedBox(height: 12),
          ],

          _buildPermissionTile(
            title: s.notifPermissionTitle,
            description: s.notifPermissionDesc,
            icon: Icons.notifications_active_rounded,
            gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
            isGranted: isNotifGranted,
            isDark: isDark,
            onAction: () async {
              await Permission.notification.request();
              _checkPermissions();
            },
          ),
          const SizedBox(height: 10),

          _buildPermissionTile(
            title: s.exactAlarmTitle,
            description: s.exactAlarmDesc,
            icon: Icons.alarm_on_rounded,
            gradientColors: const [Color(0xFFEA580C), Color(0xFFF97316)],
            isGranted: isAlarmGranted,
            isDark: isDark,
            onAction: () async {
              try {
                await Permission.scheduleExactAlarm.request();
              } catch (_) {}
              _checkPermissions();
            },
          ),
          const SizedBox(height: 10),

          _buildPermissionTile(
            title: s.batteryOptimizationTitle,
            description: s.batteryOptimizationDesc,
            icon: Icons.battery_charging_full_rounded,
            gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
            isGranted: isBatteryGranted,
            isDark: isDark,
            onAction: _showBatteryOptimizationDialog,
          ),

          const SizedBox(height: 24),

          // 5. LANGUAGE
          _buildSectionHeader(
            s.languageHeader,
            icon: Icons.translate_rounded,
            accentColor: const Color(0xFF0D9488),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildLanguageSelector(context, lang, s, isDark),

          const SizedBox(height: 24),

          // 7. DATA & PRIVACY
          _buildSectionHeader(
            s.dataAndPrivacyHeader,
            icon: Icons.shield_outlined,
            accentColor: const Color(0xFFE11D48),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildDataAndPrivacyCard(context, provider, isDark, s),

          const SizedBox(height: 24),

          // 8. ABOUT & MEDICAL TRUST
          _buildSectionHeader(
            s.aboutAndTrustHeader,
            icon: Icons.info_outline_rounded,
            accentColor: const Color(0xFF0EA5E9),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildAboutCard(context, s, isDark),
        ],
      ),
    );
  }

  // ================= 0. APPEARANCE & THEME =================
  Widget _buildThemeCard(
    BuildContext context,
    ThemeProvider themeProvider,
    AppStrings s,
    bool isDark,
  ) {
    final currentMode = themeProvider.themeMode;

    Widget buildOption({
      required String title,
      required IconData icon,
      required ThemeMode mode,
      required List<Color> activeGradient,
    }) {
      final isSelected = currentMode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => themeProvider.setThemeMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: activeGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.35)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeGradient.first.withValues(alpha: isDark ? 0.4 : 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.palette_rounded,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                size: 46,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.appearanceThemeTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.appearanceThemeSub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              buildOption(
                title: s.themeLight,
                icon: Icons.wb_sunny_rounded,
                mode: ThemeMode.light,
                activeGradient: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
              ),
              const SizedBox(width: 8),
              buildOption(
                title: s.themeDark,
                icon: Icons.nightlight_round,
                mode: ThemeMode.dark,
                activeGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              const SizedBox(width: 8),
              buildOption(
                title: s.themeSystem,
                icon: Icons.brightness_auto_rounded,
                mode: ThemeMode.system,
                activeGradient: const [Color(0xFF3B82F6), Color(0xFF0284C7)],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 1. LOCAL DATA BACKUP & RESTORE =================
  Widget _buildLocalBackupCard(
    BuildContext context,
    MedicineProvider provider,
    AppStrings s,
    bool isDark,
  ) {
    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF0D9488),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.backup_rounded,
                gradientColors: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
                size: 46,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.deviceLocalBackupTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.deviceLocalBackupSub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Badge: Offline & Last Backup Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastBackupFormatted != null ? s.latestBackupDate(_lastBackupFormatted!) : s.noBackupFound,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Export & Restore
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _performLocalExport(context),
                  icon: const Icon(Icons.upload_file_rounded, size: 17),
                  label: Text(
                    s.exportBackupBtn,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                    shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLocalRestore(context, provider, s),
                  icon: const Icon(Icons.download_rounded, size: 17, color: Color(0xFF0D9488)),
                  label: Text(
                    s.restoreBackupBtn,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D9488), width: 1.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isDark
                        ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                        : const Color(0xFF0D9488).withValues(alpha: 0.04),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performLocalExport(BuildContext context) async {
    try {
      final success = await LocalBackupService.instance.exportBackup();
      if (success) {
        final formattedTime = DateFormat('MMM d, h:mm a').format(DateTime.now());
        await _savePreference('last_backup_time', formattedTime);
        setState(() {
          _lastBackupFormatted = formattedTime;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backup created and shared successfully!'),
              backgroundColor: Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Export failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmLocalRestore(BuildContext context, MedicineProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            _buildSquircleIcon(
              icon: Icons.restore_rounded,
              gradientColors: const [Color(0xFF0D9488), Color(0xFF06B6D4)],
              size: 40,
              iconSize: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.restoreBackupConfirmTitle,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          s.restoreBackupConfirmDesc,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancelBtn, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await LocalBackupService.instance.importBackup();
              if (result.success) {
                await provider.reloadAfterRestore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: const Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (result.message != 'No file selected.') {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.file_open_rounded, size: 16),
            label: Text(s.selectFileBtn, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ================= 2. FAMILY & PROFILES =================
  Widget _buildFamilyCard(
    BuildContext context,
    MedicineProvider provider,
    AppStrings s,
    bool isDark,
  ) {
    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF10B981),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          ...provider.profiles.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2644) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      (p.avatarEmoji.isNotEmpty && p.avatarEmoji != '👤')
                          ? Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(p.colorValue).withValues(alpha: 0.18),
                              ),
                              child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 22)),
                            )
                          : (p.svgAvatar.isNotEmpty
                              ? AppSvgIcons.render(p.svgAvatar, width: 42, height: 42)
                              : _buildSquircleIcon(
                                  icon: Icons.person,
                                  gradientColors: const [Color(0xFF0D9488), Color(0xFF10B981)],
                                  size: 42,
                                  iconSize: 22,
                                )),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name.toLowerCase() == 'myself' ? s.myself : p.name,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.age != null && p.age! > 0
                                    ? '${p.age} ${s.ageYears} · ${p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)}'
                                    : (p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (p.id == 'default_me')
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF10B981)),
                          tooltip: s.editMyProfile,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserOnboardingProfileScreen(isEditMode: true),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyMembersScreen()),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.groups_rounded,
                    gradientColors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    size: 36,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.manageFamilyMembers,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => ProfileSelectorSheet.show(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.person_add_rounded,
                    gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                    size: 36,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.addFamilyMemberTitle,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.add_rounded, size: 20, color: Color(0xFF10B981)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. REMINDERS =================
  Widget _buildReminderControlsCard(bool isDark, AppStrings s) {
    final snoozeOptions = [5, 10, 15, 30];

    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF8B5CF6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sound toggle
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.volume_up_rounded,
                gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.reminderSoundTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.reminderSoundDesc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _soundEnabled,
                activeThumbColor: const Color(0xFF8B5CF6),
                activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                onChanged: (val) {
                  setState(() => _soundEnabled = val);
                  _savePreference('reminder_sound_enabled', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Vibration toggle
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.vibration_rounded,
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFFB923C)],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.vibrationTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.vibrationDesc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _vibrationEnabled,
                activeThumbColor: const Color(0xFFFB923C),
                activeTrackColor: const Color(0xFFFB923C).withValues(alpha: 0.35),
                onChanged: (val) {
                  setState(() => _vibrationEnabled = val);
                  _savePreference('reminder_vibration_enabled', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Default Snooze
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.snooze_rounded,
                gradientColors: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.defaultSnoozeTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.defaultSnoozeDesc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Snooze chips row
          Row(
            children: snoozeOptions.map((min) {
              final isSelected = _snoozeMinutes == min;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _snoozeMinutes = min);
                      _savePreference('reminder_snooze_minutes', min);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0284C7)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${s.formatNumber(min)} ${s.minShort}',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Reminder Style
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.alarm_on_rounded,
                gradientColors: const [Color(0xFFE11D48), Color(0xFFF43F5E)],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.reminderStyleTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      s.reminderStyleDesc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Style selector pills
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _reminderBehavior = 'persistent');
                    _savePreference('reminder_behavior', 'persistent');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _reminderBehavior == 'persistent'
                          ? const Color(0xFFE11D48)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _reminderBehavior == 'persistent'
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 15,
                          color: _reminderBehavior == 'persistent' ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.persistentAlarm,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: _reminderBehavior == 'persistent' ? FontWeight.w800 : FontWeight.w600,
                            color: _reminderBehavior == 'persistent'
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _reminderBehavior = 'normal');
                    _savePreference('reminder_behavior', 'normal');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _reminderBehavior == 'normal'
                          ? const Color(0xFF0284C7)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _reminderBehavior == 'normal'
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 15,
                          color: _reminderBehavior == 'normal' ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.standardAlert,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: _reminderBehavior == 'normal' ? FontWeight.w800 : FontWeight.w600,
                            color: _reminderBehavior == 'normal'
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 4. SYSTEM PERMISSIONS =================
  Widget _buildPermissionAttentionBanner(bool isDark, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.22 : 0.12),
            const Color(0xFFEA580C).withValues(alpha: isDark ? 0.15 : 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _buildSquircleIcon(
            icon: Icons.warning_amber_rounded,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
            size: 38,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.permissionsRequiredTitle,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF9A3412),
                  ),
                ),
                Text(
                  s.permissionsRequiredSubtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFFC2410C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _requestAllPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 2,
            ),
            child: Text(s.fixAllBtn, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isGranted,
    required bool isDark,
    required VoidCallback onAction,
  }) {
    return _buildCardContainer(
      isDark: isDark,
      accentGlow: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildSquircleIcon(
            icon: icon,
            gradientColors: isGranted ? gradientColors : [const Color(0xFFF59E0B), const Color(0xFFFB923C)],
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Active',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
                elevation: 2,
              ),
              child: Text('Grant', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  // ================= 5. LANGUAGE =================
  Widget _buildLanguageSelector(
    BuildContext context,
    LanguageProvider lang,
    AppStrings s,
    bool isDark,
  ) {
    final current = lang.languageCode;
    final options = [
      {'code': 'bn', 'name': 'বাংলা', 'badge': 'BN'},
      {'code': 'en', 'name': 'English', 'badge': 'EN'},
      {'code': 'hi', 'name': 'हिन्दी', 'badge': 'HI'},
    ];

    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF0D9488),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSquircleIcon(
                icon: Icons.translate_rounded,
                gradientColors: const [Color(0xFF0D9488), Color(0xFF2DD4BF)],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.chooseLanguage,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.chooseLanguageSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final isSelected = current == opt['code'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => context.read<LanguageProvider>().setLanguage(opt['code']!),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF0F3E3A) : const Color(0xFFE6FFFA))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0D9488)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                opt['name']!,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488))
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            opt['badge']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ================= 7. DATA & PRIVACY =================
  Widget _buildDataAndPrivacyCard(
    BuildContext context,
    MedicineProvider provider,
    bool isDark,
    AppStrings s,
  ) {
    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFFE11D48),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          InkWell(
            onTap: () => _confirmClearHistory(context, provider, s),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.history_toggle_off_rounded,
                    gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    size: 38,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.clearHistoryTitle,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          s.clearHistorySubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFF59E0B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _confirmDeleteAllData(context, provider, s),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.delete_forever_rounded,
                    gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
                    size: 38,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.deleteAllDataTitle,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          s.deleteAllDataSubtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.error),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, MedicineProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(s.clearHistoryDialogTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          s.clearHistoryDialogContent,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearIntakeHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.clearHistoryTitle),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(s.clearHistoryTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllData(BuildContext context, MedicineProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(s.deleteAllDialogTitle, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.error)),
          ],
        ),
        content: Text(
          s.deleteAllDialogContent,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAllAppData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.allDataErasedMsg),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(s.deleteEverythingBtn, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ================= 8. ABOUT =================
  Widget _buildAboutCard(BuildContext context, AppStrings s, bool isDark) {
    return _buildCardContainer(
      isDark: isDark,
      accentGlow: const Color(0xFF0EA5E9),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/app_brand_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.appName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.safeMedicationCompanion,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.aboutDisclaimer,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen(isFromSettings: true)),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.auto_stories_rounded,
                    gradientColors: const [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    size: 34,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.replayOnboarding,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showDeveloperCreditsSheet(context, isDark, s),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: isDark ? 0.2 : 0.08),
                    const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.15 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildSquircleIcon(
                    icon: Icons.code_rounded,
                    gradientColors: const [Color(0xFF0D9488), Color(0xFF3B82F6)],
                    size: 34,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kadir Laskar',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                          ),
                        ),
                        Text(
                          s.founderRole,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: Color(0xFF0D9488),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeveloperCreditsSheet(BuildContext context, bool isDark, AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Creator Avatar with Verified Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF06B6D4), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'KL',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF0D9488),
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Creator Name
              Text(
                'Kadir Laskar',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              // Role & Title
              Text(
                s.founderRole,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.25 : 0.12),
                      const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.2 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Founder & Creator · MediRemind',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mission & Vision Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Text(
                          'Creator\'s Mission',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MediRemind was built with extreme dedication and care to ensure that you and your family never miss a vital medicine dose. Designed for reliability, intuitive privacy, and modern health tracking.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // GitHub Profile Button
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://github.com/kadirlaskar012');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.terminal_rounded, size: 18, color: Color(0xFF0D9488)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'github.com/kadirlaskar012',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'View Open Source Repositories',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF0D9488)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Open Source Licenses Button
              InkWell(
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'MediRemind',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Crafted with ❤️ by Kadir Laskar',
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.balance_rounded, size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Open Source Licenses & Packages',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.white38 : Colors.black38),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
