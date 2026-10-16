import 'app_role.dart';

/// A user document from the `users` collection, as seen by the admin panel.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final AppRole role;

  String get fullName => '$firstName $lastName'.trim();

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email']?.toString() ?? '',
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      role: AppRole.fromName(data['role']?.toString()),
    );
  }
}
