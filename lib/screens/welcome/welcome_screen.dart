import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import '../main_navigation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final bool isFromSettings;
  const WelcomeScreen({super.key, this.isFromSettings = false});

  static const String prefKeySeenWelcome = 'has_seen_welcome_screen';

  Future<void> _completeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeySeenWelcome, true);
    if (!context.mounted) return;

    if (isFromSettings) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainNavigationScreen(),
          transitionsBuilder: (context, animation, secAnim, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final s = lang.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F7F6),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient soft glowing background orbs
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Close button if opened from Settings
                  if (isFromSettings)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                  const Spacer(flex: 1),

                  // 3D Floating Medicine Cluster
                  SizedBox(
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // White Scored Tablet (Left)
                        Positioned(
                          left: 40,
                          top: 25,
                          child: Image.asset(
                            'assets/icons/3d/med_3d_tablet.png',
                            width: 85,
                            height: 85,
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .moveY(begin: 0, end: -8, duration: 1800.ms),
                        ),
                        // Amber Glass Syrup Bottle (Right)
                        Positioned(
                          right: 35,
                          top: 15,
                          child: Image.asset(
                            'assets/icons/3d/med_3d_syrup.png',
                            width: 95,
                            height: 95,
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .moveY(begin: 0, end: 10, duration: 2200.ms),
                        ),
                        // Royal Blue & Coral Capsule (Center Foreground)
                        Positioned(
                          top: 45,
                          child: Image.asset(
                            'assets/icons/3d/med_3d_capsule.png',
                            width: 105,
                            height: 105,
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .moveY(begin: 0, end: -12, duration: 1500.ms)
                           .rotate(begin: -0.05, end: 0.05, duration: 2000.ms),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.85, 0.85)),

                  const SizedBox(height: 16),

                  // Frosted Welcome Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          s.welcomeTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F2B2B),
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.welcomeSub,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),

                        // Feature Badges
                        _buildFeatureRow(
                          icon: Icons.alarm_on_rounded,
                          color: const Color(0xFF10B981),
                          text: s.exactAlarmsFeature,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.group_rounded,
                          color: const Color(0xFF0EA5E9),
                          text: s.familyProfilesFeature,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          icon: Icons.cloud_done_rounded,
                          color: const Color(0xFF8B5CF6),
                          text: s.cloudSyncFeature,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                  const Spacer(flex: 1),

                  // Language Quick-Selector Pill (English | বাংলা | हिंदी)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangChip(context, 'en', 'English', lang.languageCode == 'en'),
                        _buildLangChip(context, 'bn', 'বাংলা', lang.languageCode == 'bn'),
                        _buildLangChip(context, 'hi', 'हिन्दी', lang.languageCode == 'hi'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                  const SizedBox(height: 20),

                  // "Get Started" Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _completeWelcome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        s.getStarted,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(BuildContext context, String code, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<LanguageProvider>().setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
