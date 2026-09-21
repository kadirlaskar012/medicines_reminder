import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import 'onboarding_language_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool isFromSettings;
  const WelcomeScreen({super.key, this.isFromSettings = false});

  static const String prefKeySeenWelcome = 'has_seen_welcome_screen';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WelcomeScreen.prefKeySeenWelcome, true);
    if (!context.mounted) return;

    if (widget.isFromSettings) {
      Navigator.pop(context);
    } else {
      // Prompt for permissions after onboarding pages have been viewed
      await NotificationService.instance.requestPermissions();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingLanguageScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final s = lang.strings;
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
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
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
                // Top bar: Skip button & language selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Language Chip
                      _buildLangChip(context, lang),

                      // Skip / Close
                      if (widget.isFromSettings)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      else if (_currentPage < 3)
                        TextButton(
                          onPressed: () => _completeWelcome(context),
                          child: Text(
                            s.skip,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // PageView for Screens 01, 02, 03, 04
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    children: [
                      // SCREEN 01: Splash / Welcome
                      _buildSplashPage(isDark, s),
                      // SCREEN 02: Onboarding 1
                      _buildOnboardingPage(
                        isDark: isDark,
                        assetImage: 'assets/icons/3d/med_3d_tablet.png',
                        title: lang.languageCode == 'bn' ? 'নিয়ম মেনে চলুন, সুস্থ থাকুন' : (lang.languageCode == 'hi' ? 'समय पर दवा, स्वस्थ जीवन' : 'Stay on Track, Stay Healthy'),
                        subtitle: lang.languageCode == 'bn' ? 'কখনও ডোজ মিস করবেন না। সহজে ওষুধের সময়সূচী নির্ধারণ করুন।' : (lang.languageCode == 'hi' ? 'कभी कोई खुराक न भूलें। आसानी से दवाओं का समय तय करें।' : 'Never miss a dose again. Set personalized medicine schedules effortlessly.'),
                      ),
                      // SCREEN 03: Onboarding 2
                      _buildOnboardingPage(
                        isDark: isDark,
                        assetImage: 'assets/icons/3d/med_3d_syrup.png',
                        title: lang.languageCode == 'bn' ? 'নিজের ও পরিবারের যত্ন নিন' : (lang.languageCode == 'hi' ? 'अपने और परिवार का ख्याल रखें' : 'Manage for You & Your Family'),
                        subtitle: lang.languageCode == 'bn' ? 'একই অ্যাপে নিজের ও প্রিয়জনদের প্রেসক্রিপশন ও ওষুধের হিসাব রাখুন।' : (lang.languageCode == 'hi' ? 'एक ही ऐप से पूरे परिवार की दवाइयों का प्रबंधन करें।' : 'Track prescriptions for loved ones from a single profile seamlessly.'),
                      ),
                      // SCREEN 04: Onboarding 3
                      _buildOnboardingPage(
                        isDark: isDark,
                        assetImage: 'assets/icons/3d/med_3d_capsule.png',
                        title: lang.languageCode == 'bn' ? 'স্বাস্থ্য রিপোর্ট ও অ্যানালিটিক্স' : (lang.languageCode == 'hi' ? 'स्वास्थ्य रिपोर्ट और विश्लेषण' : 'Get Useful Health Insights'),
                        subtitle: lang.languageCode == 'bn' ? 'ওষুধ খাওয়ার প্রবণতা, শতাংশ ও চিকিৎসকের জন্য পিডিএফ রিপোর্ট তৈরি করুন।' : (lang.languageCode == 'hi' ? 'दवा लेने का रिकॉर्ड देखें और डॉक्टर के लिए रिपोर्ट निर्यात करें।' : 'Visualize intake trends, adherence rates, and export doctor reports in 1 click.'),
                      ),
                    ],
                  ),
                ),

                // Bottom Page Indicators & Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    children: [
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final isActive = _currentPage == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isActive ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Primary CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < 3) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _completeWelcome(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 0
                                    ? s.getStarted
                                    : (_currentPage == 3
                                        ? (lang.languageCode == 'bn' ? "চলুন শুরু করি →" : (lang.languageCode == 'hi' ? "शुरू करें →" : "Let's Start →"))
                                        : (lang.languageCode == 'bn' ? "পরবর্তী →" : (lang.languageCode == 'hi' ? "अगला →" : "Next →"))),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // SCREEN 01: Splash Screen Page
  Widget _buildSplashPage(bool isDark, dynamic s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // 3D Medicine Bottle Illustration Cluster
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing circular backdrop
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Tablet floating left
                Positioned(
                  left: 30,
                  top: 30,
                  child: Image.asset(
                    'assets/icons/3d/med_3d_tablet.png',
                    width: 70,
                    height: 70,
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .moveY(begin: 0, end: -10, duration: 1800.ms),
                ),

                // Main Medicine Bottle / Capsule in center
                Image.asset(
                  'assets/icons/3d/med_3d_syrup.png',
                  width: 130,
                  height: 130,
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .moveY(begin: -5, end: 5, duration: 2200.ms),

                // Dual capsule floating right
                Positioned(
                  right: 35,
                  bottom: 30,
                  child: Image.asset(
                    'assets/icons/3d/med_3d_capsule.png',
                    width: 75,
                    height: 75,
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .moveY(begin: 0, end: 8, duration: 1600.ms),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // App Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icons/app_brand_logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Tagline: "Small Reminders, Big Healthier Tomorrows"
          Text(
            s.appTagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.accentMint,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            s.welcomeSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              height: 1.4,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // Generic Onboarding Page (Screens 02, 03, 04)
  Widget _buildOnboardingPage({
    required bool isDark,
    required String assetImage,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // 3D Illustration
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            ),
            child: Center(
              child: Image.asset(
                assetImage,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .moveY(begin: -6, end: 6, duration: 2000.ms),
            ),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildLangChip(BuildContext context, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<String>(
        onSelected: (code) => lang.setLanguage(code),
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'en', child: Text('English')),
          const PopupMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
          const PopupMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              lang.languageCode == 'bn' ? 'বাংলা' : (lang.languageCode == 'hi' ? 'हिन्दी' : 'English'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
