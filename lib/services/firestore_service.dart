import 'package:cloud_firestore/cloud_firestore.dart';

/// Provides the application's Cloud Firestore connection.
///
/// Firebase must be initialized before this service is created. In production
/// it uses the default Firestore instance; tests can provide a fake instance.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// The active Cloud Firestore connection.
  FirebaseFirestore get instance => _firestore;

  /// Returns a typed top-level collection from the active connection.
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }
}
