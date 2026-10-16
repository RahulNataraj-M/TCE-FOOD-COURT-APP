import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/app_role.dart';

/// Why a sign-in attempt did not produce a signed-in user.
enum AuthFailureReason {
  cancelled,
  unauthorizedDomain,
  network,
  misconfigured,
  unknown,
}

/// A sign-in failure that is already phrased for the user.
class AuthFailure implements Exception {
  const AuthFailure(this.reason, this.message);

  final AuthFailureReason reason;
  final String message;

  @override
  String toString() => message;
}

/// Authentication boundary of the app.
///
/// Screens depend on this interface rather than on `FirebaseAuth` directly so
/// the sign-in flow stays testable and the provider can be swapped later.
abstract class AuthService {
  /// Prepares the underlying provider. Must be awaited once before signing in.
  ///
  /// Defaults to a no-op so fakes do not have to implement it.
  Future<void> initialize() async {}

  /// Emits the signed-in user, or null when signed out.
  Stream<User?> get authStateChanges;

  User? get currentUser;

  /// Signs in with Google and returns the resulting user.
  ///
  /// Throws [AuthFailure] for every expected failure mode.
  Future<User> signInWithGoogle();

  /// Signs in an existing Firebase user with email and password.
  ///
  /// The [role] parameter controls the domain gate: students must use a
  /// `@student.tce.edu` address; staff and admin may use any email.
  Future<User> signInWithEmailPassword(
    String email,
    String password, {
    AppRole role = AppRole.student,
  });

  /// Creates a Firebase user with email and password.
  Future<User> createAccountWithEmailPassword({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Returns the signed-in user's role from `users/{uid}`.
  ///
  /// Defaults to [AppRole.student] when no document exists so existing
  /// accounts keep working.
  Future<AppRole> currentRole();

  static bool isAllowedEmail(String? email, {AppRole role = AppRole.student}) {
    if (email == null || email.isEmpty) return false;
    // Staff and admin can use any email address.
    if (role != AppRole.student) return true;
    return email.toLowerCase().endsWith('@${AppConfig.allowedEmailDomain}');
  }
}

/// [AuthService] backed by Firebase Authentication + Google Sign-In.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  AuthFailure? _initializationFailure;
  bool _isInitialized = false;

  /// Prepares Google Sign-In. Must be awaited once before signing in.
  ///
  /// [GoogleSignIn.initialize] is required to be called exactly once, and
  /// `hostedDomain` makes the Google account chooser default to the TCE domain.
  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    if (_isInitialized) return;
    try {
      await _googleSignIn.initialize(
        clientId: AppConfig.webGoogleClientId.isEmpty
            ? null
            : AppConfig.webGoogleClientId,
      );
    } on Object {
      _initializationFailure = const AuthFailure(
        AuthFailureReason.misconfigured,
        'Google sign-in is not configured for this web app yet.',
      );
    } finally {
      _isInitialized = true;
    }
  }

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AppRole> currentRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AppRole.student;
    try {
      final doc = await _firestore
          .collection(AppConfig.usersCollection)
          .doc(uid)
          .get();
      return AppRole.fromName(doc.data()?['role']?.toString());
    } on Object {
      return AppRole.student;
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    await initialize();
    final initializationFailure = _initializationFailure;
    if (initializationFailure != null) throw initializationFailure;

    if (kIsWeb) {
      try {
        final credentialResult = await _auth.signInWithPopup(
          GoogleAuthProvider(),
        );
        final user = credentialResult.user;
        if (user == null) {
          throw const AuthFailure(
            AuthFailureReason.unknown,
            'Sign-in did not return an account. Please try again.',
          );
        }
        if (!AuthService.isAllowedEmail(user.email)) {
          await _auth.signOut();
          throw const AuthFailure(
            AuthFailureReason.unauthorizedDomain,
            'Only @student.tce.edu accounts can sign in.',
          );
        }
        return user;
      } on FirebaseAuthException catch (error) {
        throw _mapFirebaseAuthError(error);
      }
    }

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      throw _mapGoogleError(error);
    }

    try {
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final credentialResult = await _auth.signInWithCredential(credential);
      final user = credentialResult.user;
      if (user == null) {
        throw const AuthFailure(
          AuthFailureReason.unknown,
          'Sign-in did not return an account. Please try again.',
        );
      }
      if (!AuthService.isAllowedEmail(user.email)) {
        await _auth.signOut();
        throw const AuthFailure(
          AuthFailureReason.unauthorizedDomain,
          'Only @student.tce.edu accounts can sign in.',
        );
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthError(error);
    }
  }

