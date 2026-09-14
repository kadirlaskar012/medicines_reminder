import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/supabase_service.dart';
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

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  late AuthMode _mode;
  bool _isLoading = false;
  bool _isForgotPasswordView = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;

  int _selectedSecurityQuestionIndex = 0;
  String? _existingSecurityQuestion;
  String? _existingUserName;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _securityAnswerController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  // ==================== FLOW HANDLERS ====================

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

      final ok = await authProvider.signInWithEmail(
        email: email,
        password: password,
        medicineProvider: medProvider,
      );

      if (!ok) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showToast(s.msgInvalidCredentials, isError: true);
        return;
      }

      if (!mounted) return;

      setState(() => _isLoading = false);
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
    final answer = _securityAnswerController.text.trim();

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
    if (answer.isEmpty) {
      _showToast(s.errEnterSecurityAnswer, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final medProvider = context.read<MedicineProvider>();

      final questions = s.authSecurityQuestions;
      final selectedQuestion = (_selectedSecurityQuestionIndex >= 0 && _selectedSecurityQuestionIndex < questions.length)
          ? questions[_selectedSecurityQuestionIndex]
          : questions.first;

      final ok = await authProvider.signUpWithEmail(
        email: email,
        name: name,
        password: password,
        securityQuestion: selectedQuestion,
        securityAnswer: answer,
        medicineProvider: medProvider,
      );

      if (!ok) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showToast(s.code == 'bn'
            ? 'অ্যাকাউন্ট তৈরি ব্যর্থ হয়েছে। এই ইমেলে ইতিমধ্যে অ্যাকাউন্ট থাকতে পারে।'
            : (s.code == 'hi' ? 'खाता निर्माण विफल रहा। शायद यह ईमेल पहले से मौजूद है।' : 'Account creation failed. An account may already exist with this email.'), isError: true);
        return;
      }

      if (!mounted) return;

      setState(() => _isLoading = false);
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

  Future<void> _handleForgotPasswordInit(AppStrings s) async {
    final email = _emailController.text.trim().toLowerCase();
    if (!_isValidEmail(email)) {
      _showToast(s.errEnterValidEmail, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final status = await SupabaseService.instance.checkUserEmailStatus(email);
    if (!mounted) return;

    if (!status.exists) {
      setState(() => _isLoading = false);
      _showToast(s.msgEmailNotFound, isError: true);
      return;
    }

    setState(() {
      _isLoading = false;
      _existingUserName = status.name;
      _existingSecurityQuestion = status.securityQuestion;
      _isForgotPasswordView = true;
    });
  }

  Future<void> _handleAnswerSecurityQuestion(AppStrings s) async {
    final email = _emailController.text.trim().toLowerCase();
    final answer = _securityAnswerController.text.trim();
    if (answer.isEmpty) {
      _showToast(s.errEnterSecurityAnswer, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final ok = await SupabaseService.instance.verifySecurityAnswerByEmail(
      email: email,
      enteredAnswer: answer,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast(s.msgAnswerIncorrect, isError: true);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showEnterNewPasswordDialog(email, s);
    }
  }

  void _showEnterNewPasswordDialog(String email, AppStrings s) {
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    final authProvider = context.read<AuthProvider>();
    final medProvider = context.read<MedicineProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    s.code == 'bn' ? 'নতুন পাসওয়ার্ড দিন' : (s.code == 'hi' ? 'नया पासवर्ड दर्ज करें' : 'Set New Password'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.code == 'bn'
                        ? 'উত্তর সঠিক হয়েছে! নতুন পাসওয়ার্ড দিন (কমপক্ষে ৬ অক্ষর):'
                        : (s.code == 'hi'
                            ? 'उत्तर सही है! नया पासवर्ड दर्ज करें (कम से कम ६ अक्षर):'
                            : 'Security answer verified! Enter your new password (at least 6 characters):'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      hintText: s.authPasswordHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setDlgState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmNewPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      hintText: s.authConfirmPasswordHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(s.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final newPwd = _newPasswordController.text.trim();
                    final confirmNewPwd = _confirmNewPasswordController.text.trim();
                    if (newPwd.length < 6) {
                      _showToast(s.errPasswordLength, isError: true);
                      return;
                    }
                    if (newPwd != confirmNewPwd) {
                      _showToast(s.errPasswordsDoNotMatch, isError: true);
                      return;
                    }
                    Navigator.pop(ctx);

                    setState(() => _isLoading = true);
                    await SupabaseService.instance.resetPasswordByEmail(email: email, newPassword: newPwd);

                    await authProvider.signInWithEmail(
                      email: email,
                      password: newPwd,
                      medicineProvider: medProvider,
                    );

                    if (mounted) {
                      setState(() => _isLoading = false);
                      _showToast(s.msgPasswordResetSuccess);
                      if (widget.isModal || Navigator.canPop(context)) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  child: Text(s.code == 'bn' ? 'সংরক্ষণ ও লগইন' : (s.code == 'hi' ? 'सहेजें व लॉगिन' : 'Save & Sign In')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRequestAdminHelp(AppStrings s) async {
    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isLoading = true);
    final ok = await SupabaseService.instance.submitPasswordResetRequest(
      email: email,
      userName: _existingUserName ?? 'User',
      message: 'User requested password reset from login screen for email $email',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.headset_mic_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(s.code == 'bn' ? 'অ্যাডমিন সাপোর্ট' : (s.code == 'hi' ? 'एडमिन सहायता' : 'Admin Support'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ok
                    ? (s.code == 'bn'
                        ? '✅ আপনার অনুরোধ অ্যাডমিনের কাছে পাঠানো হয়েছে! অ্যাডমিন প্যানেল থেকে আপনার অ্যাকাউন্ট যাচাই করে সহায়তা করা হবে।'
                        : (s.code == 'hi'
                            ? '✅ आपका अनुरोध एडमिन को भेज दिया गया है। एडमिन सत्यापन के बाद आपकी सहायता करेगा।'
                            : '✅ Your request has been sent to the admin. The administrator will verify and assist you.'))
                    : (s.code == 'bn' ? 'অনুরোধ পাঠানো হয়েছে।' : (s.code == 'hi' ? 'अनुरोध भेजा गया।' : 'Request submitted.')),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                s.code == 'bn'
                    ? 'তাৎক্ষণিক সহায়তার জন্য যোগাযোগ করুন:'
                    : (s.code == 'hi' ? 'तत्काल सहायता के लिए संपर्क करें:' : 'Contact for immediate assistance:'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('tel:+919876543210');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: Text(s.code == 'bn' ? 'সরাসরি কল' : (s.code == 'hi' ? 'कॉल करें' : 'Call Support')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://wa.me/?text=${Uri.encodeComponent("Hello MediRemind Support, I need help resetting my password for account $email.")}');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.ok),
            ),
          ],
        );
      },
    );
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
            if (_isForgotPasswordView) {
              setState(() => _isForgotPasswordView = false);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _isForgotPasswordView
              ? _buildForgotPasswordView(isDark, s)
              : (_mode == AuthMode.signIn ? _buildSignInView(isDark, s) : _buildSignUpView(isDark, s)),
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
        const SizedBox(height: 28),

        // Email Input Field
        _buildInputField(
          controller: _emailController,
          hint: s.authEmailHint,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Password Input Field
        _buildInputField(
          controller: _passwordController,
          hint: s.authPasswordSecretHint,
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 10),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _handleForgotPasswordInit(s),
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

  // ==================== SIGN UP VIEW ====================
  Widget _buildSignUpView(bool isDark, AppStrings s) {
    final questions = s.authSecurityQuestions;
    if (_selectedSecurityQuestionIndex >= questions.length) {
      _selectedSecurityQuestionIndex = 0;
    }

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

        // Password & Confirm Password
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
        const SizedBox(height: 16),

        // Security Question & Answer Card (Mandatory for safe password recovery without mobile OTP)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(s.authSecurityQuestionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedSecurityQuestionIndex,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                items: List.generate(
                  questions.length,
                  (idx) => DropdownMenuItem(
                    value: idx,
                    child: Text(questions[idx], style: const TextStyle(fontSize: 12)),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSecurityQuestionIndex = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _securityAnswerController,
                decoration: InputDecoration(
                  hintText: s.authSecurityAnswerHint,
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ],
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

  // ==================== FORGOT PASSWORD RECOVERY VIEW ====================
  Widget _buildForgotPasswordView(bool isDark, AppStrings s) {
    final email = _emailController.text.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lock_reset_rounded, size: 32, color: AppColors.warning),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.code == 'bn'
              ? 'পাসওয়ার্ড রিকভারি ও অ্যাডমিন সাপোর্ট'
              : (s.code == 'hi' ? 'पासवर्ड रिकवरी व एडमिन सहायता' : 'Password Recovery & Support'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Email: $email',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Way 1: Security Question
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.code == 'bn'
                          ? 'উপায় ১: সিকিউরিটি প্রশ্ন'
                          : (s.code == 'hi' ? 'तरीका १: सुरक्षा प्रश्न' : 'Method 1: Security Question'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _existingSecurityQuestion ?? s.authSecurityQuestions.first,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _securityAnswerController,
                  decoration: InputDecoration(
                    hintText: s.authSecurityAnswerHint,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleAnswerSecurityQuestion(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(s.code == 'bn'
                        ? 'উত্তর যাচাই করে নতুন পাসওয়ার্ড দিন'
                        : (s.code == 'hi' ? 'सत्यापित करें और नया पासवर्ड सेट करें' : 'Verify & Set New Password')),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Way 2: Admin Support
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      s.code == 'bn'
                          ? 'উপায় ২: অ্যাডমিনের সাহায্য নিন'
                          : (s.code == 'hi' ? 'तरीका २: एडमिन सहायता लें' : 'Method 2: Contact Admin Support'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.code == 'bn'
                      ? 'আপনি যদি প্রশ্ন ও উত্তর ভুলে যান, তবে সরাসরি অ্যাডমিনকে অনুরোধ পাঠান। অ্যাডমিন আপনার অ্যাকাউন্ট যাচাই করে পাসওয়ার্ড রিসেট করে দেবে।'
                      : (s.code == 'hi'
                          ? 'यदि आप प्रश्न और उत्तर भूल गए हैं, तो सीधे एडमिन को अनुरोध भेजें। एडमिन आपके खाते का सत्यापन करेगा।'
                          : 'If you forgot your security question and answer, request assistance from the administrator.'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _handleRequestAdminHelp(s),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(s.code == 'bn'
                        ? 'অ্যাডমিনকে রিকোয়েস্ট পাঠান'
                        : (s.code == 'hi' ? 'एडमिन को अनुरोध भेजें' : 'Send Request to Admin')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}
