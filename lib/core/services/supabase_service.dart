import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserSession {
  final String id;
  final String phoneNumber;
  final String name;
  final bool isVerified;
  final bool isAdmin;

  SupabaseUserSession({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.isVerified = true,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'name': name,
    'isVerified': isVerified,
    'isAdmin': isAdmin,
  };
}

class UserAuthStatus {
  final bool exists;
  final bool hasPin;
  final String? name;
  final String? securityQuestion;
  final bool isAdmin;

  UserAuthStatus({
    required this.exists,
    required this.hasPin,
    this.name,
    this.securityQuestion,
    this.isAdmin = false,
  });
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
      final phone = prefs.getString(_prefUserPhone) ?? '';
      final name = prefs.getString(_prefUserName) ?? 'User';
      final id = prefs.getString(_prefUserId) ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final isAdm = prefs.getBool(_prefIsAdmin) ?? false;
      if (phone.isNotEmpty) {
        _currentUser = SupabaseUserSession(
          id: id,
          phoneNumber: phone,
          name: name,
          isAdmin: isAdm,
        );
      }
    }
  }

  // ==================== PIN AUTHENTICATION ====================

  /// Checks if a phone number already exists and whether a security PIN is set
  Future<UserAuthStatus> checkUserStatus(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) {
      return UserAuthStatus(exists: false, hasPin: false);
    }

    try {
      final res = await c
          .from('app_users')
          .select('phone_number, name, security_pin, security_question, is_admin')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) {
        return UserAuthStatus(exists: false, hasPin: false);
      }

      final pin = res['security_pin']?.toString();
      final hasPin = pin != null && pin.trim().isNotEmpty;
      return UserAuthStatus(
        exists: true,
        hasPin: hasPin,
        name: res['name']?.toString(),
        securityQuestion: res['security_question']?.toString(),
        isAdmin: res['is_admin'] == true,
      );
    } catch (e) {
      debugPrint('SupabaseService checkUserStatus error: $e');
      return UserAuthStatus(exists: false, hasPin: false);
    }
  }

  /// Register a new user with 4-digit Security PIN and Security Question/Answer
  Future<bool> registerUserWithPin({
    required String phoneNumber,
    required String name,
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      final userId = 'user_${cleanPhone.replaceAll('+', '')}';

      await c.from('app_users').upsert({
        'phone_number': cleanPhone,
        'name': name.trim().isNotEmpty ? name.trim() : 'Patient',
        'security_pin': pin.trim(),
        'security_question': securityQuestion.trim(),
        'security_answer': securityAnswer.trim().toLowerCase(),
        'is_verified': true,
        'last_login': DateTime.now().toIso8601String(),
      }, onConflict: 'phone_number');

      // Save local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserPhone, cleanPhone);
      await prefs.setString(_prefUserName, name);
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, false);

      _currentUser = SupabaseUserSession(
        id: userId,
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

  /// Verify PIN for an existing user and complete login
  Future<bool> verifyPin({
    required String phoneNumber,
    required String enteredPin,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      final res = await c
          .from('app_users')
          .select('id, name, security_pin, is_admin')
          .eq('phone_number', cleanPhone)
          .maybeSingle();

      if (res == null) return false;

      final savedPin = res['security_pin']?.toString().trim();
      if (savedPin != enteredPin.trim()) {
        return false;
      }

      final userId = 'user_${cleanPhone.replaceAll('+', '')}';
      final name = res['name']?.toString() ?? 'Patient';
      final isAdm = res['is_admin'] == true;

      // Save local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsLoggedIn, true);
      await prefs.setString(_prefUserPhone, cleanPhone);
      await prefs.setString(_prefUserName, name);
      await prefs.setString(_prefUserId, userId);
      await prefs.setBool(_prefIsAdmin, isAdm);

      _currentUser = SupabaseUserSession(
        id: userId,
        phoneNumber: cleanPhone,
        name: name,
        isAdmin: isAdm,
      );

      // Update last login timestamp in background
      await c.from('app_users').update({
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', cleanPhone);

      return true;
    } catch (e) {
      debugPrint('SupabaseService verifyPin error: $e');
      return false;
    }
  }

  /// Verify Security Question Answer for PIN self-service recovery
  Future<bool> verifySecurityAnswer({
    required String phoneNumber,
    required String enteredAnswer,
  }) async {
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

  /// Reset PIN after answering security question or through admin
  Future<bool> resetPin({
    required String phoneNumber,
    required String newPin,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final c = client;
    if (c == null) return false;

    try {
      await c.from('app_users').update({
        'security_pin': newPin.trim(),
        'last_login': DateTime.now().toIso8601String(),
      }).eq('phone_number', cleanPhone);
      return true;
    } catch (e) {
      debugPrint('SupabaseService resetPin error: $e');
      return false;
    }
  }

  /// Submit a PIN reset support request to Admin table
  Future<bool> submitPinResetRequest({
    required String phoneNumber,
    String? userName,
    String? message,
  }) async {
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

  /// Update PIN directly for any user from the Admin panel
  Future<bool> adminUpdateUserPin({
    required String phoneNumber,
    required String newPin,
  }) async {
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

  // Legacy compatibility methods
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
    await prefs.remove(_prefUserPhone);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefUserId);
    await prefs.remove(_prefIsAdmin);
    _currentUser = null;
  }
}
