import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  static const String _kPrefGoogleIdToken = 'google_id_token';
  static const String _kPrefFirebaseIdToken = 'firebase_id_token';
  static const String _kPrefTokenUpdatedAtMs = 'tokens_updated_at_ms';

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.userChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError(
        'This sample uses Google sign-in via web popup only.',
      );
    }
    try {
      debugPrint('Starting Google sign-in...');
      final googleProvider = GoogleAuthProvider();
      debugPrint('Calling signInWithPopup...');
      final UserCredential cred = await _auth.signInWithPopup(googleProvider);
      debugPrint('Sign-in successful, user: ${cred.user?.email}');
      final OAuthCredential? oauth = cred.credential as OAuthCredential?;
      final String? googleToken = oauth?.idToken;
      final String? firebaseToken = await cred.user!.getIdToken();
      await _persistTokens(
        googleIdToken: googleToken,
        firebaseIdToken: firebaseToken,
      );
      debugPrint('Tokens persisted successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in signInWithGoogle: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> refreshTokens() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final IdTokenResult result = await user.getIdTokenResult(true);
    final String? firebaseToken = result.token ?? await user.getIdToken();
    String? googleToken;
    try {
      final googleProvider = GoogleAuthProvider();
      final UserCredential cred = await user.reauthenticateWithPopup(
        googleProvider,
      );
      final OAuthCredential? oauth = cred.credential as OAuthCredential?;
      googleToken = oauth?.idToken;
    } catch (_) {}
    await _persistTokens(
      googleIdToken: googleToken,
      firebaseIdToken: firebaseToken,
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearPersistedTokens();
  }

  /// Gets the Firebase ID token expiration time.
  /// Returns null if user is not authenticated.
  Future<DateTime?> getFirebaseTokenExpiration() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final result = await user.getIdTokenResult();
      return result.expirationTime;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistTokens({
    String? googleIdToken,
    String? firebaseIdToken,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (googleIdToken != null) {
        await prefs.setString(_kPrefGoogleIdToken, googleIdToken);
      }
      if (firebaseIdToken != null) {
        await prefs.setString(_kPrefFirebaseIdToken, firebaseIdToken);
      }
      await prefs.setInt(
        _kPrefTokenUpdatedAtMs,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> _clearPersistedTokens() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefGoogleIdToken);
      await prefs.remove(_kPrefFirebaseIdToken);
      await prefs.remove(_kPrefTokenUpdatedAtMs);
    } catch (_) {}
  }
}
