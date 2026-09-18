import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import 'user_onboarding_profile_screen.dart';

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() => _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen> {
  final List<Map<String, String>> _languages = const [
    {
      'code': 'bn',
      'name': 'Bengali',
      'nativeName': 'বাংলা',
      'badge': 'বাংলা',
      'preview': 'ওষুধের সঠিক রিমাইন্ডার ও স্টক ট্র্যাকিং',
    },
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'badge': 'EN',
      'preview': 'Timely medication reminders & stock tracking',
    },
    {
      'code': 'hi',
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'badge': 'हिन्दी',
      'preview': 'दवा की सही खुराक और समय पर रिमाइंडर',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final s = langProvider.strings;
    final currentCode = langProvider.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glowing background orbs
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentMint.withValues(alpha: isDark ? 0.15 : 0.08),
                ),
              ),
            ),

            Column(
              children: [
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                  child: Column(
                    children: [
                      // Globe Icon with subtle glow
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryTeal,
                              AppColors.primaryTealLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.language_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 20),

                      Text(
                        s.chooseLanguage,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        s.chooseLanguageSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Language Selection Cards List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _languages.length,
                    itemBuilder: (context, index) {
                      final item = _languages[index];
                      final isSelected = item['code'] == currentCode;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            langProvider.setLanguage(item['code']!);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.primaryTeal.withValues(alpha: 0.18)
                                      : const Color(0xFFF0FDF4))
                                  : (isDark ? AppColors.darkCard : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primaryTeal.withValues(alpha: isDark ? 0.25 : 0.15)
                                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: isSelected ? 16 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Badge / Script Icon
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryTeal.withValues(alpha: 0.2)
                                        : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryTeal.withValues(alpha: 0.4)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    item['badge']!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? AppColors.primaryTealLight
                                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Title & Native Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item['nativeName']!,
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (item['name'] != item['nativeName']) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '(${item['name']})',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['preview']!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Radio / Checkmark Indicator
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryTeal
                                          : (isDark ? AppColors.darkBorder : Colors.grey.shade400),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
                    },
                  ),
                ),

                // Bottom Action: Continue Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserOnboardingProfileScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.continueBtn,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
