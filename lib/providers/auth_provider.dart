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

  bool _isEmailConfirmationPending = false;
  bool get isEmailConfirmationPending => _isEmailConfirmationPending;
  String? _pendingVerificationEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  void setEmailConfirmationPending(String email) {
    _isEmailConfirmationPending = true;
    _pendingVerificationEmail = email;
    notifyListeners();
  }

  void clearEmailConfirmationPending() {
    _isEmailConfirmationPending = false;
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  void resetFlow() {
    _errorMessage = null;
    _isLoading = false;
    _isEmailConfirmationPending = false;
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  /// Sign in with Email and Password via Supabase Inbuilt Auth
  Future<SupabaseAuthResult> signInWithEmail({
    required String email,
    required String password,
    required MedicineProvider medicineProvider,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPwd = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }

    if (cleanPwd.isEmpty) {
      _errorMessage = 'Please enter your password';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _supabase.loginWithEmail(
        email: cleanEmail,
        password: cleanPwd,
      );

      if (!result.success) {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Invalid email or password!';
        _isEmailConfirmationPending = result.isEmailConfirmationRequired;
        if (result.isEmailConfirmationRequired) {
          _pendingVerificationEmail = cleanEmail;
        }
        notifyListeners();
        return result;
      }

      _isEmailConfirmationPending = false;
      _pendingVerificationEmail = null;

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
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign in error: $e';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }
  }

  /// Sign up / Create Account with Email and Password via Supabase Inbuilt Auth
  Future<SupabaseAuthResult> signUpWithEmail({
    required String email,
    required String name,
    required String password,
    String? securityQuestion,
    String? securityAnswer,
    required MedicineProvider medicineProvider,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPwd = password.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Please enter your full name';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }

    if (cleanPwd.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _supabase.registerUserWithEmail(
        email: cleanEmail,
        name: cleanName,
        password: cleanPwd,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );

      if (!result.success) {
        _isLoading = false;
        _errorMessage = result.errorMessage ?? 'Account creation failed.';
        notifyListeners();
        return result;
      }

      if (result.isEmailConfirmationRequired) {
        _isLoading = false;
        _isEmailConfirmationPending = true;
        _pendingVerificationEmail = cleanEmail;
        notifyListeners();
        return result;
      }

      _isEmailConfirmationPending = false;
      _pendingVerificationEmail = null;

      // Sync existing local medicines to cloud for new account
      await CloudSyncService.instance.syncLocalToCloud(
        profiles: medicineProvider.profiles,
        medicines: medicineProvider.medicines,
        remindersByMedicine: medicineProvider.remindersByMedicine,
        records: medicineProvider.intakeRecords,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign up error: $e';
      notifyListeners();
      return SupabaseAuthResult(success: false, errorMessage: _errorMessage);
    }
  }

  /// Resend Supabase confirmation email
  Future<SupabaseAuthResult> resendVerificationEmail(String email) async {
    return await _supabase.resendEmailConfirmation(email);
  }

  /// Verify signup using 6-digit OTP code sent in email
  Future<SupabaseAuthResult> verifySignupOtp({
    required String email,
    required String token,
    MedicineProvider? medicineProvider,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _supabase.verifySignupOtp(email: email, token: token);
    _isLoading = false;

    if (result.success) {
      _isEmailConfirmationPending = false;
      _pendingVerificationEmail = null;
      if (medicineProvider != null) {
        try {
          await CloudSyncService.instance.syncLocalToCloud(
            profiles: medicineProvider.profiles,
            medicines: medicineProvider.medicines,
            remindersByMedicine: medicineProvider.remindersByMedicine,
            records: medicineProvider.intakeRecords,
          );
        } catch (_) {}
      }
    } else {
      _errorMessage = result.errorMessage;
    }

    notifyListeners();
    return result;
  }

  /// Send password reset link to user's email from Supabase
  Future<SupabaseAuthResult> sendPasswordResetEmail(String email) async {
    return await _supabase.sendPasswordResetEmail(email);
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

  // ==================== LEGACY PHONE STUBS ====================
  int get countdownSeconds => 0;
  bool get canResendOtp => true;
  bool get isCodeSent => false;
  String? get generatedVerificationCode => null;
  Future<bool> sendOtp(String phone) async => false;
  Future<bool> verifyOtp(String otp, MedicineProvider med) async => false;
}
