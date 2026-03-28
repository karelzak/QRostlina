import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  bool get isSupported => kIsWeb || Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    if (isSupported) {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        _auth = FirebaseAuth.instance;
        _googleSignIn = GoogleSignIn();
      } catch (e) {
        debugPrint('Firebase Auth initialization failed: $e');
      }
    }
  }

  Stream<User?> get userStream {
    if (_auth != null) {
      return _auth!.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    if (!isSupported || _auth == null || _googleSignIn == null) {
      debugPrint('Google Sign-In is not supported on this platform.');
      return null;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (isSupported && _auth != null && _googleSignIn != null) {
      await _googleSignIn!.signOut();
      await _auth!.signOut();
    }
  }
}

final authService = AuthService();
