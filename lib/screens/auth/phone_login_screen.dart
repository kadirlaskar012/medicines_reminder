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

enum AuthStep { phone, enterPin, createPin, forgotPin }

class PhoneLoginScreen extends StatefulWidget {
  final bool isModal;
  const PhoneLoginScreen({super.key, this.isModal = false});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  AuthStep _step = AuthStep.phone;
  bool _isLoading = false;

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

  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে বৈধ ১০ ডিজিটের মোবাইল নম্বর লিখুন'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final status = await SupabaseService.instance.checkUserStatus(_fullPhoneNumber);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _existingUserName = status.name;
        _existingSecurityQuestion = status.securityQuestion;

        if (status.exists && status.hasPin) {
          _step = AuthStep.enterPin;
        } else {
          _step = AuthStep.createPin;
          if (status.name != null && status.name!.isNotEmpty) {
            _nameController.text = status.name!;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleLoginWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে ৪-সংখ্যার গোপন পিন লিখুন'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ok = await SupabaseService.instance.verifyPin(
      phoneNumber: _fullPhoneNumber,
      enteredPin: pin,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ভুল পিন দেওয়া হয়েছে! সঠিক পিন লিখুন অথবা Forgot PIN চাপুন।'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (!mounted) return;

    // PIN is correct! Now restore cloud data and merge
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restoredCount > 0
              ? '🎉 স্বাগতম! আপনার $restoredCount টি ওষুধ ক্লাউড থেকে সফলভাবে রিস্টোর হয়েছে।'
              : '🎉 সফলভাবে লগইন হয়েছে! ক্লাউড সিঙ্ক সক্রিয়।'),
          backgroundColor: AppColors.success,
        ),
      );

      if (widget.isModal) {
        Navigator.pop(context, true);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleRegisterWithPin() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final answer = _securityAnswerController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে আপনার নাম লিখুন'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('৪-সংখ্যার একটি গোপন পিন নির্ধারণ করুন'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('দুইবারের পিন মিলছে না! অনুগ্রহ করে একই পিন লিখুন।'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পিন ভুলে গেলে রিকভারির জন্য সিকিউরিটি প্রশ্নের উত্তর দিন'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ok = await SupabaseService.instance.registerUserWithPin(
      phoneNumber: _fullPhoneNumber,
      name: name,
      pin: pin,
      securityQuestion: _selectedSecurityQuestion,
      securityAnswer: answer,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পিন সংরক্ষণ ব্যর্থ হয়েছে। অনুগ্রহ করে পুনরায় চেষ্টা করুন।'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (!mounted) return;

    // Sync any existing local medicines to cloud
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ আপনার গোপন পিন সেট হয়েছে ও ক্লাউড ব্যাকআপ সক্রিয় হয়েছে!'),
          backgroundColor: AppColors.success,
        ),
      );

      if (widget.isModal) {
        Navigator.pop(context, true);
      } else if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleAnswerSecurityQuestion() async {
    final answer = _securityAnswerController.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে উত্তরটি লিখুন'), backgroundColor: AppColors.error),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ উত্তর সঠিক নয়! অ্যাডমিনের সাহায্য নিন।'), backgroundColor: AppColors.error),
        );
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
              Text('নতুন পিন নির্ধারণ করুন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('আপনার উত্তর সঠিক হয়েছে! এবার নতুন একটি ৪-সংখ্যার সিকিউরিটি পিন দিন:', style: TextStyle(fontSize: 13)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('৪ সংখ্যার পিন লিখুন'), backgroundColor: AppColors.error),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ পিন সফলভাবে পরিবর্তন ও লগইন সম্পন্ন হয়েছে!'), backgroundColor: AppColors.success),
                  );
                  if (widget.isModal) {
                    Navigator.pop(context, true);
                  } else if (Navigator.canPop(context)) {
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
              const Text('তাৎক্ষণিক সাহায্যের জন্য সরাসরি যোগাযোগ করুন:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          _step == AuthStep.phone
              ? s.phoneLoginTitle
              : (_step == AuthStep.enterPin
                  ? 'গোপন পিন যাচাইকরণ'
                  : (_step == AuthStep.createPin ? 'সিকিউরিটি পিন সেট করুন' : 'পিন রিকভারি')),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        leading: _step != AuthStep.phone
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    if (_step == AuthStep.forgotPin) {
                      _step = AuthStep.enterPin;
                    } else {
                      _step = AuthStep.phone;
                    }
                  });
                },
              )
            : (widget.isModal
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                : (Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == AuthStep.phone) _buildPhoneStep(isDark),
              if (_step == AuthStep.enterPin) _buildEnterPinStep(isDark),
              if (_step == AuthStep.createPin) _buildCreatePinStep(isDark),
              if (_step == AuthStep.forgotPin) _buildForgotPinStep(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== STEP 1: PHONE INPUT ====================
  Widget _buildPhoneStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'আপনার মোবাইল নম্বর লিখুন',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'আপনার ব্যক্তিগত পিন দ্বারা প্রেসক্রিপশন ও ওষুধের তথ্য ১০০% সুরক্ষিত থাকবে।',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
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
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '১০ ডিজিটের নম্বর',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePhoneSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('এগিয়ে যান', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ==================== STEP 2A: ENTER SECRET PIN ====================
  Widget _buildEnterPinStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 36, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _existingUserName != null ? 'স্বাগতম, $_existingUserName!' : 'স্বাগতম!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ফোন: $_fullPhoneNumber', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _step = AuthStep.phone),
              child: const Text('বদলান', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'আপনার ৪-সংখ্যার গোপন সিকিউরিটি পিন দিন:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: _obscurePin,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 16),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: IconButton(
              icon: Icon(_obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _securityAnswerController.clear();
                _step = AuthStep.forgotPin;
              });
            },
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('পিন ভুলে গেছেন? (Forgot PIN?)', style: TextStyle(fontSize: 13)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLoginWithPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('লগইন ও ডেটা রিস্টোর করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ==================== STEP 2B: CREATE SECRET PIN ====================
  Widget _buildCreatePinStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'নতুন সিকিউরিটি পিন সেট করুন',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'নম্বর: $_fullPhoneNumber (ভবিষ্যতে ডেটা রিস্টোর করতে এই পিনটি প্রয়োজন হবে)',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        const Text('আপনার নাম *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'যেমন: কাদির লস্কর',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('৪-সংখ্যার পিন *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'PIN',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('পিন নিশ্চিত করুন *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Confirm',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('পিন রিকভারি সিকিউরিটি প্রশ্ন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedSecurityQuestion,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSecurityQuestion = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _securityAnswerController,
                decoration: InputDecoration(
                  hintText: 'প্রশ্নের উত্তরটি লিখুন (যেমন: ঢাকা, কলকাতা)',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegisterWithPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('পিন সংরক্ষণ ও অ্যাকাউন্ট সুরক্ষিত করুন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  // ==================== STEP 3: FORGOT PIN & SUPPORT ====================
  Widget _buildForgotPinStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
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
        const SizedBox(height: 6),
        Text(
          'নম্বর: $_fullPhoneNumber',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Choice 1: Security Question
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

        // Choice 2: Admin Support
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
    ).animate().fadeIn(duration: 300.ms);
  }
}
