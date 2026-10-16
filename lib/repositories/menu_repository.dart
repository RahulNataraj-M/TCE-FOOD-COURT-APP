import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/app_config.dart';
import '../models/menu_item.dart';
import '../services/local_database.dart';

/// Reads and writes the food court menu in Cloud Firestore, backed by a local
/// SQLite cache.
///
/// The collection lives at `menu_items/{id}` with the fields of
/// [MenuItem.toMap]. `imageAsset` holds an asset path (for example
/// `assets/images/dosa.jpg`) so the existing `Image.asset` based widgets keep
/// working unchanged.
///
/// [fetchMenu] filters out unavailable items (for the student-facing screens);
/// [fetchAllMenu] returns everything including unavailable items (for the admin
/// panel). [createItem], [updateItem] and [deleteItem] are used by the admin
/// panel to manage the menu.
class MenuRepository {
  MenuRepository({this._firestore, this._localDatabase});

  final FirebaseFirestore? _firestore;
  final LocalDatabase? _localDatabase;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _menu =>
      _db.collection(AppConfig.menuCollection);

  /// Loads the menu ordered by name, excluding unavailable items.
  ///
  /// Used by the student-facing screens. Falls back to the cached menu when
  /// the Firestore read fails; throws a [FirebaseException] only when there is
  /// no cache either, so the caller can fall back to the bundled catalog.
  Future<List<MenuItem>> fetchMenu() async {
    try {
      final snapshot = await _menu.orderBy('name').get();

      final items = <MenuItem>[];
      for (final doc in snapshot.docs) {
        final item = MenuItem.fromMap(doc.data(), docId: doc.id);
        if (item.isValid && item.available) items.add(item);
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

  /// Loads every menu item ordered by name, including unavailable ones.
  ///
  /// Used by the admin panel. Throws a [FirebaseException] if the read fails.
  Future<List<MenuItem>> fetchAllMenu() async {
    final snapshot = await _menu.orderBy('name').get();
    final items = <MenuItem>[];
    for (final doc in snapshot.docs) {
      final item = MenuItem.fromMap(doc.data(), docId: doc.id);
      if (item.isValid) items.add(item);
    }
    return items;
  }

  /// Streams the available menu ordered by name, re-emitting whenever the
  /// `menu_items` collection changes. Used by the student-facing screens so
  /// admin edits show up without a manual refresh.
  Stream<List<MenuItem>> watchMenu() {
    return _menu.orderBy('name').snapshots().map((snapshot) {
      final items = <MenuItem>[];
      for (final doc in snapshot.docs) {
        final item = MenuItem.fromMap(doc.data(), docId: doc.id);
        if (item.isValid && item.available) items.add(item);
      }
      return items;
    });
  }

  /// Streams every menu item ordered by name, including unavailable ones.
  /// Used by the admin panel so its list stays in sync in real time.
  Stream<List<MenuItem>> watchAllMenu() {
    return _menu.orderBy('name').snapshots().map((snapshot) {
      final items = <MenuItem>[];
      for (final doc in snapshot.docs) {
        final item = MenuItem.fromMap(doc.data(), docId: doc.id);
        if (item.isValid) items.add(item);
      }
      return items;
    });
  }

  /// Creates a new menu item and returns it with its Firestore document id.
  Future<MenuItem> createItem(MenuItem item) async {
    final doc = await _menu.add(item.toMap());
    return item.copyWith(docId: doc.id);
  }

  /// Updates an existing menu item. The item must have a [MenuItem.docId].
  Future<MenuItem> updateItem(MenuItem item) async {
    final docId = item.docId;
    if (docId == null) {
      throw StateError('Cannot update a menu item without a document id.');
    }
    await _menu.doc(docId).update(item.toMap());
    return item;
  }

  /// Deletes a menu item by its Firestore document id.
  Future<void> deleteItem(String docId) async {
    await _menu.doc(docId).delete();
  }
}
