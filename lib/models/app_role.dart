/// The three access levels in the food court app.
///
/// The role is stored as a string on the `users/{uid}` Firestore document and
/// drives routing in [AuthGate] plus the Firestore security rules.
enum AppRole {
  /// A student who browses the menu and places orders.
  student('student', 'Student'),

  /// Food-court staff who see incoming orders and update their status.
  staff('staff', 'Food Court Staff'),

  /// An administrator who manages menu items and user roles.
  admin('admin', 'Administrator');

  const AppRole(this.wireName, this.label);

  /// The value persisted in Firestore.
  final String wireName;

  /// Human-readable name shown in the UI.
  final String label;

  /// Parses a Firestore role string, defaulting to [AppRole.student] for
  /// null, empty, or unrecognised values so existing accounts keep working.
  static AppRole fromName(String? value) {
    for (final role in AppRole.values) {
      if (role.wireName == value) return role;
    }
    return AppRole.student;
  }
}
