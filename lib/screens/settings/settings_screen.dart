import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/profile_selector_sheet.dart';
import '../admin/admin_control_panel_screen.dart';
import '../auth/phone_login_screen.dart';
import '../family/family_members_screen.dart';
import '../welcome/user_onboarding_profile_screen.dart';

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
  bool _isAdminUnlocked = false;
  int _buildTapCount = 0;
  DateTime? _lastBuildTapTime;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.battery_alert_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keep MediRemind Reliable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Some Android devices delay or silence scheduled medicine reminders when battery saver or optimization is enabled.\n\nTo make sure your doses ring accurately on time, allow MediRemind background activity.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Permission.ignoreBatteryOptimizations.request();
              } catch (_) {}
              _checkPermissions();
            },
            child: const Text('Allow Background Activity'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final s = lang.strings;

    final isNotifGranted = _permissionStatuses['notification'] ?? false;
    final isAlarmGranted = _permissionStatuses['exactAlarm'] ?? false;
    final isBatteryGranted = _permissionStatuses['batteryOptimization'] ?? false;
    final hasMissingPermission = !isNotifGranted || !isAlarmGranted || !isBatteryGranted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          s.settingsAndDiagnostics,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
        children: [
          // 1. ACCOUNT & CLOUD SYNC
          _buildSectionHeader('ACCOUNT & CLOUD SYNC'),
          const SizedBox(height: 8),
          _buildAccountCard(context, auth, provider, s, isDark),

          const SizedBox(height: 24),

          // 2. FAMILY & PROFILES
          _buildSectionHeader('FAMILY & PROFILES'),
          const SizedBox(height: 8),
          _buildFamilyCard(context, provider, s, isDark),

          const SizedBox(height: 24),

          // 3. REMINDERS (Sound, Vibration, Snooze, Behavior)
          _buildSectionHeader('REMINDERS'),
          const SizedBox(height: 8),
          _buildReminderControlsCard(isDark),

          const SizedBox(height: 24),

          // 4. SYSTEM PERMISSIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('SYSTEM PERMISSIONS'),
              if (_isChecking)
                const SizedBox(
                  width: 14,
                  height: 14,
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
            _buildPermissionAttentionBanner(isDark),
            const SizedBox(height: 12),
          ],

          _buildPermissionTile(
            title: 'Notification Permission',
            description: 'Allows MediRemind to show medicine reminder alerts.',
            isGranted: isNotifGranted,
            isDark: isDark,
            onAction: () async {
              await Permission.notification.request();
              _checkPermissions();
            },
          ),
          const SizedBox(height: 8),

          _buildPermissionTile(
            title: 'Exact Alarm Permission',
            description: 'Ensures scheduled dose alarms trigger on the exact minute.',
            isGranted: isAlarmGranted,
            isDark: isDark,
            onAction: () async {
              try {
                await Permission.scheduleExactAlarm.request();
              } catch (_) {}
              _checkPermissions();
            },
          ),
          const SizedBox(height: 8),

          _buildPermissionTile(
            title: 'Battery Optimization',
            description: 'Prevents Android system from delaying background dose alarms.',
            isGranted: isBatteryGranted,
            isDark: isDark,
            onAction: _showBatteryOptimizationDialog,
          ),

          const SizedBox(height: 24),

          // 5. APPEARANCE
          _buildSectionHeader('APPEARANCE'),
          const SizedBox(height: 8),
          _buildThemeSelector(context, themeProvider, s, isDark),

          const SizedBox(height: 24),

          // 6. LANGUAGE
          _buildSectionHeader('LANGUAGE'),
          const SizedBox(height: 8),
          _buildLanguageSelector(context, lang, s, isDark),

          const SizedBox(height: 24),

          // 7. DATA & PRIVACY
          _buildSectionHeader('DATA & PRIVACY'),
          const SizedBox(height: 8),
          _buildDataAndPrivacyCard(context, provider, isDark),

          const SizedBox(height: 24),

          // 8. ABOUT & MEDICAL TRUST
          _buildSectionHeader('ABOUT'),
          const SizedBox(height: 8),
          _buildAboutCard(context, s, isDark),

          // 9. Admin & Database Control (Unlocked via 5-tap)
          if (_isAdminUnlocked) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('ADMIN & DATABASE CONTROL'),
            const SizedBox(height: 8),
            _buildAdminAccessCard(context, isDark, s),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ================= 1. ACCOUNT & CLOUD SYNC =================
  Widget _buildAccountCard(
    BuildContext context,
    AuthProvider auth,
    MedicineProvider provider,
    AppStrings s,
    bool isDark,
  ) {
    if (auth.isSignedIn) {
      final displayName = auth.displayName ?? auth.email ?? auth.phoneNumber ?? 'User';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (auth.photoUrl != null)
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(auth.photoUrl!),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (auth.email != null)
                        Text(
                          auth.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Cloud Sync Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                          if (_lastBackupFormatted != null) ...[
                            Text(
                              ' · $_lastBackupFormatted',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, auth, s),
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                  label: Text(
                    s.signOutBtn,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _performBackup(context, provider, s),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                    label: const Text('Backup Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRestore(context, auth, provider, s),
                    icon: const Icon(Icons.cloud_download_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Guest / Offline Mode Card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Sync Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sign in to automatically sync and protect your medicines in the cloud.',
                      style: TextStyle(
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneLoginScreen(isModal: true)),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text(s.signInOrLoginTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context, MedicineProvider provider, AppStrings s) async {
    try {
      final ok = await CloudSyncService.instance.syncLocalToCloud(
        profiles: provider.profiles,
        medicines: provider.medicines,
        remindersByMedicine: provider.remindersByMedicine,
        records: provider.intakeRecords,
      );
      if (ok) {
        final formattedTime = DateFormat('h:mm a').format(DateTime.now());
        await _savePreference('last_backup_time', 'Today, $formattedTime');
        setState(() {
          _lastBackupFormatted = 'Today, $formattedTime';
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? '☁️ Cloud backup completed successfully.'
                : '⚠️ Cloud backup could not be completed. Check connection and retry.'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmRestore(BuildContext context, AuthProvider auth, MedicineProvider provider, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Backup?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Your current medication data and schedules will be merged with your saved cloud backup.\n\nDo you want to proceed?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final userKey = auth.email ?? auth.phoneNumber;
              if (userKey == null || userKey.isEmpty) return;
              final count = await provider.restoreUserFromCloud(userKey);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔄 Successfully restored $count medicines from backup.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Continue Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider auth, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.signOutConfirmTitle),
        content: Text(s.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (mounted) {
                setState(() {});
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.code == 'bn'
                        ? '👋 সফলভাবে লগআউট হয়েছে।'
                        : (s.code == 'hi' ? '👋 सफलतापूर्वक लॉगआउट हुआ।' : '👋 Successfully signed out.')),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.signOutBtn),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          ...provider.profiles.map((p) => ListTile(
                leading: (p.avatarEmoji.isNotEmpty && p.avatarEmoji != '👤')
                    ? Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(p.colorValue).withValues(alpha: 0.15),
                        ),
                        child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 20)),
                      )
                    : (p.svgAvatar.isNotEmpty
                        ? AppSvgIcons.render(p.svgAvatar, width: 36, height: 36)
                        : const Icon(Icons.person, color: AppColors.primary)),
                title: Text(
                  p.name.toLowerCase() == 'myself' ? s.myself : p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  p.age != null && p.age! > 0
                      ? '${p.age} ${s.ageYears} · ${p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)}'
                      : (p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                trailing: p.id == 'default_me'
                    ? IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        tooltip: s.editMyProfile,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserOnboardingProfileScreen(isEditMode: true),
                            ),
                          );
                        },
                      )
                    : null,
              )),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 22),
            title: Text(
              'Manage Family Members',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyMembersScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
            title: Text(
              s.addFamilyMemberTitle,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onTap: () => ProfileSelectorSheet.show(context),
          ),
        ],
      ),
    );
  }

  // ================= 3. REMINDERS =================
  Widget _buildReminderControlsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Sound toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Reminder Sound',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Play auditory alert during scheduled dose reminders',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            value: _soundEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: (val) {
              setState(() => _soundEnabled = val);
              _savePreference('reminder_sound_enabled', val);
            },
          ),
          const Divider(height: 16),

          // Vibration toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Vibration',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Vibrate phone when a medication alarm rings',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            value: _vibrationEnabled,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.success,
            onChanged: (val) {
              setState(() => _vibrationEnabled = val);
              _savePreference('reminder_vibration_enabled', val);
            },
          ),
          const Divider(height: 16),

          // Snooze duration selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Snooze',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Interval when tapping Snooze',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _snoozeMinutes,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 min', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 10, child: Text('10 min', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 15, child: Text('15 min', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 30, child: Text('30 min', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _snoozeMinutes = val);
                        _savePreference('reminder_snooze_minutes', val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Reminder behavior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Style',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Persistent alarm or standard alert',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _reminderBehavior,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: 'persistent',
                        child: Text('Persistent Alarm', style: TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('Standard Alert', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _reminderBehavior = val);
                        _savePreference('reminder_behavior', val);
                      }
                    },
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
  Widget _buildPermissionAttentionBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Permissions Needed',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grant permissions to guarantee alarms fire accurately without Android battery delay.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _requestAllPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Fix All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String description,
    required bool isGranted,
    required bool isDark,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: isGranted ? AppColors.success : AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓ Active',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Fix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  // ================= 5. APPEARANCE =================
  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
    AppStrings s,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          _buildThemeButton(
            context,
            ThemeMode.system,
            s.themeSystem,
            Icons.brightness_auto_rounded,
            themeProvider.themeMode == ThemeMode.system,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildThemeButton(
            context,
            ThemeMode.light,
            s.themeLight,
            Icons.wb_sunny_rounded,
            themeProvider.themeMode == ThemeMode.light,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildThemeButton(
            context,
            ThemeMode.dark,
            s.themeDark,
            Icons.nightlight_round,
            themeProvider.themeMode == ThemeMode.dark,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    bool isSelected,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ThemeProvider>().setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 6. LANGUAGE =================
  Widget _buildLanguageSelector(
    BuildContext context,
    LanguageProvider lang,
    AppStrings s,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferred Language',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Choose language for user interface',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: lang.languageCode,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'bn', child: Text('বাংলা', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    context.read<LanguageProvider>().setLanguage(val);
                  }
                },
              ),
            ),
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
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history_toggle_off_rounded, color: AppColors.textSecondary, size: 22),
            title: Text(
              'Clear Intake History',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Clear past taken and missed records without removing medicines',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            onTap: () => _confirmClearHistory(context, provider),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
            title: const Text(
              'Delete All MediRemind Data',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
            subtitle: Text(
              'Permanently remove all local medicines, alarms, and history',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            onTap: () => _confirmDeleteAllData(context, provider),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, MedicineProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Intake History?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'This will reset all past dose logs and adherence charts to zero. Your medicine schedule will remain active.\n\nAre you sure you want to clear history?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearIntakeHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intake history cleared successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllData(BuildContext context, MedicineProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete All Data?', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
          ],
        ),
        content: const Text(
          'This will permanently delete:\n• All medicines in cabinet\n• All scheduled reminder alarms\n• Complete intake and adherence history\n• Custom family profiles\n\nThis action cannot be undone.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteAllAppData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local MediRemind data has been erased.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  // ================= 8. ABOUT =================
  Widget _buildAboutCard(BuildContext context, AppStrings s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _handleBuildVersionTap(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Text(
                    '${s.appName} v1.0.1 (Build 2)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  if (_isAdminUnlocked) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber, width: 0.8),
                      ),
                      child: const Text(
                        'ADMIN UNLOCKED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'MediRemind is a personal medication management and schedule tracking utility. It is not intended to diagnose, treat, or replace professional medical advice.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBuildVersionTap(BuildContext context) {
    if (_isAdminUnlocked) return;

    final now = DateTime.now();
    if (_lastBuildTapTime == null || now.difference(_lastBuildTapTime!) > const Duration(seconds: 2)) {
      _buildTapCount = 1;
    } else {
      _buildTapCount++;
    }
    _lastBuildTapTime = now;

    if (_buildTapCount >= 5) {
      _buildTapCount = 0;
      _promptAdminPasscode(context);
    }
  }

  Widget _buildAdminAccessCard(BuildContext context, bool isDark, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Control Panel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage users, cloud database tables, and PIN resets.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminControlPanelScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_customize_rounded, size: 16),
              label: const Text('Open Admin Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _promptAdminPasscode(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Admin Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter 4-digit Master Passcode to open Admin Panel (Default: 2026):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Passcode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final code = controller.text.trim();
              if (code == SupabaseService.masterAdminPasscode) {
                Navigator.pop(ctx);
                setState(() {
                  _isAdminUnlocked = true;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminControlPanelScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Incorrect passcode!'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
