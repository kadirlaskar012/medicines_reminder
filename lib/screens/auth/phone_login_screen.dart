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
  bool _isCodeSent = false;

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
      setState(() => _isCodeSent = true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      final s = context.read<LanguageProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.otpInvalidValidation), backgroundColor: AppColors.error),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final medProvider = context.read<MedicineProvider>();
    final success = await authProvider.verifyOtp(otp, medProvider);

    if (success && mounted) {
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isCodeSent ? s.verifyOtpTitle : s.phoneLoginTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: widget.isModal
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : (_isCodeSent
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() => _isCodeSent = false),
                  )
                : null),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Top Icon / Header Illustration
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _isCodeSent ? Icons.mark_email_read_rounded : Icons.phone_iphone_rounded,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().scale(duration: 400.ms),
              ),

              const SizedBox(height: 24),

              Text(
                _isCodeSent ? s.verifyOtpTitle : s.phoneLoginTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _isCodeSent ? '${s.otpSentTo} $_selectedCountryCode ${_phoneController.text}' : s.phoneLoginSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

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

              // Step 1: Phone Input
              if (!_isCodeSent) ...[
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

                // Send OTP Button
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
                        : Text(
                            s.sendOtpBtn,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],

              // Step 2: OTP Verification
              if (_isCodeSent) ...[
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
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        hintStyle: TextStyle(
                          letterSpacing: 12,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        if (val.length == 6) {
                          _handleVerifyOtp();
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!auth.canResendOtp)
                      Text(
                        '${s.resendOtpIn} 00:${auth.countdownSeconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: auth.isLoading ? null : _handleSendOtp,
                        child: Text(
                          s.resendOtpBtn,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

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
                        : Text(
                            s.verifyAndLoginBtn,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // "Continue as Guest" / Skip Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    s.continueAsGuest,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
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
