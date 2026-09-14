import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/cloud_sync_service.dart';
import '../core/services/supabase_service.dart';
import 'medicine_provider.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _supabase.initSession();
    notifyListeners();
  }

  bool get isSignedIn => _supabase.isSignedIn;
  bool get isAdmin => _supabase.isAdmin;
  String? get email => _supabase.currentUser?.email;
  String? get phoneNumber => _supabase.currentUser?.phoneNumber;
  String? get displayName => _supabase.currentUser?.name;
  String? get userId => _supabase.currentUser?.id;
  String? get photoUrl => null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetFlow() {
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Sign in with Email and Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required MedicineProvider medicineProvider,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'একটি সঠিক ইমেল ঠিকানা প্রদান করুন';
      notifyListeners();
      return false;
    }

    if (cleanPwd.isEmpty) {
      _errorMessage = 'পাসওয়ার্ড লিখুন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _supabase.loginWithEmail(
        email: cleanEmail,
        password: cleanPwd,
      );

      if (!success) {
        _isLoading = false;
        _errorMessage = 'ইমেল বা পাসওয়ার্ড ভুল দেওয়া হয়েছে!';
        notifyListeners();
        return false;
      }

      // 1. Restore previous medicines from cloud for this email
      await medicineProvider.restoreUserFromCloud(cleanEmail);

      // 2. Sync local medicines/profiles to cloud
      await CloudSyncService.instance.syncLocalToCloud(
        profiles: medicineProvider.profiles,
        medicines: medicineProvider.medicines,
        remindersByMedicine: medicineProvider.remindersByMedicine,
        records: medicineProvider.intakeRecords,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'সাইন ইন করতে ত্রুটি: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign up / Create Account with Email and Password
  Future<bool> signUpWithEmail({
    required String email,
    required String name,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
    required MedicineProvider medicineProvider,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPwd = password.trim();
    final cleanAnswer = securityAnswer.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'আপনার পুরো নাম লিখুন';
      notifyListeners();
      return false;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'একটি সঠিক ইমেল ঠিকানা প্রদান করুন';
      notifyListeners();
      return false;
    }

    if (cleanPwd.length < 6) {
      _errorMessage = 'কমপক্ষে ৬ অক্ষরের একটি শক্তিশালী পাসওয়ার্ড দিন';
      notifyListeners();
      return false;
    }

    if (cleanAnswer.isEmpty) {
      _errorMessage = 'পাসওয়ার্ড রিকভারি প্রশ্নের উত্তর দিন';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _supabase.registerUserWithEmail(
        email: cleanEmail,
        name: cleanName,
        password: cleanPwd,
        securityQuestion: securityQuestion,
        securityAnswer: cleanAnswer,
      );

      if (!success) {
        _isLoading = false;
        _errorMessage = 'অ্যাকাউন্ট তৈরি করা যায়নি। এই ইমেলে অ্যাকাউন্ট থাকতে পারে।';
        notifyListeners();
        return false;
      }

      // Sync existing local medicines to cloud for new account
      await CloudSyncService.instance.syncLocalToCloud(
        profiles: medicineProvider.profiles,
        medicines: medicineProvider.medicines,
        remindersByMedicine: medicineProvider.remindersByMedicine,
        records: medicineProvider.intakeRecords,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'সাইন আপ করতে ত্রুটি: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _supabase.signOut();
    resetFlow();
    _isLoading = false;
    notifyListeners();
  }

  // Legacy stubs for compatibility
  int get countdownSeconds => 0;
  bool get canResendOtp => true;
  bool get isCodeSent => false;
  String? get generatedVerificationCode => null;
  Future<bool> sendOtp(String fullPhoneNumber) async => false;
  Future<bool> verifyOtp(String enteredCode, MedicineProvider medicineProvider) async => false;
}

