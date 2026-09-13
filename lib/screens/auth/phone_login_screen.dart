import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  final bool isModal;
  const PhoneLoginScreen({super.key, this.isModal = false});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedCountryCode = '+91';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India (ভারত)', 'flag': '🇮🇳'},
    {'code': '+880', 'name': 'Bangladesh (বাংলাদেশ)', 'flag': '🇧🇩'},
    {'code': '+1', 'name': 'USA / Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+966', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      final s = context.read<LanguageProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.phoneInvalidValidation), backgroundColor: AppColors.error),
      );
      return;
    }

    final fullNumber = '$_selectedCountryCode$phone';
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(fullNumber);

    if (success && mounted) {
      // Auto-fill the code for user convenience or let them type it
      final code = authProvider.generatedVerificationCode;
      if (code != null) {
        _otpController.text = code;
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে ৪-সংখ্যার সঠিক কোডটি লিখুন'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final medProvider = context.read<MedicineProvider>();
    final success = await authProvider.verifyOtp(otp, medProvider);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সফলভাবে সাইন-ইন সম্পন্ন হয়েছে! ক্লাউড ব্যাকআপ সক্রিয়।'),
          backgroundColor: AppColors.success,
        ),
      );
      if (widget.isModal) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          auth.isCodeSent ? 'কোড যাচাইকরণ' : s.phoneLoginTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Header Avatar / Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 40),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),

              Text(
                auth.isCodeSent ? 'ভেরিফিকেশন সম্পন্ন করুন' : 'মোবাইল নম্বর দিয়ে ক্লাউড ব্যাকআপ',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                auth.isCodeSent
                    ? 'নিচে দেখানো কোডটি প্রবেশ করিয়ে সাইনআপ সম্পন্ন করুন'
                    : 'আপনার ওষুধের তথ্য ও অ্যালার্ম নিরাপদে ক্লাউডে সংরক্ষণ করতে মোবাইল নম্বর লিখুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Error banner if any
              if (auth.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Step 1: Enter Phone
              if (!auth.isCodeSent) ...[
                Row(
                  children: [
                    // Country Code Dropdown Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountryCode,
                          items: _countryCodes.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['code'],
                              child: Row(
                                children: [
                                  Text(item['flag']!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 6),
                                  Text(item['code']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCountryCode = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Phone Number Field
                    Expanded(
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1),
                            decoration: InputDecoration(
                              hintText: s.enterPhoneHint,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Request Code Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'এগিয়ে যান (Get Code)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],

              // Step 2: Auto-generated On-Screen Code Display & Verification
              if (auth.isCodeSent) ...[
                // On-Screen Security Badge displaying the dynamic verification code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'আপনার তাৎক্ষণিক নিরাপত্তা কোড',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Code Display Card (Clickable to auto-copy / auto-fill)
                      GestureDetector(
                        onTap: () {
                          if (auth.generatedVerificationCode != null) {
                            _otpController.text = auth.generatedVerificationCode!;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            auth.generatedVerificationCode ?? '----',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'এসএমএস বিলম্ব এড়াতে কোডটি স্ক্রিনেই দেওয়া হয়েছে।\nকোডটি বক্সে লিখুন বা উপরে ট্যাপ করুন।',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // OTP Input Field
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 16,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••',
                        hintStyle: TextStyle(
                          letterSpacing: 16,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        if (val.length == 4) {
                          _handleVerifyOtp();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Verify Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleVerifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'ভেরিফাই করুন ও লগইন (Verify)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: () => auth.resetFlow(),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text(
                      'নম্বর পরিবর্তন করুন',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // "Continue Offline / Skip" Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'লগইন ছাড়া অফলাইনে ব্যবহার করুন (Skip)',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
