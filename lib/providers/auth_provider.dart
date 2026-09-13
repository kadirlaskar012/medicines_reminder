import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/cloud_sync_service.dart';
import 'medicine_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Phone Auth flow states
  String? _verificationId;
  int? _resendToken;
  String _phoneNumber = '';
  int _countdownSeconds = 0;
  Timer? _timer;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  String? get phoneNumber => _user?.phoneNumber ?? (_phoneNumber.isNotEmpty ? _phoneNumber : null);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get countdownSeconds => _countdownSeconds;
  bool get canResendOtp => _countdownSeconds == 0;
  String? get verificationId => _verificationId;
  int? get resendToken => _resendToken;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startCountdown() {
    _timer?.cancel();
    _countdownSeconds = 45;
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

  /// Initiate Phone OTP
  Future<bool> sendOtp(String fullPhoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    _phoneNumber = fullPhoneNumber;
    notifyListeners();

    final completer = Completer<bool>();

    await _authService.sendOtp(
      fullPhoneNumber: fullPhoneNumber,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _isLoading = false;
        _startCountdown();
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (err) {
        _isLoading = false;
        _errorMessage = err;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAutoVerified: (credential) async {
        try {
          await _authService.signInWithCredential(credential);
          _isLoading = false;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        } catch (e) {
          _isLoading = false;
          _errorMessage = e.toString();
          notifyListeners();
          if (!completer.isCompleted) completer.complete(false);
        }
      },
    );

    return completer.future;
  }

  /// Verify 6-digit OTP code and sync local data to cloud
  Future<bool> verifyOtp(String smsCode, MedicineProvider medicineProvider) async {
    if (_verificationId == null) {
      _errorMessage = 'Verification session expired. Please request OTP again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      _isLoading = false;
      _timer?.cancel();
      notifyListeners();

      if (cred?.user != null) {
        // Automatically sync all existing local medicines, profiles, and records to Cloud Firestore!
        await CloudSyncService.instance.syncLocalToCloud(
          profiles: medicineProvider.profiles,
          medicines: medicineProvider.medicines,
          records: medicineProvider.intakeRecords,
        );
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().contains('invalid-verification-code')
          ? 'Invalid OTP code. Please enter the correct 6-digit code.'
          : e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