  @override
  Future<User> signInWithEmailPassword(
    String email,
    String password, {
    AppRole role = AppRole.student,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!AuthService.isAllowedEmail(normalizedEmail, role: role)) {
      throw AuthFailure(
        AuthFailureReason.unauthorizedDomain,
        role == AppRole.student
            ? 'Only @student.tce.edu accounts can sign in.'
            : 'Enter a valid email address.',
      );
    }
    if (password.isEmpty) {
      throw const AuthFailure(
        AuthFailureReason.unknown,
        'Enter your password to continue.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          AuthFailureReason.unknown,
          'Sign-in did not return an account. Please try again.',
        );
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapEmailPasswordError(error);
    }
  }

  @override
  Future<User> createAccountWithEmailPassword({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!AuthService.isAllowedEmail(normalizedEmail)) {
      throw const AuthFailure(
        AuthFailureReason.unauthorizedDomain,
        'Only @student.tce.edu accounts can create an account.',
      );
    }
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        phoneNumber.trim().isEmpty) {
      throw const AuthFailure(
        AuthFailureReason.unknown,
        'Enter your first name, last name, and phone number.',
      );
    }
    if (password.length < 6) {
      throw const AuthFailure(
        AuthFailureReason.unknown,
        'Password must be at least 6 characters.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          AuthFailureReason.unknown,
          'Account creation did not return a user. Please try again.',
        );
      }
      await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
      await _firestore.collection(AppConfig.usersCollection).doc(user.uid).set({
        'email': normalizedEmail,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'role': AppRole.student.wireName,
      });
      if (!AuthService.isAllowedEmail(user.email)) {
        await _auth.signOut();
        throw const AuthFailure(
          AuthFailureReason.unauthorizedDomain,
          'Only @student.tce.edu accounts can sign in.',
        );
      }
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapEmailPasswordError(error, creatingAccount: true);
    } on FirebaseException {
      throw const AuthFailure(
        AuthFailureReason.network,
        'Account was created, but your profile could not be saved. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (error) {
      throw _mapGoogleError(error);
    }
  }

  AuthFailure _mapGoogleError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthFailure(
          AuthFailureReason.cancelled,
          'Sign-in was cancelled.',
        );
      case GoogleSignInExceptionCode.userMismatch:
        return const AuthFailure(
          AuthFailureReason.unknown,
          'Google sign-in failed. Please try again.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AuthFailure(
          AuthFailureReason.misconfigured,
          'Google sign-in is not configured for this app yet.',
        );
      case GoogleSignInExceptionCode.unknownError:
        return const AuthFailure(
          AuthFailureReason.network,
          'Cannot reach Google right now. Please try again.',
        );
    }
  }

  AuthFailure _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return const AuthFailure(
          AuthFailureReason.cancelled,
          'Sign-in was cancelled.',
        );
      case 'popup-blocked':
        return const AuthFailure(
          AuthFailureReason.misconfigured,
          'Allow pop-ups for this site to sign in with Google.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          AuthFailureReason.network,
          'Cannot reach Google right now. Please try again.',
        );
      case 'unauthorized-domain':
        return const AuthFailure(
          AuthFailureReason.misconfigured,
          'Add this website domain in Firebase Authentication settings.',
        );
      default:
        return AuthFailure(
          AuthFailureReason.unknown,
          'Sign-in failed. Please try again. (${error.code})',
        );
    }
  }

  AuthFailure _mapEmailPasswordError(
    FirebaseAuthException error, {
    bool creatingAccount = false,
  }) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return const AuthFailure(
          AuthFailureReason.unknown,
          'Email or password is incorrect.',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          AuthFailureReason.unknown,
          'An account already exists for this email. Sign in instead.',
        );
      case 'weak-password':
        return const AuthFailure(
          AuthFailureReason.unknown,
          'Choose a stronger password with at least 6 characters.',
        );
      case 'invalid-email':
        return const AuthFailure(
          AuthFailureReason.unknown,
          'Enter a valid email address.',
        );
      case 'user-disabled':
        return const AuthFailure(
          AuthFailureReason.unknown,
          'This account has been disabled. Contact the administrator.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          AuthFailureReason.network,
          'Too many attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          AuthFailureReason.network,
          'Cannot reach the server. Check your connection.',
        );
      default:
        return AuthFailure(
          AuthFailureReason.unknown,
          '${creatingAccount ? 'Account creation' : 'Email sign-in'} failed. '
          'Please try again. (${error.code})',
        );
    }
  }
}
