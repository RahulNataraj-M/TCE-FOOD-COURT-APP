/// App-wide Firebase configuration.
///
/// Keeping these values in one place avoids scattering collection names and the
/// allowed student domain through the UI code.
class AppConfig {
  AppConfig._();

  static const String allowedEmailDomain = 'student.tce.edu';

  /// Optional OAuth client id for Google Sign-In on web.
  ///
  /// Supply it with `--dart-define=GOOGLE_WEB_CLIENT_ID=...`.
  static const String webGoogleClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Firestore collection holding the food court menu.
  static const String menuCollection = 'menu_items';

  /// Firestore collection holding the per-user documents.
  static const String usersCollection = 'users';

  /// Sub-collection of `users/{uid}` holding that user's orders.
  static const String ordersCollection = 'orders';
}
