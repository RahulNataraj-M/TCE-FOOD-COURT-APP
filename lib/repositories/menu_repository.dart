import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/menu_item.dart';

/// Reads the food court menu from Cloud Firestore.
///
/// The collection is expected to live at `menu_items/{id}` with the fields of
/// [MenuItem.toMap]. `imageAsset` keeps holding an asset path (for example
/// `assets/images/dosa.jpg`) so the existing `Image.asset` based widgets keep
/// working unchanged.
class MenuRepository {
  MenuRepository({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Loads the menu ordered by name.
  ///
  /// Documents without a usable name are skipped. Throws a
  /// [FirebaseException] when the read fails so the caller can fall back to the
  /// bundled catalog.
  Future<List<MenuItem>> fetchMenu() async {
    final snapshot = await _db
        .collection(AppConfig.menuCollection)
        .orderBy('name')
        .get();

    final items = <MenuItem>[];
    for (final doc in snapshot.docs) {
      final item = MenuItem.fromMap(doc.data());
      if (item.isValid) items.add(item);
    }
    return items;
  }
}