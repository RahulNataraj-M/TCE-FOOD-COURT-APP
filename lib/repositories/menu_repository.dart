import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/menu_item.dart';
import '../services/local_database.dart';

/// Reads the food court menu from Cloud Firestore, backed by a local SQLite
/// cache.
///
/// The collection is expected to live at `menu_items/{id}` with the fields of
/// [MenuItem.toMap]. `imageAsset` keeps holding an asset path (for example
/// `assets/images/dosa.jpg`) so the existing `Image.asset` based widgets keep
/// working unchanged.
///
/// Every successful read refreshes the cache. When Firestore is unreachable the
/// last cached menu is served instead, so the app keeps working offline.
class MenuRepository {
  MenuRepository({this._firestore, this._localDatabase});

  final FirebaseFirestore? _firestore;
  final LocalDatabase? _localDatabase;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Loads the menu ordered by name.
  ///
  /// Documents without a usable name are skipped. Falls back to the cached menu
  /// when the Firestore read fails; throws a [FirebaseException] only when there
  /// is no cache either, so the caller can fall back to the bundled catalog.
  Future<List<MenuItem>> fetchMenu() async {
    try {
      final snapshot = await _db
          .collection(AppConfig.menuCollection)
          .orderBy('name')
          .get();

      final items = <MenuItem>[];
      for (final doc in snapshot.docs) {
        final item = MenuItem.fromMap(doc.data());
        if (item.isValid) items.add(item);
      }
      if (items.isNotEmpty) {
        await _localDatabase?.cacheMenu(items);
      }
      return items;
    } on Object {
      final cached = await _localDatabase?.readMenu() ?? const <MenuItem>[];
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}