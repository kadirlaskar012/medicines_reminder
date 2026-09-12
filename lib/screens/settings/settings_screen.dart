import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/profile_selector_sheet.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Diagnostics'),
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
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Android Alarm Reliability',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'To ensure medicines ring precisely on time on Android 12, 13, 14, and 15+, make sure all permissions below are active.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _requestAllPermissions,
                  icon: const Icon(Icons.security_update_good_rounded, size: 18),
                  label: const Text('Grant All Permissions'),
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
              _buildSectionTitle('SYSTEM PERMISSIONS (ANDROID 12-15+)'),
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
            title: 'Notification Permission',
            subtitle: 'Required by Android 13+ to show alerts and reminders.',
            isGranted: _permissionStatuses['notification'] ?? false,
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildDiagnosticTile(
            title: 'Exact Alarm Permission',
            subtitle: 'Required on Android 12 & 14+ for zero-delay alarms.',
            isGranted: _permissionStatuses['exactAlarm'] ?? false,
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildDiagnosticTile(
            title: 'Ignore Battery Optimization',
            subtitle: 'Prevents Samsung/Xiaomi/OnePlus from putting alarms to sleep.',
            isGranted: _permissionStatuses['batteryIgnored'] ?? false,
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Instant Test Alarm
          _buildSectionTitle('ALARM SOUND & BANNER TEST'),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Test Alarm Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Trigger real notifications with custom medicine icons.', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
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
                            const SnackBar(
                              content: Text('💊 Tablet notification dispatched!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      icon: const Text('💊', style: TextStyle(fontSize: 14)),
                      label: const Text('Tablet'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await NotificationService.instance.showTestNotification(type: MedicineType.syrup);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🧪 Syrup notification dispatched!'),
                              backgroundColor: Color(0xFFD97706),
                            ),
                          );
                        }
                      },
                      icon: const Text('🧪', style: TextStyle(fontSize: 14)),
                      label: const Text('Syrup'),
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
                            const SnackBar(
                              content: Text('💉 Injection notification dispatched!'),
                              backgroundColor: Color(0xFF2563EB),
                            ),
                          );
                        }
                      },
                      icon: const Text('💉', style: TextStyle(fontSize: 14)),
                      label: const Text('Injection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profile Management
          _buildSectionTitle('FAMILY MEMBERS & PROFILES'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ...provider.profiles.map((p) {
                  return ListTile(
                    leading: Text(p.avatarEmoji, style: const TextStyle(fontSize: 24)),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(p.relation),
                    trailing: p.id != 'default_me'
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                            onPressed: () => provider.deleteProfile(p.id),
                          )
                        : null,
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  title: const Text('Add Family Member', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  onTap: () => ProfileSelectorSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About & Medical Disclaimer
          _buildSectionTitle('ABOUT MEDIREMIND'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MediRemind v1.0.0', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'Designed for reliable, on-time medication schedules across all Android versions. Private, offline-first, and battery-friendly.',
                  style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
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
              isGranted ? 'Active' : 'Missing',
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
}
