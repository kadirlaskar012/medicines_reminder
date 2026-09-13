import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';
import '../main_navigation_screen.dart';
import 'welcome_screen.dart';

class UserOnboardingProfileScreen extends StatefulWidget {
  final bool isEditMode;
  const UserOnboardingProfileScreen({super.key, this.isEditMode = false});

  @override
  State<UserOnboardingProfileScreen> createState() => _UserOnboardingProfileScreenState();
}

class _UserOnboardingProfileScreenState extends State<UserOnboardingProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  final List<Map<String, dynamic>> _avatarOptions = [
    {'emoji': '👨', 'label': 'পুরুষ', 'color': 0xFF0D9488},
    {'emoji': '👩', 'label': 'মহিলা', 'color': 0xFFEC4899},
    {'emoji': '👦', 'label': 'তরুণ', 'color': 0xFF0284C7},
    {'emoji': '👧', 'label': 'তরুণী', 'color': 0xFF8B5CF6},
    {'emoji': '👴', 'label': 'প্রবীণ', 'color': 0xFFD97706},
    {'emoji': '👵', 'label': 'প্রবীণা', 'color': 0xFFE11D48},
    {'emoji': '👤', 'label': 'সাধারণ', 'color': 0xFF10B981},
  ];

  late String _selectedEmoji;
  late int _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = _avatarOptions[0]['emoji'] as String;
    _selectedColor = _avatarOptions[0]['color'] as int;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MedicineProvider>();
      final primary = provider.primaryProfile;
      if (primary.name.isNotEmpty && primary.name.toLowerCase() != 'myself') {
        _nameController.text = primary.name;
      }
      if (primary.age != null && primary.age! > 0) {
        _ageController.text = primary.age.toString();
      }
      if (primary.avatarEmoji.isNotEmpty) {
        final match = _avatarOptions.firstWhere(
          (opt) => opt['emoji'] == primary.avatarEmoji,
          orElse: () => _avatarOptions[0],
        );
        setState(() {
          _selectedEmoji = match['emoji'] as String;
          _selectedColor = match['color'] as int;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveAndProceed({bool isSkip = false}) async {
    final s = context.read<LanguageProvider>().strings;
    final provider = context.read<MedicineProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(WelcomeScreen.prefKeySeenWelcome, true);

    if (isSkip) {
      if (!mounted) return;
      _navigateToMain();
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.nameRequired),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ageText = _ageController.text.trim();
    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age <= 0 || age > 120) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(s.ageRequired),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    await provider.saveInitialUserProfile(
      name: name,
      age: age,
      avatarEmoji: _selectedEmoji,
      colorValue: _selectedColor,
    );

    if (!mounted) return;

    if (widget.isEditMode) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.profileUpdated),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      nav.pop();
    } else {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F7F6),
      appBar: widget.isEditMode
          ? AppBar(
              title: Text(s.editMyProfile),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glowing background orbs
            Positioned(
              top: -40,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
                ),
              ),
            ),

            // Scrollable Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Step Icon & Title
                      if (!widget.isEditMode) ...[
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _selectedEmoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                          ),
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 18),
                        Text(
                          s.setupProfileTitle,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          s.setupProfileSub,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                        const SizedBox(height: 28),
                      ],

                      // Main Setup Card
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Choose Avatar
                            Text(
                              s.chooseAvatar,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _avatarOptions.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final opt = _avatarOptions[index];
                                  final emoji = opt['emoji'] as String;
                                  final isSelected = _selectedEmoji == emoji;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedEmoji = emoji;
                                        _selectedColor = opt['color'] as int;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.16)
                                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : Colors.transparent,
                                          width: 2.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: TextStyle(
                                            fontSize: isSelected ? 24 : 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(height: 1),
                            ),

                            // 2. Name Input Field
                            Text(
                              s.yourName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: s.enterNameHint,
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 3. Age Input Field
                            Text(
                              s.yourAge,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              decoration: InputDecoration(
                                hintText: s.enterAgeHint,
                                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.secondary),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Text(
                                    s.ageYears,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 28),

                      // Primary Button: Complete Setup / Save Changes
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _saveAndProceed(isSkip: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  widget.isEditMode ? s.saveChanges : s.completeSetupBtn,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),

                      // Secondary Button: Skip for now (Only in onboarding)
                      if (!widget.isEditMode) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _saveAndProceed(isSkip: true),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            s.skipForNow,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
