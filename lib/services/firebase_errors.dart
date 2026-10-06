import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

/// Turns Firebase exceptions into copy that is safe to show in the UI.
///
/// Firebase error messages are written for developers and can leak internal
/// details (project ids, rules internals), so the app never surfaces them
/// verbatim.
class FirebaseErrors {
  FirebaseErrors._();

  /// Describes any error thrown by a Firebase call.
  static String describe(Object error) {
    if (error is FirebaseException) return _describeFirestore(error);
    if (error is FirebaseAuthException) return _describeAuth(error);
    return 'Something went wrong. Please try again.';
  }

  static String _describeFirestore(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have access to this data.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Cannot reach the server. Check your connection.';
      case 'unauthenticated':
        return 'Your session expired. Please sign in again.';
      case 'failed-precondition':
      case 'unimplemented':
        return 'This feature is not available yet.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _describeAuth(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return 'Cannot reach the server. Check your connection.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'user-cancelled':
        return 'Sign-in was cancelled.';
      case 'account-exists-with-different-credential':
        return 'This account is already registered with another sign-in method.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}