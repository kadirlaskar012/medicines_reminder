import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not yet initialized: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _auth?.currentUser;

  bool get isSignedIn => _auth?.currentUser != null;

  String? get userPhoneNumber => _auth?.currentUser?.phoneNumber;

  String? get userDisplayName => _auth?.currentUser?.displayName;

  String? get userEmail => _auth?.currentUser?.email;

  String? get userPhotoUrl => _auth?.currentUser?.photoURL;

  String? get userId => _auth?.currentUser?.uid;

  /// Send OTP to user's mobile number
  Future<void> sendOtp({
    required String fullPhoneNumber, // e.g. +919876543210
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String errorMessage) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    final auth = _auth;
    if (auth == null) {
      onError('Firebase is not initialized on this device.');
      return;
    }

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Phone verification auto-completed: $credential');
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          String message = e.message ?? 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            message = 'The entered phone number is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try again later.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('SMS OTP code sent: verificationId=$verificationId');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout: verificationId=$verificationId');
        },
      );
    } catch (e) {
      debugPrint('Error in verifyPhoneNumber: $e');
      onError(e.toString());
    }
  }

  /// Verify 6-digit SMS OTP code
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized on this device.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );

    return await auth.signInWithCredential(credential);
  }

  /// Sign in with auto-retrieved PhoneAuthCredential
  Future<UserCredential?> signInWithCredential(PhoneAuthCredential credential) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized on this device.');
    }
    return await auth.signInWithCredential(credential);
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized on this device.');
    }

    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return null; // User canceled sign-in
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await auth.signInWithCredential(credential);
  }

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth?.signOut();
  }
}
