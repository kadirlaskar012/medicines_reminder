import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserSession {
  final String id;
  final String email;
  final String? phoneNumber;
  final String name;
  final bool isVerified;
  final bool isAdmin;

  SupabaseUserSession({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.name,
    this.isVerified = true,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'phoneNumber': phoneNumber,
    'name': name,
    'isVerified': isVerified,
    'isAdmin': isAdmin,
  };
}

class SupabaseAuthResult {
  final bool success;
  final bool isEmailConfirmationRequired;
  final String? errorMessage;
  final User? user;

  SupabaseAuthResult({
    required this.success,
    this.isEmailConfirmationRequired = false,
    this.errorMessage,
    this.user,
  });
}

class UserAuthStatus {
  final bool exists;
  final bool hasPassword;
  final String? email;
  final String? name;
  final String? securityQuestion;
  final bool isAdmin;

  UserAuthStatus({
    required this.exists,
    this.hasPassword = false,
    this.email,
    this.name,
    this.securityQuestion,
    this.isAdmin = false,
  });

  // Backward compatibility getter
  bool get hasPin => hasPassword;
}

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static const String _prefUserEmail = 'supabase_user_email';
  static const String _prefUserPhone = 'supabase_user_phone';
  static const String _prefUserName = 'supabase_user_name';
  static const String _prefUserId = 'supabase_user_id';
  static const String _prefIsLoggedIn = 'supabase_is_logged_in';
  static const String _prefIsAdmin = 'supabase_is_admin';

  // Master Admin Passcode for app-level owner access
  static const String masterAdminPasscode = '2026';

  // Hosted Web & Deep Link redirect for email verification and password reset
  static const String authRedirectUrl = 'https://kadirlaskar012.github.io/medicines_reminder/';

  SupabaseUserSession? _currentUser;

  /// Current session directly mapped from Supabase Inbuilt Auth User
  SupabaseUserSession? get currentUser {
    final authUser = client?.auth.currentUser;
    if (authUser != null) {
      final name = (authUser.userMetadata?['name'] as String?) ?? authUser.email?.split('@').first ?? 'User';
      return SupabaseUserSession(
        id: authUser.id,
        email: authUser.email ?? '',
        phoneNumber: authUser.phone,
        name: name,
        isVerified: authUser.emailConfirmedAt != null,
        isAdmin: false,
      );
    }
    return _currentUser;
  }

  bool get isSignedIn => (client?.auth.currentUser != null) || (_currentUser != null);
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Initialize session from Supabase Inbuilt Auth session or local storage
  Future<void> initSession() async {
    // 1. Check if Supabase client already has an active session from local storage
    final authUser = client?.auth.currentUser;
    if (authUser != null) {
      final name = (authUser.userMetadata?['name'] as String?) ?? authUser.email?.split('@').first ?? 'User';
      _currentUser = SupabaseUserSession(
        id: authUser.id,
        email: authUser.email ?? '',
        phoneNumber: authUser.phone,
        name: name,
        isVerified: authUser.emailConfirmedAt != null,
        isAdmin: false,
      );
      return;
    }

    // 2. Fallback to shared_preferences
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefIsLoggedIn) ?? false;
    if (isLoggedIn) {
      final email = prefs.getString(_prefUserEmail) ?? '';
      final phone = prefs.getString(_prefUserPhone);
      final name = prefs.getString(_prefUserName) ?? 'User';
      final id = prefs.getString(_prefUserId) ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final isAdm = prefs.getBool(_prefIsAdmin) ?? false;

      if (email.isNotEmpty || (phone != null && phone.isNotEmpty)) {
        _currentUser = SupabaseUserSession(
          id: id,
          email: email.isNotEmpty ? email : (phone ?? ''),
          phoneNumber: phone,
          name: name,
          isAdmin: isAdm,
        );
      }
    }
  }

  Future<void> _saveLocalSession(String id, String email, String name, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsLoggedIn, true);
    await prefs.setString(_prefUserEmail, email);
    await prefs.setString(_prefUserName, name);
    await prefs.setString(_prefUserId, id);
    await prefs.setBool(_prefIsAdmin, isAdmin);
  }

  // ==================== SUPABASE INBUILT EMAIL & PASSWORD AUTH ====================

  /// Register a new user directly in Supabase native auth (auth.users)
  Future<SupabaseAuthResult> registerUserWithEmail({
    required String email,
    required String name,
    required String password,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Patient';
    final c = client;
    if (c == null || cleanEmail.isEmpty || cleanPwd.isEmpty) {
      return SupabaseAuthResult(success: false, errorMessage: 'Supabase client is not available.');
    }

    try {
      // 1. Direct call to Supabase Inbuilt Authentication (registers in auth.users)
      final authRes = await c.auth.signUp(
        email: cleanEmail,
        password: cleanPwd,
        emailRedirectTo: authRedirectUrl,
        data: {
          'name': cleanName,
        },
      );

      final user = authRes.user;
      if (user == null) {
        return SupabaseAuthResult(
          success: false,
          errorMessage: 'User registration failed on Supabase.',
        );
      }

      // Check if email verification is required:
      // When email confirmation is enabled in Supabase, session is null and emailConfirmedAt is null
      final isEmailConfirmed = user.emailConfirmedAt != null;
      final isConfirmationRequired = !isEmailConfirmed && authRes.session == null;

      // Sync public app_users table with native auth UUID so foreign keys and sync work seamlessly
      try {
        await c.from('app_users').upsert({
          'id': user.id,
          'email': cleanEmail,
          'name': cleanName,
          'is_verified': isEmailConfirmed,
          'last_login': DateTime.now().toIso8601String(),
        }, onConflict: 'email');
      } catch (dbErr) {
        debugPrint('app_users upsert note: $dbErr');
      }

      if (!isConfirmationRequired) {
        // Immediate session granted
        await _saveLocalSession(user.id, cleanEmail, cleanName, false);
        _currentUser = SupabaseUserSession(
          id: user.id,
          email: cleanEmail,
          name: cleanName,
          isVerified: true,
          isAdmin: false,
        );
      }

      return SupabaseAuthResult(
        success: true,
        isEmailConfirmationRequired: isConfirmationRequired,
        user: user,
      );
    } on AuthException catch (e) {
      debugPrint('Supabase signUp AuthException: ${e.message}');
      return SupabaseAuthResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('Supabase signUp error: $e');
      return SupabaseAuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with Email and Password using Supabase Inbuilt Auth (auth.users)
  Future<SupabaseAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();
    final c = client;
    if (c == null || cleanEmail.isEmpty || cleanPwd.isEmpty) {
      return SupabaseAuthResult(success: false, errorMessage: 'Supabase client is not available.');
    }

    try {
      // 1. Direct call to Supabase Inbuilt Authentication (authenticates against auth.users)
      final authRes = await c.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPwd,
      );

      final user = authRes.user;
      if (user == null) {
        return SupabaseAuthResult(
          success: false,
          errorMessage: 'Sign in failed.',
        );
      }

      final name = (user.userMetadata?['name'] as String?) ?? cleanEmail.split('@').first;

      // Sync public app_users table with native auth UUID
      try {
        await c.from('app_users').upsert({
          'id': user.id,
          'email': cleanEmail,
          'name': name,
          'is_verified': true,
          'last_login': DateTime.now().toIso8601String(),
        }, onConflict: 'email');
      } catch (_) {}

      await _saveLocalSession(user.id, cleanEmail, name, false);
      _currentUser = SupabaseUserSession(
        id: user.id,
        email: cleanEmail,
        name: name,
        isVerified: true,
        isAdmin: false,
      );

      return SupabaseAuthResult(
        success: true,
        user: user,
      );
    } on AuthException catch (e) {
      debugPrint('Supabase signIn AuthException: ${e.message}');
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        return SupabaseAuthResult(
          success: false,
          isEmailConfirmationRequired: true,
          errorMessage: 'Email not confirmed. Please check your inbox and verify your email.',
        );
      }
      return SupabaseAuthResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      debugPrint('Supabase signIn error: $e');
      return SupabaseAuthResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Resend Supabase email verification link to user's email
  Future<SupabaseAuthResult> resendEmailConfirmation(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final c = client;
    if (c == null) {
      return SupabaseAuthResult(success: false, errorMessage: 'Supabase client is not available.');
    }

    try {
      await c.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
        emailRedirectTo: authRedirectUrl,
      );
      return SupabaseAuthResult(success: true);
    } on AuthException catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.toString());
    }
  }

  /// Verify Supabase email signup via 6-digit OTP token
  Future<SupabaseAuthResult> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    final c = client;
    if (c == null) {
      return SupabaseAuthResult(success: false, errorMessage: 'Supabase client is not available.');
    }

    try {
      final res = await c.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.signup,
      );

      final user = res.user;
      if (user != null) {
        final name = (user.userMetadata?['name'] as String?) ?? cleanEmail.split('@').first;
        await _saveLocalSession(user.id, cleanEmail, name, false);
        _currentUser = SupabaseUserSession(
          id: user.id,
          email: cleanEmail,
          name: name,
          isVerified: true,
          isAdmin: false,
        );

        try {
          await c.from('app_users').upsert({
            'id': user.id,
            'email': cleanEmail,
            'name': name,
            'is_verified': true,
            'last_login': DateTime.now().toIso8601String(),
          }, onConflict: 'email');
        } catch (_) {}

        return SupabaseAuthResult(success: true, user: user);
      }
      return SupabaseAuthResult(success: false, errorMessage: 'Verification failed.');
    } on AuthException catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.toString());
    }
  }

  /// Send official Supabase password reset link to user's email
  Future<SupabaseAuthResult> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final c = client;
    if (c == null) {
      return SupabaseAuthResult(success: false, errorMessage: 'Supabase client is not available.');
    }

    try {
      await c.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: authRedirectUrl,
      );
      return SupabaseAuthResult(success: true);
    } on AuthException catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.message);
    } catch (e) {
      return SupabaseAuthResult(success: false, errorMessage: e.toString());
    }
  }

  /// Checks if an email address already exists and whether a password is set
  Future<UserAuthStatus> checkUserEmailStatus(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final c = client;
    if (c == null || cleanEmail.isEmpty) {
      return UserAuthStatus(exists: false, hasPassword: false);
    }

    try {
      final res = await c
          .from('app_users')
          .select('email, name, password, security_pin, security_question, is_admin')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (res == null) {
        return UserAuthStatus(exists: false, hasPassword: false);
      }

      final pwd = res['password']?.toString() ?? res['security_pin']?.toString();
      final hasPwd = pwd != null && pwd.trim().isNotEmpty;
      return UserAuthStatus(
        exists: true,
        hasPassword: hasPwd,
        email: res['email']?.toString() ?? cleanEmail,
        name: res['name']?.toString(),
        securityQuestion: res['security_question']?.toString(),
        isAdmin: res['is_admin'] == true,
      );
    } catch (e) {
      debugPrint('SupabaseService checkUserEmailStatus error: $e');
      return UserAuthStatus(exists: false, hasPassword: false);
    }
  }

  /// Verify Security Question Answer for password recovery
  Future<bool> verifySecurityAnswerByEmail({
    required String email,
    required String enteredAnswer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final c = client;
    if (c == null || cleanEmail.isEmpty) return false;

    try {
      final res = await c
          .from('app_users')
          .select('security_answer')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (res == null) return false;
      final savedAnswer = res['security_answer']?.toString().trim().toLowerCase();
      return savedAnswer == enteredAnswer.trim().toLowerCase();
    } catch (e) {
      debugPrint('SupabaseService verifySecurityAnswerByEmail error: $e');
      return false;
    }
  }

  /// Reset Password after answering security question or through admin
  Future<bool> resetPasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = newPassword.trim();
    final c = client;
    if (c == null || cleanEmail.isEmpty || cleanPwd.isEmpty) return false;

    try {
      await c.from('app_users').update({
        'password': cleanPwd,
        'security_pin': cleanPwd,
        'last_login': DateTime.now().toIso8601String(),
      }).eq('email', cleanEmail);
      return true;
    } catch (e) {
      debugPrint('SupabaseService resetPasswordByEmail error: $e');
      return false;
    }
  }

  /// Submit a password reset support request to Admin table
  Future<bool> submitPasswordResetRequest({
    required String email,
    String? userName,
    String? message,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final c = client;
    if (c == null || cleanEmail.isEmpty) return false;

    try {
      await c.from('pin_reset_requests').insert({
        'email': cleanEmail,
        'user_name': userName ?? 'User',
        'message': message ?? 'I forgot my password. Please help me reset.',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseService submitPasswordResetRequest error: $e');
      return false;
    }
  }

  // ==================== ADMIN CONTROL PANEL ====================

  /// Fetch all registered users in Supabase
  Future<List<Map<String, dynamic>>> adminGetAllUsers() async {
    final c = client;
    if (c == null) return [];

    try {
      final List<dynamic> res = await c
          .from('app_users')
          .select()
          .order('last_login', ascending: false);
      return res.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('SupabaseService adminGetAllUsers error: $e');
      return [];
    }
  }

  /// Fetch all support/reset requests in Supabase
  Future<List<Map<String, dynamic>>> adminGetAllRequests() async {
    final c = client;
    if (c == null) return [];

    try {
      final List<dynamic> res = await c
          .from('pin_reset_requests')
          .select()
          .order('created_at', ascending: false);
      return res.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('SupabaseService adminGetAllRequests error: $e');
      return [];
    }
  }

  /// Fetch all medicines across users in Supabase
  Future<List<Map<String, dynamic>>> adminGetAllMedicines() async {
    final c = client;
    if (c == null) return [];

    try {
      final List<dynamic> res = await c
          .from('user_medicines')
          .select()
          .order('updated_at', ascending: false);
      return res.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('SupabaseService adminGetAllMedicines error: $e');
      return [];
    }
  }

  /// Update password directly for any user from the Admin panel
  Future<bool> adminUpdateUserPassword({
    required String email,
    required String newPassword,
  }) async {
    return await resetPasswordByEmail(email: email, newPassword: newPassword);
  }

  /// Update user PIN directly (legacy compat)
  Future<bool> adminUpdateUserPin({
    required String phoneNumber,
    required String newPin,
  }) async {
    if (phoneNumber.contains('@')) {
      return await resetPasswordByEmail(email: phoneNumber, newPassword: newPin);
    }
    return await resetPin(phoneNumber: phoneNumber, newPin: newPin);
  }

  /// Resolve a support request
  Future<bool> adminResolveRequest(String requestId) async {
    final c = client;
    if (c == null) return false;

    try {
      await c.from('pin_reset_requests').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService adminResolveRequest error: $e');
      return false;
    }
  }

  /// Get overall database statistics for the admin dashboard
  Future<Map<String, int>> adminGetStats() async {
    final c = client;
    if (c == null) return {'users': 0, 'medicines': 0, 'pending_requests': 0};

    try {
      final users = await c.from('app_users').select('id');
      final meds = await c.from('user_medicines').select('id');
      final reqs = await c.from('pin_reset_requests').select('id').eq('status', 'pending');

      return {
        'users': (users as List).length,
        'medicines': (meds as List).length,
        'pending_requests': (reqs as List).length,
      };
    } catch (e) {
      debugPrint('SupabaseService adminGetStats error: $e');
      return {'users': 0, 'medicines': 0, 'pending_requests': 0};
    }
  }

  // ==================== BACKWARD COMPATIBILITY / LEGACY METHODS ====================

  Future<UserAuthStatus> checkUserStatus(String phoneOrEmail) async {
    if (phoneOrEmail.contains('@')) {
      return checkUserEmailStatus(phoneOrEmail);
    }
    final cleanPhone = phoneOrEmail.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return UserAuthStatus(exists: false, hasPassword: false);

    try {
      final res = await c
          .from('app_users')
          .select('phone_number, email, name, security_pin, password, security_question, is_admin')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) return UserAuthStatus(exists: false, hasPassword: false);

      final pwd = res['password']?.toString() ?? res['security_pin']?.toString();
      final hasPwd = pwd != null && pwd.trim().isNotEmpty;
      return UserAuthStatus(
        exists: true,
        hasPassword: hasPwd,
        email: res['email']?.toString(),
        name: res['name']?.toString(),
        securityQuestion: res['security_question']?.toString(),
        isAdmin: res['is_admin'] == true,
      );
    } catch (e) {
      debugPrint('SupabaseService checkUserStatus error: $e');
      return UserAuthStatus(exists: false, hasPassword: false);
    }
  }

  Future<bool> registerUserWithPin({
    required String phoneNumber,
    required String name,
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    if (phoneNumber.contains('@')) {
      final res = await registerUserWithEmail(
        email: phoneNumber,
        name: name,
        password: pin,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      return res.success;
    }
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      final userId = 'user_${cleanPhone.replaceAll('+', '')}';

      await c.from('app_users').upsert({
        'phone_number': cleanPhone,
        'name': name.trim().isNotEmpty ? name.trim() : 'Patient',
        'password': pin.trim(),
        'security_pin': pin.trim(),
        'security_question': securityQuestion.trim(),
        'security_answer': securityAnswer.trim().toLowerCase(),
        'is_verified': true,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'phone_number');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserPhone, cleanPhone);
      await prefs.setString(_prefUserName, name);
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, false);

      _currentUser = SupabaseUserSession(
        id: userId,
        email: cleanPhone,
        phoneNumber: cleanPhone,
        name: name,
        isAdmin: false,
      );
      return true;
    } catch (e) {
      debugPrint('SupabaseService registerUserWithPin error: $e');
      return false;
    }
  }

  Future<bool> verifyPin({
    required String phoneNumber,
    required String enteredPin,
  }) async {
    if (phoneNumber.contains('@')) {
      final res = await loginWithEmail(email: phoneNumber, password: enteredPin);
      return res.success;
    }
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      final res = await c
          .from('app_users')
          .select('id, name, security_pin, password, is_admin')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) return false;

      final savedPin = res['password']?.toString().trim() ?? res['security_pin']?.toString().trim();
      if (savedPin != enteredPin.trim()) return false;

      final userId = 'user_${cleanPhone.replaceAll('+', '')}';
      final name = res['name']?.toString() ?? 'Patient';
      final isAdm = res['is_admin'] == true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserPhone, cleanPhone);
      await prefs.setString(_prefUserName, name);
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, isAdm);

      _currentUser = SupabaseUserSession(
        id: userId,
        email: cleanPhone,
        phoneNumber: cleanPhone,
        name: name,
        isAdmin: isAdm,
      );

      await c.from('app_users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', cleanPhone);

      return true;
    } catch (e) {
      debugPrint('SupabaseService verifyPin error: $e');
      return false;
    }
  }

  Future<bool> verifySecurityAnswer({
    required String phoneNumber,
    required String enteredAnswer,
  }) async {
    if (phoneNumber.contains('@')) {
      return verifySecurityAnswerByEmail(email: phoneNumber, enteredAnswer: enteredAnswer);
    }
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      final res = await c
          .from('app_users')
          .select('security_answer')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) return false;
      final savedAnswer = res['security_answer']?.toString().trim().toLowerCase();
      return savedAnswer == enteredAnswer.trim().toLowerCase();
    } catch (e) {
      debugPrint('SupabaseService verifySecurityAnswer error: $e');
      return false;
    }
  }

  Future<bool> resetPin({
    required String phoneNumber,
    required String newPin,
  }) async {
    if (phoneNumber.contains('@')) {
      return resetPasswordByEmail(email: phoneNumber, newPassword: newPin);
    }
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      await c.from('app_users').update({
        'password': newPin.trim(),
        'security_pin': newPin.trim(),
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', cleanPhone);
      return true;
    } catch (e) {
      debugPrint('SupabaseService resetPin error: $e');
      return false;
    }
  }

  Future<bool> submitPinResetRequest({
    required String phoneNumber,
    String? userName,
    String? message,
  }) async {
    if (phoneNumber.contains('@')) {
      return submitPasswordResetRequest(email: phoneNumber, userName: userName, message: message);
    }
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      await c.from('pin_reset_requests').insert({
        'phone_number': cleanPhone,
        'user_name': userName ?? 'User',
        'message': message ?? 'I forgot my PIN. Please help me reset.',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseService submitPinResetRequest error: $e');
      return false;
    }
  }

  String generateVerificationCode() {
    final rnd = Random();
    return (1000 + rnd.nextInt(9000)).toString();
  }

  Future<String> requestVerificationCode(String phoneNumber) async {
    return generateVerificationCode();
  }

  Future<bool> verifyCode({
    required String phoneNumber,
    required String enteredCode,
    required String expectedCode,
    String? userName,
  }) async {
    return verifyPin(phoneNumber: phoneNumber, enteredPin: enteredCode);
  }

  /// Verify whether the current user is still active in the cloud database (not deleted by admin)
  Future<bool> isCurrentUserActiveInCloud() async {
    final c = client;
    if (c == null) return true; // Offline or no network: maintain offline access

    final email = currentUser?.email;
    final phone = currentUser?.phoneNumber;
    final id = currentUser?.id;

    if ((email == null || email.isEmpty) &&
        (phone == null || phone.isEmpty) &&
        (id == null || id.isEmpty)) {
      return false;
    }

    try {
      var query = c.from('app_users').select('id');
      if (email != null && email.isNotEmpty && email.contains('@')) {
        query = query.eq('email', email.trim().toLowerCase());
      } else if (phone != null && phone.isNotEmpty) {
        query = query.eq('phone_number', phone.trim());
      } else if (id != null && id.isNotEmpty) {
        query = query.eq('id', id.trim());
      }

      final List<dynamic> res = await query.limit(1);
      return res.isNotEmpty;
    } catch (e) {
      debugPrint('isCurrentUserActiveInCloud check notice: $e');
      // If temporary network issue or offline, do not forcefully log out
      return true;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (e) {
      debugPrint('Supabase client signOut error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIsLoggedIn);
    await prefs.remove(_prefUserEmail);
    await prefs.remove(_prefUserPhone);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefUserId);
    await prefs.remove(_prefIsAdmin);
    _currentUser = null;
  }
}

