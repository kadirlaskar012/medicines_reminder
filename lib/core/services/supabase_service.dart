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

  SupabaseUserSession? _currentUser;
  SupabaseUserSession? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Initialize session from local persistent storage
  Future<void> initSession() async {
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

  // ==================== EMAIL & PASSWORD AUTHENTICATION ====================

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

  /// Register a new user with Email, Name, Password, and Security Question/Answer
  Future<bool> registerUserWithEmail({
    required String email,
    required String name,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();
    final c = client;
    if (c == null || cleanEmail.isEmpty || cleanPwd.isEmpty) return false;

    try {
      final sanitizedEmailId = cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final userId = 'usr_$sanitizedEmailId';

      await c.from('app_users').upsert({
        'email': cleanEmail,
        'name': name.trim().isNotEmpty ? name.trim() : 'Patient',
        'password': cleanPwd,
        'security_pin': cleanPwd, // for legacy fallback
        'security_question': securityQuestion.trim(),
        'security_answer': securityAnswer.trim().toLowerCase(),
        'is_verified': true,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'email');

      // Save local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserEmail, cleanEmail);
      await prefs.setString(_prefUserName, name.trim().isNotEmpty ? name.trim() : 'Patient');
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, false);

      _currentUser = SupabaseUserSession(
        id: userId,
        email: cleanEmail,
        name: name.trim().isNotEmpty ? name.trim() : 'Patient',
        isAdmin: false,
      );
      return true;
    } catch (e) {
      debugPrint('SupabaseService registerUserWithEmail error: $e');
      return false;
    }
  }

  /// Verify email and password for an existing user and complete login
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();
    final c = client;
    if (c == null || cleanEmail.isEmpty || cleanPwd.isEmpty) return false;

    try {
      final res = await c
          .from('app_users')
          .select('id, email, name, password, security_pin, phone_number, is_admin')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (res == null) return false;

      final savedPwd = res['password']?.toString().trim();
      final savedPin = res['security_pin']?.toString().trim();

      // Check password or legacy pin
      if (savedPwd != cleanPwd && savedPin != cleanPwd) {
        return false;
      }

      final userId = res['id']?.toString() ?? 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final name = res['name']?.toString() ?? 'Patient';
      final phone = res['phone_number']?.toString();
      final isAdm = res['is_admin'] == true;

      // Save local persistent session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserEmail, cleanEmail);
      if (phone != null && phone.isNotEmpty) {
        await prefs.setString(_prefUserPhone, phone);
      }
      await prefs.setString(_prefUserName, name);
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, isAdm);

      _currentUser = SupabaseUserSession(
        id: userId,
        email: cleanEmail,
        phoneNumber: phone,
        name: name,
        isAdmin: isAdm,
      );

      // Update last login timestamp in background
      await c.from('app_users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('email', cleanEmail);

      return true;
    } catch (e) {
      debugPrint('SupabaseService loginWithEmail error: $e');
      return false;
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
      return registerUserWithEmail(
        email: phoneNumber,
        name: name,
        password: pin,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
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
      return loginWithEmail(email: phoneNumber, password: enteredPin);
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

  /// Sign out
  Future<void> signOut() async {
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
