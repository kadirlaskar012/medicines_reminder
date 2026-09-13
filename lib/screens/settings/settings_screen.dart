import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/profile_selector_sheet.dart';
import '../auth/phone_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> _permissionStatuses = {
    'notification': true,
    'exactAlarm': true,
    'batteryIgnored': false,
  };
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MedicineProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final s = lang.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsAndDiagnostics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // Android 12 - 15+ Reliability Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.androidAlarmReliability,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.androidAlarmSub,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _requestAllPermissions,
                  icon: const Icon(Icons.security_update_good_rounded, size: 18),
                  label: Text(s.grantAllPermissions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Diagnostic Health Checks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(s.systemPermissions),
              if (_isChecking)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: _checkPermissions,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),

          _buildDiagnosticTile(
            title: s.notificationPermission,
            subtitle: s.notifSub,
            isGranted: _permissionStatuses['notification'] ?? false,
            isDark: isDark,
            s: s,
          ),
          const SizedBox(height: 8),

          _buildDiagnosticTile(
            title: s.exactAlarmPermission,
            subtitle: s.exactAlarmSub,
            isGranted: _permissionStatuses['exactAlarm'] ?? false,
            isDark: isDark,
            s: s,
          ),
          const SizedBox(height: 8),

          _buildDiagnosticTile(
            title: s.batteryOptimization,
            subtitle: s.batteryOptimizationSub,
            isGranted: _permissionStatuses['batteryIgnored'] ?? false,
            isDark: isDark,
            s: s,
          ),

          const SizedBox(height: 24),

          // Instant Test Alarm
          _buildSectionTitle(s.alarmSoundBannerTest),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.ring_volume_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.testAlarmNotifications, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(s.testAlarmSub, style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.showTestNotification(type: MedicineType.tablet);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('💊 ${s.notificationDispatched(s.tablet)}'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      icon: const Text('💊', style: TextStyle(fontSize: 14)),
                      label: Text(s.tablet),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.showTestNotification(type: MedicineType.syrup);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🧪 ${s.notificationDispatched(s.syrup)}'),
                              backgroundColor: const Color(0xFFD97706),
                            ),
                          );
                        }
                      },
                      icon: const Text('🧪', style: TextStyle(fontSize: 14)),
                      label: Text(s.syrup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.showTestNotification(type: MedicineType.injection);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('💉 ${s.notificationDispatched(s.injection)}'),
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                          );
                        }
                      },
                      icon: const Text('💉', style: TextStyle(fontSize: 14)),
                      label: Text(s.injection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account & Cloud Sync Section
          _buildSectionTitle(s.accountAndCloudSync),
          const SizedBox(height: 10),
          _buildAccountCard(context, auth, provider, s, isDark),

          const SizedBox(height: 24),

          // Family Profiles Section
          _buildSectionTitle(s.familyMembersProfiles),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ...provider.profiles.map((p) => ListTile(
                  leading: p.svgAvatar.isNotEmpty
                      ? AppSvgIcons.render(p.svgAvatar, width: 36, height: 36)
                      : const Icon(Icons.person, color: AppColors.primary),
                  title: Text((p.id == 'default_me' || p.name.toLowerCase() == 'myself') ? s.myself : p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text((p.id == 'default_me' || p.relation.toLowerCase() == 'myself') ? s.relationName('myself') : s.relationName(p.relation), style: const TextStyle(fontSize: 12)),
                )),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  title: Text(s.addFamilyMemberTitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  onTap: () => ProfileSelectorSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Multi-Language Selector Card
          _buildSectionTitle(s.languageOption),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.selectLanguage,
                  style: const TextStyle(fontSize: 13, color: AppColors.lightTextMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildLanguageButton(context, 'en', 'English', '🇬🇧', lang.languageCode == 'en', isDark),
                    const SizedBox(width: 8),
                    _buildLanguageButton(context, 'bn', 'বাংলা', '🇧🇩', lang.languageCode == 'bn', isDark),
                    const SizedBox(width: 8),
                    _buildLanguageButton(context, 'hi', 'हिन्दी', '🇮🇳', lang.languageCode == 'hi', isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About & Medical Disclaimer
          _buildSectionTitle(s.aboutMediRemind),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.appName} v1.0.0', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  s.appDescription,
                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String code,
    String label,
    String flag,
    bool isSelected,
    bool isDark,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<LanguageProvider>().setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.lightTextMuted,
      ),
    );
  }

  Widget _buildDiagnosticTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isDark,
    required AppStrings s,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isGranted ? AppColors.success : AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isGranted ? s.activeBadge : s.missingBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isGranted ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    AuthProvider auth,
    MedicineProvider provider,
    AppStrings s,
    bool isDark,
  ) {
    if (auth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      auth.email != null ? Icons.account_circle_rounded : Icons.phone_android_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName ?? auth.email ?? auth.phoneNumber ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (auth.displayName != null && auth.email != null)
                        Text(
                          auth.email!,
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.cloudSyncActive,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              s.phoneLoginSub,
              style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await CloudSyncService.instance.syncLocalToCloud(
                          profiles: provider.profiles,
                          medicines: provider.medicines,
                          records: provider.intakeRecords,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('☁️ ${s.cloudSyncActive}'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync note: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                    label: Text(s.code == 'bn' ? 'সিঙ্ক করুন' : (s.code == 'hi' ? 'सिंक करें' : 'Sync Now')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context, auth, s),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  label: Text(s.signOutBtn, style: const TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.cloudSyncInactive,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.loginToBackup,
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
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
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(s.phoneLoginTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.signOutBtn),
          ),
        ],
      ),
    );
  }
}
