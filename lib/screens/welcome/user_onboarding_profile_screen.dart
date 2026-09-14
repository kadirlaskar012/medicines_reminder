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
    {'emoji': '👨', 'label': 'Man', 'color': 0xFF0D9488},
    {'emoji': '👩', 'label': 'Woman', 'color': 0xFFEC4899},
    {'emoji': '👦', 'label': 'Boy', 'color': 0xFF0284C7},
    {'emoji': '👧', 'label': 'Girl', 'color': 0xFF8B5CF6},
    {'emoji': '👴', 'label': 'Elder Man', 'color': 0xFFD97706},
    {'emoji': '👵', 'label': 'Elder Woman', 'color': 0xFFE11D48},
    {'emoji': '👤', 'label': 'Neutral', 'color': 0xFF10B981},
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
          backgroundColor: AppColors.success,
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
        transitionDuration: const Duration(milliseconds: 350),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEditMode
          ? AppBar(
              title: Text(
                s.editMyProfile,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle ambient background orbs (reduced by 50% per Spec 33)
            Positioned(
              top: -20,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
                ),
              ),
            ),

            // Scrollable Content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Step Icon & Title (Onboarding only)
                    if (!widget.isEditMode) ...[
                      Center(
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              _selectedEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                      Text(
                        s.setupProfileTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 4),
                      Text(
                        s.setupProfileSub,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
                      const SizedBox(height: 20),
                    ],

                    // Main Setup Card (Moved higher, standard 16dp radius & 1dp border)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
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
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                                    duration: const Duration(milliseconds: 180),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.14)
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: TextStyle(fontSize: isSelected ? 24 : 20),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1),
                          ),

                          // 2. Name Input Field
                          Text(
                            s.yourName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: s.enterNameHint,
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. Age Input Field (Numeric, calendar/person icon per Spec 34)
                          Text(
                            s.yourAge,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              hintText: s.enterAgeHint,
                              prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: Text(
                                  s.ageYears,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                    const SizedBox(height: 24),

                    // Primary Button: Save Changes / Complete Setup
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveAndProceed(isSkip: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Text(
                                widget.isEditMode ? s.saveChanges : s.completeSetupBtn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    // Secondary Button: Skip for now (Only in onboarding)
                    if (!widget.isEditMode) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => _saveAndProceed(isSkip: true),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        child: Text(
                          s.skipForNow,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
