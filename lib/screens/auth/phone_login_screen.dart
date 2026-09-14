import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

enum AuthMode { signIn, signUp }

// Type alias so any existing caller can reference EmailAuthScreen or PhoneLoginScreen
typedef EmailAuthScreen = PhoneLoginScreen;

class PhoneLoginScreen extends StatefulWidget {
  final bool isModal;
  final AuthMode initialMode;

  const PhoneLoginScreen({
    super.key,
    this.isModal = false,
    this.initialMode = AuthMode.signIn,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> with WidgetsBindingObserver {
  late AuthMode _mode;
  bool _isLoading = false;
  bool _isForgotPasswordView = false;
  bool _isEmailVerificationView = false;
  String? _pendingVerificationEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _resetEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isEmailVerificationView) {
      final email = _pendingVerificationEmail ?? _emailController.text.trim();
      final pwd = _passwordController.text.trim();
      if (email.isNotEmpty && pwd.isNotEmpty) {
        _autoCheckVerification(email, pwd);
      }
    }
  }

  Future<void> _autoCheckVerification(String email, String password) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();
      final res = await authProvider.signInWithEmail(
        email: email,
        password: password,
        medicineProvider: medProvider,
      );
      if (res.success && mounted) {
        final s = context.read<LanguageProvider>().strings;
        _showToast(s.code == 'bn' ? 'ইমেল ভেরিফিকেশন সফল! স্বাগতম।' : 'Email verified successfully! Welcome.');
        if (widget.isModal || Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (_) {}
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  // ==================== SUPABASE NATIVE AUTH HANDLERS ====================

  Future<void> _handleSignIn(AppStrings s) async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (!_isValidEmail(email)) {
      _showToast(s.errEnterValidEmail, isError: true);
      return;
    }
    if (password.isEmpty) {
      _showToast(s.errEnterPassword, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();

      final result = await authProvider.signInWithEmail(
        email: email,
        password: password,
        medicineProvider: medProvider,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!result.success) {
        if (result.isEmailConfirmationRequired) {
          setState(() {
            _pendingVerificationEmail = email;
            _isEmailVerificationView = true;
          });
          _showToast(s.authEmailNotConfirmed, isError: true);
          return;
        }

        _showToast(result.errorMessage ?? s.msgInvalidCredentials, isError: true);
        return;
      }

      _showToast(s.msgSignInSuccess);

      if (widget.isModal || Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleSignUp(AppStrings s) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showToast(s.errEnterFullName, isError: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _showToast(s.errEnterValidEmail, isError: true);
      return;
    }
    if (password.length < 6) {
      _showToast(s.errPasswordLength, isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showToast(s.errPasswordsDoNotMatch, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();

      final result = await authProvider.signUpWithEmail(
        email: email,
        name: name,
        password: password,
        medicineProvider: medProvider,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!result.success) {
        _showToast(result.errorMessage ?? 'Account creation failed.', isError: true);
        return;
      }

      if (result.isEmailConfirmationRequired) {
        setState(() {
          _pendingVerificationEmail = email;
          _isEmailVerificationView = true;
        });
        return;
      }

      // Email confirmation not required or instant session
      _showToast(s.msgSignUpSuccess);
      if (widget.isModal || Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleSendPasswordReset(AppStrings s) async {
    final email = _resetEmailController.text.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      _showToast(s.errEnterValidEmail, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final res = await authProvider.sendPasswordResetEmail(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.success) {
        _showToast(s.authPasswordResetSent);
        setState(() {
          _isForgotPasswordView = false;
          _mode = AuthMode.signIn;
          _emailController.text = email;
        });
      } else {
        _showToast(res.errorMessage ?? 'Could not send reset link.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleResendVerification(AppStrings s, String email) async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final res = await authProvider.resendVerificationEmail(email);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.success) {
        _showToast(s.authVerificationResent);
      } else {
        _showToast(res.errorMessage ?? 'Could not resend email. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleCheckVerificationAndSignIn(AppStrings s, String email) async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _isEmailVerificationView = false;
        _mode = AuthMode.signIn;
        _emailController.text = email;
      });
      _showToast(s.code == 'bn' ? 'পাসওয়ার্ড দিয়ে সাইন ইন করুন' : 'Enter your password to sign in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();
      final result = await authProvider.signInWithEmail(
        email: email,
        password: password,
        medicineProvider: medProvider,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        _showToast(s.code == 'bn' ? 'ইমেল ভেরিফিকেশন সফল! স্বাগতম।' : s.msgSignInSuccess);
        if (widget.isModal || Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else if (result.isEmailConfirmationRequired) {
        _showToast(
          s.code == 'bn'
              ? 'ইমেল এখনও ভেরিফাই হয়নি। আপনার ইনবক্সের লিঙ্কে ক্লিক করুন।'
              : 'Email not verified yet. Please click the link in your email.',
          isError: true,
        );
      } else {
        _showToast(result.errorMessage ?? 'Sign in failed.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleVerifyOtp(AppStrings s, String email) async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showToast(s.code == 'bn' ? 'দয়া করে ৬-সংখ্যার কোডটি লিখুন' : 'Please enter 6-digit code', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();
      final result = await authProvider.verifySignupOtp(
        email: email,
        token: otp,
        medicineProvider: medProvider,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.success) {
        _showToast(s.code == 'bn' ? 'ইমেল সফলভাবে ভেরিফাই হয়েছে!' : 'Email verified successfully!');
        if (widget.isModal || Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else {
        _showToast(result.errorMessage ?? 'Invalid verification code.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('Error: $e', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final s = AppStrings.of(lang.languageCode);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.lightTextPrimary),
          onPressed: () {
            if (_isEmailVerificationView) {
              setState(() => _isEmailVerificationView = false);
            } else if (_isForgotPasswordView) {
              setState(() => _isForgotPasswordView = false);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Flag-free Language Dropdown
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: lang.languageCode,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  DropdownMenuItem(value: 'bn', child: Text('বাংলা', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  DropdownMenuItem(value: 'hi', child: Text('हिन्दी', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                ],
                onChanged: (val) {
                  if (val != null) lang.setLanguage(val);
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _isEmailVerificationView
              ? _buildEmailVerificationView(isDark, s)
              : (_isForgotPasswordView
                  ? _buildForgotPasswordView(isDark, s)
                  : (_mode == AuthMode.signIn ? _buildSignInView(isDark, s) : _buildSignUpView(isDark, s))),
        ),
      ),
    );
  }

  // ==================== SIGN IN VIEW ====================
  Widget _buildSignInView(bool isDark, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Switcher Tabs [Sign In] | [Sign Up]
        _buildModeTabBar(isDark, s),
        const SizedBox(height: 28),

        // Header
        Text(
          s.authSignInTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.authSignInSub,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Email Address Input
        _buildInputField(
          controller: _emailController,
          hint: s.authEmailHint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Password Input
        _buildInputField(
          controller: _passwordController,
          hint: s.authPasswordHint,
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 10),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                _resetEmailController.text = _emailController.text.trim();
                _isForgotPasswordView = true;
              });
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            child: Text(
              s.authForgotPasswordLink,
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Primary Sign In Button
        _buildPrimaryButton(
          title: s.authSignInBtn,
          onPressed: _isLoading ? null : () => _handleSignIn(s),
        ),
        const SizedBox(height: 32),

        // Bottom Switch Link
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.signUp),
            child: RichText(
              text: TextSpan(
                text: s.authDontHaveAccount,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                children: [
                  TextSpan(
                    text: s.authSignUpTab,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  // ==================== SIGN UP VIEW (NATIVE SUPABASE AUTH) ====================
  Widget _buildSignUpView(bool isDark, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Switcher Tabs [Sign In] | [Sign Up]
        _buildModeTabBar(isDark, s),
        const SizedBox(height: 28),

        // Header
        Text(
          s.authSignUpTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.authSignUpSub,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Full Name Input
        _buildInputField(
          controller: _nameController,
          hint: s.authFullNameHint,
          icon: Icons.person_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Email Address Input
        _buildInputField(
          controller: _emailController,
          hint: s.authEmailHint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 14),

        // Password Input
        _buildInputField(
          controller: _passwordController,
          hint: s.authPasswordHint,
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password Input
        _buildInputField(
          controller: _confirmPasswordController,
          hint: s.authConfirmPasswordHint,
          icon: Icons.lock_reset_rounded,
          isDark: isDark,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        const SizedBox(height: 24),

        // Primary Create Account Button
        _buildPrimaryButton(
          title: s.authSignUpBtn,
          onPressed: _isLoading ? null : () => _handleSignUp(s),
        ),
        const SizedBox(height: 28),

        // Bottom Switch Link
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.signIn),
            child: RichText(
              text: TextSpan(
                text: s.authAlreadyHaveAccount,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                children: [
                  TextSpan(
                    text: s.authSignInTab,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  // ==================== EMAIL VERIFICATION VIEW ====================
  Widget _buildEmailVerificationView(bool isDark, AppStrings s) {
    final email = _pendingVerificationEmail ?? _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 44),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.authVerificationSentTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                s.authVerificationSentDesc(email),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary: "I've Verified, Sign In"
        _buildPrimaryButton(
          title: s.authAlreadyVerifiedBtn,
          onPressed: _isLoading ? null : () => _handleCheckVerificationAndSignIn(s, email),
        ),
        const SizedBox(height: 20),

        // Alternative: Enter 6-digit OTP code if received in email
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                s.authOrEnterCode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 4),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      letterSpacing: 3,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _handleVerifyOtp(s, email),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(s.authVerifyCodeBtn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Secondary: "Resend Verification Email"
        OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _handleResendVerification(s, email),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(s.authResendVerification),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        // Back / Change Email
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isEmailVerificationView = false;
                _mode = AuthMode.signUp;
              });
            },
            child: Text(
              s.code == 'bn'
                  ? 'ইমেল পরিবর্তন করুন বা পিছনে যান'
                  : (s.code == 'hi' ? 'ईमेल बदलें या वापस जाएं' : 'Change Email or Go Back'),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  // ==================== FORGOT PASSWORD (NATIVE SUPABASE RESET) ====================
  Widget _buildForgotPasswordView(bool isDark, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 38),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.authForgotPasswordLink,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.authResetPasswordEmailDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _resetEmailController,
          hint: s.authEmailHint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          title: s.authSendResetLink,
          onPressed: _isLoading ? null : () => _handleSendPasswordReset(s),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isForgotPasswordView = false),
            child: Text(
              s.code == 'bn' ? 'সাইন ইন-এ ফিরে যান' : (s.code == 'hi' ? 'लॉगिन पर वापस जाएं' : 'Back to Sign In'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  // ==================== COMMON WIDGETS ====================

  Widget _buildModeTabBar(bool isDark, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = AuthMode.signIn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.signIn
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.signIn
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    s.authSignInTab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _mode == AuthMode.signIn
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = AuthMode.signUp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.signUp
                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.signUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    s.authSignUpTab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _mode == AuthMode.signUp
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String title,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
