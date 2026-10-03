import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Emits the signed-in user, or null when signed out.
  Stream<User?> get authChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Returns null on success, or a short message to show the user.
  Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-canceled') {
        return null; // user simply closed the window
      }
      return e.message ?? 'Sign-in failed. Please try again.';
    } catch (_) {
      return 'Sign-in failed. Check your internet connection.';
    }
  }

  Future<void> signOut() => _auth.signOut();
}
