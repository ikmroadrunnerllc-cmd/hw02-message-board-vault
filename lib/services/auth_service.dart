import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<User?> authState = _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  static String getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email. Please check your credentials or register.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please verify your details.';
        case 'email-already-in-use':
          return 'An account already exists with this email. Please sign in instead.';
        case 'invalid-email':
          return 'The email address format is invalid.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'network-request-failed':
          return 'Network error: Check your connection and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Access blocked temporarily. Try again later.';
        default:
          return error.message ?? 'An authentication error occurred (${error.code}).';
      }
    }
    return error.toString();
  }
}
