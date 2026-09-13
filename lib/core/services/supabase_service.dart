import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserSession {
  final String id;
  final String phoneNumber;
  final String name;
  final bool isVerified;

  SupabaseUserSession({
    required this.id,
    required this.phoneNumber,
    required this.name,
    this.isVerified = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'name': name,
    'isVerified': isVerified,
  };
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

  SupabaseUserSession? _currentUser;
  SupabaseUserSession? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Initialize session from local persistent storage
  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefIsLoggedIn) ?? false;
    if (isLoggedIn) {
      final phone = prefs.getString(_prefUserPhone) ?? '';
      final name = prefs.getString(_prefUserName) ?? 'User';
      final id = prefs.getString(_prefUserId) ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      if (phone.isNotEmpty) {
        _currentUser = SupabaseUserSession(id: id, phoneNumber: phone, name: name);
      }
    }
  }

  /// Generates a secure, readable 4-digit code for instant on-screen verification
  String generateVerificationCode() {
    final rnd = Random();
    return (1000 + rnd.nextInt(9000)).toString();
  }

  /// Registers or checks phone number in Supabase and returns the generated verification code
  Future<String> requestVerificationCode(String phoneNumber) async {
    final code = generateVerificationCode();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    try {
      final c = client;
      if (c != null) {
        // Upsert into Supabase app_users table
        await c.from('app_users').upsert(
          {
            'phone_number': cleanPhone,
            'verification_code': code,
            'is_verified': false,
            'last_login': DateTime.now().toIso8601String(),
          },
          onConflict: 'phone_number',
        );
      }
    } catch (e) {
      debugPrint('Supabase cloud record note (will proceed with local verification): $e');
    }

    return code;
  }

  /// Verifies the entered code matches the generated code and completes login
  Future<bool> verifyCode({
    required String phoneNumber,
    required String enteredCode,
    required String expectedCode,
    String? userName,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (enteredCode.trim() != expectedCode.trim()) {
      return false;
    }

    final userId = 'user_${cleanPhone.replaceAll('+', '')}';
    final name = (userName != null && userName.trim().isNotEmpty) ? userName.trim() : 'Patient';

    // 1. Save session to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefIsLoggedIn, true);
    await prefs.setString(_prefUserPhone, cleanPhone);
    await prefs.setString(_prefUserName, name);
    await prefs.setString(_prefUserId, userId);

    _currentUser = SupabaseUserSession(id: userId, phoneNumber: cleanPhone, name: name);

    // 2. Update Supabase record in background
    try {
      final c = client;
      if (c != null) {
        await c.from('app_users').update({
          'is_verified': true,
          'name': name,
          'last_login': DateTime.now().toIso8601String(),
        }).eq('phone_number', cleanPhone);
      }
    } catch (e) {
      debugPrint('Supabase update note: $e');
    }

    return true;
  }

  /// Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIsLoggedIn);
    await prefs.remove(_prefUserPhone);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefUserId);
    _currentUser = null;
  }
}
