import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/app_role.dart';
import '../models/user_profile.dart';

/// Reads the `users` collection and updates user roles for the admin panel.
class UserRepository {
  UserRepository({this._firestore});

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Loads every user, sorted by name. Reads without an `orderBy` so documents
  /// missing optional fields are still returned.
  Future<List<UserProfile>> fetchUsers() async {
    final snapshot =
        await _db.collection(AppConfig.usersCollection).get();
    final users = [
      for (final doc in snapshot.docs) UserProfile.fromMap(doc.id, doc.data()),
    ];
    users.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return users;
  }

  /// Streams every user, sorted by name, so the admin panel stays in sync.
  Stream<List<UserProfile>> watchUsers() {
    return _db.collection(AppConfig.usersCollection).snapshots().map((snapshot) {
      final users = [
        for (final doc in snapshot.docs)
          UserProfile.fromMap(doc.id, doc.data()),
      ];
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    });
  }

  /// Updates a user's role.
  Future<void> updateRole(String uid, AppRole role) async {
    await _db
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .update({'role': role.wireName});
  }
}
