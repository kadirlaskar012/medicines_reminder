import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    'batteryIgnored': false,
  };
  bool _isChecking = true;
  bool _isAdminUnlocked = false;
  int _buildTapCount = 0;
  DateTime? _lastBuildTapTime;

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
    final themeProvider = context.watch<ThemeProvider>();
    final s = lang.strings;

    final hasMissingPermission = _permissionStatuses.values.any((status) => !status);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsAndDiagnostics),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // 1. Account & Supabase Cloud Sync Section (Prominent at Top)
          _buildSectionTitle(s.accountAndCloudSync),
          const SizedBox(height: 10),
          _buildAccountCard(context, auth, provider, s, isDark),

          const SizedBox(height: 24),

          // 2. Family Profiles Section
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    p.age != null && p.age! > 0
                        ? '${p.age} ${s.ageYears} • ${p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)}'
                        : (p.relation.toLowerCase() == 'myself' ? s.relationName('myself') : s.relationName(p.relation)),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: p.id == 'default_me'
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
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
                  leading: const Icon(Icons.people_outline_rounded, color: AppColors.primary),
                  title: const Text('Manage Family Members', style: TextStyle(fontWeight: FontWeight.w700)),
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
                  leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  title: Text(s.addFamilyMemberTitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  onTap: () => ProfileSelectorSheet.show(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Android Reliability Attention Banner (shown if any permission missing)
          if (hasMissingPermission) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
            const SizedBox(height: 20),
          ],

          // 4. Diagnostic Health Checks
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

          // 5. App Theme Selector Card
          _buildSectionTitle(s.themeOption),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
          ),

          const SizedBox(height: 24),

          // 6. Multi-Language Selector Card
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

          // 7. About & Medical Disclaimer
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
                InkWell(
                  onTap: () => _handleBuildVersionTap(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text(
                          '${s.appName} v1.0.1 (Build 2)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_open_rounded, size: 12, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'ADMIN UNLOCKED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.appDescription,
                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.4),
                ),
              ],
            ),
          ),

          // 8. Admin & Database Control (Owner Master Access) - Visible ONLY when Unlocked via 5-tap
          if (_isAdminUnlocked) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(s.code == 'bn' ? 'অ্যাডমিন ও ডেটাবেস কন্ট্রোল' : (s.code == 'hi' ? 'एडमिन व डेटाबेस कंट्रोल' : 'ADMIN & DATABASE CONTROL')),
            const SizedBox(height: 10),
            _buildAdminAccessCard(context, isDark, s),
          ],
        ],
      ),
    );
  }

  void _handleBuildVersionTap(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = lang.languageCode == 'bn';
    final isHi = lang.languageCode == 'hi';

    if (_isAdminUnlocked) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? 'অ্যাডমিন মোড ইতিমধ্যে আনলক করা আছে।'
                : (isHi ? 'एडमिन मोड पहले से अनलॉक है।' : 'Admin mode is already unlocked.'),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    if (_lastBuildTapTime == null || now.difference(_lastBuildTapTime!) > const Duration(seconds: 2)) {
      _buildTapCount = 1;
    } else {
      _buildTapCount++;
    }
    _lastBuildTapTime = now;

    if (_buildTapCount >= 5) {
      _buildTapCount = 0;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _promptAdminPasscode(context);
    } else if (_buildTapCount >= 2) {
      final remaining = 5 - _buildTapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBn
                ? 'অ্যাডমিন মোড আনলক করতে আর $remaining বার ট্যাপ করুন'
                : (isHi
                    ? 'एडमिन मोड अनलॉक करने के लिए और $remaining बार टैप करें'
                    : 'Tap $remaining more time${remaining > 1 ? "s" : ""} to unlock Admin Mode'),
          ),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAdminAccessCard(BuildContext context, bool isDark, AppStrings s) {
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
                      s.code == 'bn' ? 'অ্যাডমিন কন্ট্রোল প্যানেল' : (s.code == 'hi' ? 'एडमिन कंट्रोल पैनल' : 'Admin Control Panel'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.code == 'bn'
                          ? 'সমস্ত ইউজার, ক্লাউড ডেটাবেস এবং পিন রিসেট অনুরোধ নিয়ন্ত্রণ করুন।'
                          : (s.code == 'hi'
                              ? 'सभी उपयोगकर्ता, क्लाउड डेटाबेस व पिन रीसेट प्रबंधित करें।'
                              : 'Manage all users, cloud database and PIN reset requests.'),
                      style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.3),
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
                  MaterialPageRoute(builder: (_) => const AdminControlPanelScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
              label: Text(s.code == 'bn' ? 'অ্যাডমিন ড্যাশবোর্ড খুলুন' : (s.code == 'hi' ? 'एडमिन डैशबोर्ड खोलें' : 'Open Admin Dashboard')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
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

  void _promptAdminPasscode(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = lang.languageCode == 'bn';
    final isHi = lang.languageCode == 'hi';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isBn ? 'অ্যাডমিন ভেরিফিকেশন' : (isHi ? 'एडमिन सत्यापन' : 'Admin Verification'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBn
                    ? 'অ্যাডমিন প্যানেলে প্রবেশ করতে ৪-সংখ্যার মাস্টার পাসকোড লিখুন (ডিফল্ট: 2026):'
                    : (isHi
                        ? 'एडमिन पैनल खोलने के लिए 4-अंकों का मास्टर पासकोड दर्ज करें (डिफ़ॉल्ट: 2026):'
                        : 'Enter 4-digit Master Passcode to access Admin Panel (Default: 2026):'),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
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
              child: Text(isBn ? 'বাতিল' : (isHi ? 'रद्द करें' : 'Cancel')),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isBn
                                  ? '🔓 অ্যাডমিন মোড সক্রিয় হয়েছে! নিচে অ্যাডমিন প্যানেল দৃশ্যমান।'
                                  : (isHi
                                      ? '🔓 एडमिन मोड सक्रिय! नीचे एडमिन पैनल दिखाई दे रहा है।'
                                      : '🔓 Admin Mode Activated! Admin panel is now visible below.'),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminControlPanelScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBn ? '❌ ভুল অ্যাডমিন পাসকোড!' : (isHi ? '❌ गलत एडमिन पासकोड!' : '❌ Incorrect admin passcode!'),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(isBn ? 'আনলক করুন' : (isHi ? 'अनलॉक करें' : 'Unlock')),
            ),
          ],
        );
      },
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
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
                    child: const Icon(
                      Icons.mark_email_read_rounded,
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
                        auth.displayName ?? auth.email ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (auth.email != null)
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
              s.code == 'bn'
                  ? 'আপনার ইমেল অ্যাকাউন্টের মাধ্যমে ওষুধ ও রিমাইন্ডার ক্লাউডে সুরক্ষিত রয়েছে।'
                  : (s.code == 'hi'
                      ? 'आपका डेटा क्लाउड में सुरक्षित रूप से बैकअप है।'
                      : 'Your medicine data is securely synchronized to your email account in the cloud.'),
              style: const TextStyle(fontSize: 12, color: AppColors.lightTextMuted, height: 1.3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final ok = await CloudSyncService.instance.syncLocalToCloud(
                          profiles: provider.profiles,
                          medicines: provider.medicines,
                          remindersByMedicine: provider.remindersByMedicine,
                          records: provider.intakeRecords,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? '☁️ ${s.cloudSyncActive}' : '⚠️ ক্লাউড সিঙ্ক ব্যর্থ হয়েছে। API কী বা ইন্টারনেট চেক করুন।'),
                              backgroundColor: ok ? AppColors.success : AppColors.error,
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
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: Text(s.code == 'bn' ? 'ব্যাকআপ' : (s.code == 'hi' ? 'बैकअप' : 'Backup')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final userKey = auth.email ?? auth.phoneNumber;
                      if (userKey == null || userKey.isEmpty) return;
                      final count = await provider.restoreUserFromCloud(userKey);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🔄 $count টি ওষুধ ক্লাউড থেকে রিস্টোর হয়েছে!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_download_rounded, size: 18, color: AppColors.primary),
                    label: Text(s.code == 'bn' ? 'রিস্টোর' : (s.code == 'hi' ? 'रीस्टोर' : 'Restore')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => _confirmSignOut(context, auth, s),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  tooltip: s.signOutBtn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
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
              label: Text(s.signInOrLoginTitle),
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
