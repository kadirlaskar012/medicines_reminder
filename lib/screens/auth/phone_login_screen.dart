import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/medicine_provider.dart';

enum AuthMode { signIn, signUp }

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
  bool _isForgotPinView = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();

  bool _obscurePin = true;
  String _selectedCountryCode = '+91';

  final List<String> _securityQuestions = [
    'আপনার জন্মস্থান বা প্রিয় শহর কোনটি?',
    'আপনার প্রথম স্কুলের নাম কী?',
    'আপনার প্রিয় খাবার কোনটি?',
    'আপনার শৈশবের প্রিয় বন্ধুর নাম কী?',
  ];
  late String _selectedSecurityQuestion;

  String? _existingSecurityQuestion;
  String? _existingUserName;

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India (ভারত)', 'flag': '🇮🇳'},
    {'code': '+880', 'name': 'Bangladesh (বাংলাদেশ)', 'flag': '🇧🇩'},
    {'code': '+1', 'name': 'USA / Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': '+966', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedSecurityQuestion = _securityQuestions.first;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _nameController.dispose();
    _securityAnswerController.dispose();
    _newPinController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text.trim()}';

  // ==================== FLOW HANDLERS ====================

  Future<void> _handleSignIn() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.length < 10) {
      _showToast('অনুগ্রহ করে বৈধ ১০ ডিজিটের মোবাইল নম্বর লিখুন', isError: true);
      return;
    }
    if (pin.length != 4) {
      _showToast('অনুগ্রহ করে ৪-সংখ্যার গোপন পিন লিখুন', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await SupabaseService.instance.verifyPin(
        phoneNumber: _fullPhoneNumber,
        enteredPin: pin,
      );

      if (!ok) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showToast('❌ ভুল পিন দেওয়া হয়েছে! সঠিক পিন লিখুন অথবা Forgot PIN চাপুন।', isError: true);
        return;
      }

      if (!mounted) return;

      // Restore user cloud data
      final medProvider = context.read<MedicineProvider>();
      final restoredCount = await medProvider.restoreUserFromCloud(_fullPhoneNumber);

      await CloudSyncService.instance.syncLocalToCloud(
        profiles: medProvider.profiles,
        medicines: medProvider.medicines,
        remindersByMedicine: medProvider.remindersByMedicine,
        records: medProvider.intakeRecords,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.read<AuthProvider>().resetFlow();

        _showToast(restoredCount > 0
            ? '🎉 স্বাগতম! আপনার $restoredCount টি ওষুধ ক্লাউড থেকে সফলভাবে রিস্টোর হয়েছে।'
            : '🎉 সফলভাবে সাইন ইন হয়েছে! ক্লাউড সিঙ্ক সক্রিয়।');

        if (widget.isModal || Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('ত্রুটি: $e', isError: true);
      }
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final answer = _securityAnswerController.text.trim();

    if (name.isEmpty) {
      _showToast('অনুগ্রহ করে আপনার নাম লিখুন', isError: true);
      return;
    }
    if (phone.length < 10) {
      _showToast('অনুগ্রহ করে বৈধ ১০ ডিজিটের মোবাইল নম্বর লিখুন', isError: true);
      return;
    }
    if (pin.length != 4) {
      _showToast('৪-সংখ্যার একটি গোপন পিন নির্ধারণ করুন', isError: true);
      return;
    }
    if (pin != confirmPin) {
      _showToast('দুইবারের পিন মিলছে না! একই পিন লিখুন।', isError: true);
      return;
    }
    if (answer.isEmpty) {
      _showToast('পিন রিকভারির জন্য সিকিউরিটি প্রশ্নের উত্তর দিন', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await SupabaseService.instance.registerUserWithPin(
        phoneNumber: _fullPhoneNumber,
        name: name,
        pin: pin,
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: answer,
      );

      if (!ok) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showToast('অ্যাকাউন্ট তৈরি ব্যর্থ হয়েছে। পুনরায় চেষ্টা করুন।', isError: true);
        return;
      }

      if (!mounted) return;

      // Sync existing local medicines to cloud
      final medProvider = context.read<MedicineProvider>();
      await CloudSyncService.instance.syncLocalToCloud(
        profiles: medProvider.profiles,
        medicines: medProvider.medicines,
        remindersByMedicine: medProvider.remindersByMedicine,
        records: medProvider.intakeRecords,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        context.read<AuthProvider>().resetFlow();

        _showToast('🛡️ অ্যাকাউন্ট তৈরি সম্পন্ন হয়েছে ও ক্লাউড ব্যাকআপ সক্রিয় হয়েছে!');

        if (widget.isModal || Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('ত্রুটি: $e', isError: true);
      }
    }
  }

  Future<void> _handleForgotPasswordInit() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showToast('আগে আপনার ১০ ডিজিটের মোবাইল নম্বর লিখুন', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final status = await SupabaseService.instance.checkUserStatus(_fullPhoneNumber);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _existingUserName = status.name;
      _existingSecurityQuestion = status.securityQuestion;
      _isForgotPinView = true;
    });
  }

  Future<void> _handleAnswerSecurityQuestion() async {
    final answer = _securityAnswerController.text.trim();
    if (answer.isEmpty) {
      _showToast('অনুগ্রহ করে উত্তরটি লিখুন', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final ok = await SupabaseService.instance.verifySecurityAnswer(
      phoneNumber: _fullPhoneNumber,
      enteredAnswer: answer,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showToast('❌ উত্তর সঠিক নয়! অ্যাডমিনের সাহায্য নিন।', isError: true);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showEnterNewPinDialog();
    }
  }

  void _showEnterNewPinDialog() {
    _newPinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('নতুন পিন দিন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('উত্তর সঠিক হয়েছে! নতুন ৪-সংখ্যার সিকিউরিটি পিন দিন:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _newPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'নতুন ৪-সংখ্যার পিন',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.pin_rounded),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newPin = _newPinController.text.trim();
                if (newPin.length != 4) {
                  _showToast('৪ সংখ্যার পিন লিখুন', isError: true);
                  return;
                }
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                await SupabaseService.instance.resetPin(phoneNumber: _fullPhoneNumber, newPin: newPin);
                await SupabaseService.instance.verifyPin(phoneNumber: _fullPhoneNumber, enteredPin: newPin);

                if (!mounted) return;
                final medProvider = context.read<MedicineProvider>();
                await medProvider.restoreUserFromCloud(_fullPhoneNumber);

                if (mounted) {
                  setState(() => _isLoading = false);
                  _showToast('✅ পিন সফলভাবে পরিবর্তন ও সাইন ইন সম্পন্ন হয়েছে!');
                  if (widget.isModal || Navigator.canPop(context)) {
                    Navigator.pop(context, true);
                  }
                }
              },
              child: const Text('সংরক্ষণ ও লগইন'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRequestAdminHelp() async {
    setState(() => _isLoading = true);
    final ok = await SupabaseService.instance.submitPinResetRequest(
      phoneNumber: _fullPhoneNumber,
      userName: _existingUserName ?? 'User',
      message: 'User requested PIN reset from login screen',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.headset_mic_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('অ্যাডমিন সাপোর্ট', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ok
                    ? '✅ আপনার অনুরোধ অ্যাডমিনের কাছে পাঠানো হয়েছে! অ্যাডমিন প্যানেল থেকে আপনার অ্যাকাউন্ট যাচাই করে পিন রিসেট করে দেওয়া হবে।'
                    : 'অনুরোধ পাঠানো হয়েছে।',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('তাৎক্ষণিক সাহায্যের জন্য যোগাযোগ করুন:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                      label: const Text('সরাসরি কল'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                      onPressed: () async {
                        final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent("হ্যালো MediRemind সাপোর্ট, আমার নম্বর $_fullPhoneNumber-এর পিন রিসেট করতে সাহায্য চাই।")}');
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
              child: const Text('ঠিক আছে'),
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_isForgotPinView) {
              setState(() => _isForgotPinView = false);
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _isForgotPinView
              ? _buildForgotPinView(isDark, lang)
              : (_mode == AuthMode.signIn ? _buildSignInView(isDark, lang) : _buildSignUpView(isDark, lang)),
        ),
      ),
    );
  }

  // ==================== SCREEN 06: SIGN IN (WELCOME BACK) ====================
  Widget _buildSignInView(bool isDark, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Switcher Tabs [Sign In] | [Sign Up]
        _buildModeTabBar(isDark, lang),
        const SizedBox(height: 28),

        // Header
        Text(
          lang.languageCode == 'bn' ? 'স্বাগতম ফিরে আসার জন্য' : (lang.languageCode == 'hi' ? 'वापसी पर स्वागत है' : 'Welcome Back'),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang.languageCode == 'bn'
              ? 'আপনার ওষুধের রিমাইন্ডার ও স্বাস্থ্য ডেটা এক্সেস করতে সাইন ইন করুন'
              : (lang.languageCode == 'hi'
                  ? 'अपनी दवाइयों के रिमाइंडर और स्वास्थ्य डेटा के लिए साइन इन करें'
                  : 'Sign in to access your reminders & health data'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Phone Input
        _buildPhoneInputField(isDark),
        const SizedBox(height: 16),

        // 4-Digit PIN Input
        _buildPinInputField(
          controller: _pinController,
          hint: '৪-সংখ্যার গোপন সিকিউরিটি পিন',
          isDark: isDark,
          showVisibilityToggle: true,
        ),
        const SizedBox(height: 10),

        // Forgot PIN Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPasswordInit,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            child: Text(
              lang.languageCode == 'bn' ? 'পিন ভুলে গেছেন? (Forgot PIN?)' : (lang.languageCode == 'hi' ? 'पिन भूल गए?' : 'Forgot PIN?'),
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Primary Sign In Button
        _buildPrimaryButton(
          title: lang.languageCode == 'bn' ? 'সাইন ইন করুন' : (lang.languageCode == 'hi' ? 'साइन इन करें' : 'Sign In'),
          onPressed: _isLoading ? null : _handleSignIn,
        ),
        const SizedBox(height: 24),

        // Social Buttons
        _buildSocialLoginSection(isDark, lang),
        const SizedBox(height: 24),

        // Bottom Switch Link
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.signUp),
            child: RichText(
              text: TextSpan(
                text: lang.languageCode == 'bn' ? 'কোনো অ্যাকাউন্ট নেই? ' : (lang.languageCode == 'hi' ? 'कोई खाता नहीं है? ' : "Don't have an account? "),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                children: [
                  TextSpan(
                    text: lang.languageCode == 'bn' ? 'অ্যাকাউন্ট তৈরি করুন' : (lang.languageCode == 'hi' ? 'खाता बनाएं' : 'Sign Up'),
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

  // ==================== SCREEN 05: CREATE ACCOUNT (SIGN UP) ====================
  Widget _buildSignUpView(bool isDark, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Switcher Tabs [Sign In] | [Sign Up]
        _buildModeTabBar(isDark, lang),
        const SizedBox(height: 28),

        // Header
        Text(
          lang.languageCode == 'bn' ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : (lang.languageCode == 'hi' ? 'नया खाता बनाएं' : 'Create Account'),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang.languageCode == 'bn'
              ? 'প্রেসক্রিপশন ও ওষুধের রিমাইন্ডার ট্র্যাক করতে সাইন আপ করুন'
              : (lang.languageCode == 'hi'
                  ? 'अपनी दवाओं को ट्रैक करना शुरू करने के लिए साइन अप करें'
                  : 'Sign up to start tracking your medicines'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Full Name Input
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'আপনার পুরো নাম (যেমন: কাদির লস্কর)',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Phone Input
        _buildPhoneInputField(isDark),
        const SizedBox(height: 14),

        // 4-Digit PIN Input & Confirm PIN
        Row(
          children: [
            Expanded(
              child: _buildPinInputField(
                controller: _pinController,
                hint: '৪-সংখ্যার পিন',
                isDark: isDark,
                showVisibilityToggle: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPinInputField(
                controller: _confirmPinController,
                hint: 'পিন নিশ্চিত করুন',
                isDark: isDark,
                showVisibilityToggle: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Security Question & Answer Card
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
              const Row(
                children: [
                  Icon(Icons.security_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('পিন রিকভারি সিকিউরিটি প্রশ্ন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedSecurityQuestion,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSecurityQuestion = val);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _securityAnswerController,
                decoration: InputDecoration(
                  hintText: 'উত্তর (যেমন: কলকাতা, ঢাকা)',
                  hintStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Primary Create Account Button
        _buildPrimaryButton(
          title: lang.languageCode == 'bn' ? 'অ্যাকাউন্ট তৈরি করুন' : (lang.languageCode == 'hi' ? 'खाता बनाएं' : 'Create Account'),
          onPressed: _isLoading ? null : _handleSignUp,
        ),
        const SizedBox(height: 20),

        // Social Buttons
        _buildSocialLoginSection(isDark, lang),
        const SizedBox(height: 20),

        // Bottom Switch Link
        Center(
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.signIn),
            child: RichText(
              text: TextSpan(
                text: lang.languageCode == 'bn' ? 'ইতিমধ্যে অ্যাকাউন্ট আছে? ' : (lang.languageCode == 'hi' ? 'पहले से खाता है? ' : 'Already have an account? '),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                children: [
                  TextSpan(
                    text: lang.languageCode == 'bn' ? 'সাইন ইন করুন' : (lang.languageCode == 'hi' ? 'साइन इन करें' : 'Sign In'),
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

  Widget _buildModeTabBar(bool isDark, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _mode = AuthMode.signIn),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.signIn ? (isDark ? const Color(0xFF0B132B) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.signIn
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  lang.languageCode == 'bn' ? 'সাইন ইন' : (lang.languageCode == 'hi' ? 'साइन इन' : 'Sign In'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: _mode == AuthMode.signIn ? FontWeight.w800 : FontWeight.w600,
                    color: _mode == AuthMode.signIn ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
                    fontSize: 14,
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == AuthMode.signUp ? (isDark ? const Color(0xFF0B132B) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _mode == AuthMode.signUp
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  lang.languageCode == 'bn' ? 'অ্যাকাউন্ট খুলুন' : (lang.languageCode == 'hi' ? 'साइन अप' : 'Sign Up'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: _mode == AuthMode.signUp ? FontWeight.w800 : FontWeight.w600,
                    color: _mode == AuthMode.signUp ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: _countryCodes.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['code'],
                    child: Text('${item['flag']} ${item['code']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCountryCode = val);
                },
              ),
            ),
          ),
          const SizedBox(
            height: 24,
            child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '১০ ডিজিটের নম্বর',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInputField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required bool showVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: showVisibilityToggle ? _obscurePin : true,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 4),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, letterSpacing: 0, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
          suffixIcon: showVisibilityToggle
              ? IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String title, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildSocialLoginSection(bool isDark, LanguageProvider lang) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                lang.languageCode == 'bn' ? 'অথবা মাধ্যম ব্যবহার করুন' : (lang.languageCode == 'hi' ? 'या जारी रखें' : 'Or continue with'),
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showToast('Google Sign-In শীঘ্রই আসছে (Next update)');
                },
                icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Color(0xFFEA4335)),
                label: const Text('Google', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showToast('Apple ID Sign-In শীঘ্রই আসছে (Next update)');
                },
                icon: Icon(Icons.apple_rounded, size: 22, color: isDark ? Colors.white : Colors.black87),
                label: const Text('Apple', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== FORGOT PIN RECOVERY VIEW ====================
  Widget _buildForgotPinView(bool isDark, LanguageProvider lang) {
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
        const Text(
          'পিন রিকভারি ও অ্যাডমিন সাপোর্ট',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'নম্বর: $_fullPhoneNumber',
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
                const Row(
                  children: [
                    Icon(Icons.quiz_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('উপায় ১: সিকিউরিটি প্রশ্ন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _existingSecurityQuestion ?? 'আপনার জন্মস্থান বা প্রিয় শহর কোনটি?',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _securityAnswerController,
                  decoration: InputDecoration(
                    hintText: 'সঠিক উত্তরটি লিখুন',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAnswerSecurityQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('উত্তর যাচাই করে নতুন পিন দিন'),
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
                const Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('উপায় ২: অ্যাডমিনের সাহায্য নিন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'আপনি যদি প্রশ্ন ও উত্তর মনে করতে না পারেন, তবে সরাসরি অ্যাডমিনকে অনুরোধ পাঠান। অ্যাডমিন আপনার পিন রিসেট করে দেবে।',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleRequestAdminHelp,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('অ্যাডমিনকে রিকোয়েস্ট পাঠান'),
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
