import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/cloud_sync_service.dart';
import '../core/services/supabase_service.dart';
import 'medicine_provider.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  String _phoneNumber = '';
  String? _generatedVerificationCode;
  bool _isCodeSent = false;
  int _countdownSeconds = 0;
  Timer? _timer;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _supabase.initSession();
    notifyListeners();
  }

  bool get isSignedIn => _supabase.isSignedIn;
  String? get phoneNumber => _supabase.currentUser?.phoneNumber ?? (_phoneNumber.isNotEmpty ? _phoneNumber : null);
  String? get displayName => _supabase.currentUser?.name;
  String? get userId => _supabase.currentUser?.id;
  String? get email => phoneNumber != null ? '$phoneNumber' : null;
  String? get photoUrl => null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get countdownSeconds => _countdownSeconds;
  bool get canResendOtp => _countdownSeconds == 0;
  bool get isCodeSent => _isCodeSent;
  String? get generatedVerificationCode => _generatedVerificationCode;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetFlow() {
    _isCodeSent = false;
    _generatedVerificationCode = null;
    _errorMessage = null;
    _timer?.cancel();
    _countdownSeconds = 0;
    notifyListeners();
  }

  void _startCountdown() {
    _timer?.cancel();
    _countdownSeconds = 30;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// Request verification code: saves phone to Supabase and generates on-screen code
  Future<bool> sendOtp(String fullPhoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _phoneNumber = fullPhoneNumber;
    notifyListeners();

    try {
      final code = await _supabase.requestVerificationCode(fullPhoneNumber);
      _generatedVerificationCode = code;
      _isCodeSent = true;
      _isLoading = false;
      _startCountdown();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to generate code: $e';
      notifyListeners();
      return false;
    }
  }

  /// Verify on-screen code and automatically sync local SQLite data with Supabase
  Future<bool> verifyOtp(String enteredCode, MedicineProvider medicineProvider) async {
    if (_generatedVerificationCode == null) {
      _errorMessage = 'No active verification session. Please request code again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSuccess = await _supabase.verifyCode(
        phoneNumber: _phoneNumber,
        enteredCode: enteredCode,
        expectedCode: _generatedVerificationCode!,
        userName: medicineProvider.profiles.isNotEmpty ? medicineProvider.profiles.first.name : 'User',
      );

      _isLoading = false;
      _timer?.cancel();

      if (isSuccess) {
        notifyListeners();
        // Sync local medicines and reminders to Supabase
        await CloudSyncService.instance.syncLocalToCloud(
          profiles: medicineProvider.profiles,
          medicines: medicineProvider.medicines,
          records: medicineProvider.intakeRecords,
        );
        return true;
      } else {
        _errorMessage = 'ভুল কোড দেওয়া হয়েছে! অনুগ্রহ করে স্ক্রিনে দেখানো কোডটি সঠিক লিখুন।';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
