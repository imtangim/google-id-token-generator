import 'package:firebase_auth/firebase_auth.dart' show User;

/// High-level contract for authentication operations.
///
/// Domain layer should depend on this abstraction, not on Firebase directly.
abstract class AuthRepository {
  /// Stream of auth user changes. Emits null when signed out.
  Stream<User?> authStateChanges();

  /// Returns the currently signed-in user, if any.
  User? get currentUser;

  /// Trigger Google sign-in (web via popup).
  Future<void> signInWithGoogle();

  /// Refresh tokens if possible, keeping the user session.
  Future<void> refreshTokens();

  /// Gets the Firebase ID token expiration time.
  /// Returns null if user is not authenticated.
  Future<DateTime?> getFirebaseTokenExpiration();

  /// Sign out the current user.
  Future<void> signOut();
}


