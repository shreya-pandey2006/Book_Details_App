import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

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
        return null;
      }
      return _message(e);
    } catch (_) {
      return 'Sign-in failed. Check your internet connection.';
    }
  }
  Future<void> signOut() => _auth.signOut();

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }
}