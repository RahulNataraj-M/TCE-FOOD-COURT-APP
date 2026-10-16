import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/menu_item.dart';
import '../models/order.dart';

/// SQLite-backed local cache for the menu and the signed-in user's orders.
///
/// Cloud Firestore stays the source of truth. This store mirrors what was last
/// read from the server so the app can start instantly and keep showing data
/// while offline. It is a best-effort cache: every public method swallows
/// storage errors and behaves as if nothing was cached, so a missing or broken
/// database can never take the UI down.
///
/// Web has no sqflite implementation, so the cache quietly stays off there.
class LocalDatabase {
  LocalDatabase({this._factory, this._path});

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;

  /// Set once opening fails so a missing platform implementation is not retried
  /// on every call.
  bool _unavailable = false;

  static const String _databaseName = 'tce_foodcourt.db';
  static const int _schemaVersion = 2;

  DatabaseFactory get _databaseFactory => _factory ?? databaseFactory;

  /// Whether a real SQLite database is available on the current platform.
  bool get isSupported => !kIsWeb && !_unavailable;

  Future<Database?> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    if (!isSupported) return null;

    try {
      final dbPath =
          _path ?? path.join(await _databaseFactory.getDatabasesPath(), _databaseName);
      final db = await _databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema,
        ),
      );
      _db = db;
      return db;
    } on Object catch (error) {
      debugPrint('LocalDatabase disabled: $error');
      _unavailable = true;
      return null;
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE menu_items (
        name TEXT PRIMARY KEY,
        description TEXT NOT NULL DEFAULT '',
        price INTEGER NOT NULL DEFAULT 0,
        imageAsset TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT '',
        rating REAL NOT NULL DEFAULT 0,
        timesOrdered INTEGER NOT NULL DEFAULT 0,
        available INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('''
      CREATE TABLE orders (
        docId TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        displayId TEXT NOT NULL,
        total INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        placedAt INTEGER NOT NULL,
        items TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX orders_user_idx ON orders (userId, placedAt DESC)',
    );
    await batch.commit(noResult: true);
  }

  Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    // The cache can always be rebuilt from Firestore, so a schema change simply
    // clears the old data instead of migrating it.
    await db.transaction((txn) async {
      await txn.delete('menu_items');
      await txn.delete('orders');
    });
  }

  /// Replaces the cached menu with [items].
  Future<void> cacheMenu(List<MenuItem> items) async {
    final db = await _open();
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        await txn.delete('menu_items');
        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
            'menu_items',
            _menuRow(item),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } on Object catch (error) {
      debugPrint('Failed to cache the menu: $error');
    }
  }

  /// Reads the cached menu, ordered by name. Empty when nothing is cached.
  Future<List<MenuItem>> readMenu() async {
    final db = await _open();
    if (db == null) return const [];

    try {
      final rows = await db.query('menu_items', orderBy: 'name');
      return [for (final row in rows) MenuItem.fromMap(row)];
    } on Object catch (error) {
      debugPrint('Failed to read the cached menu: $error');
      return const [];
    }
  }

  /// Replaces [userId]'s cached orders with [orders].
  Future<void> cacheOrders(Iterable<Order> orders, {required String userId}) async {
    final db = await _open();
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        await txn.delete('orders', where: 'userId = ?', whereArgs: [userId]);
        final batch = txn.batch();
        for (final order in orders) {
          if (order.docId == null) continue;
          batch.insert(
            'orders',
            _orderRow(order, userId),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } on Object catch (error) {
      debugPrint('Failed to cache orders: $error');
    }
  }

  /// Inserts or replaces a single cached order for [userId].
  Future<void> cacheOrder(Order order, {required String userId}) async {
    final db = await _open();
    final docId = order.docId;
    if (db == null || docId == null) return;

    try {
      await db.insert(
        'orders',
        _orderRow(order, userId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Object catch (error) {
      debugPrint('Failed to cache an order: $error');
    }
  }

  /// Reads [userId]'s cached orders, newest first.
  Future<List<Order>> readOrders(String userId) async {
    final db = await _open();
    if (db == null) return const [];

    try {
      final rows = await db.query(
        'orders',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'placedAt DESC',
      );
      return [for (final row in rows) _orderFromRow(row)];
    } on Object catch (error) {
      debugPrint('Failed to read cached orders: $error');
      return const [];
    }
  }

  /// Updates the cached status of the order with [docId].
  Future<void> updateOrderStatus(String docId, OrderStatus status) async {
    final db = await _open();
    if (db == null) return;

    try {
      await db.update(
        'orders',
        {'status': status.name},
        where: 'docId = ?',
        whereArgs: [docId],
      );
    } on Object catch (error) {
      debugPrint('Failed to update the cached order: $error');
    }
  }

  /// Closes the underlying connection, if one is open.
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
  Map<String, Object?> _menuRow(MenuItem item) {
    return {
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'imageAsset': item.imageAsset,
      'category': item.category,
      'rating': item.rating,
      'timesOrdered': item.timesOrdered,
      'available': item.available ? 1 : 0,
    };
  }

  Map<String, Object?> _orderRow(Order order, String userId) {
    return {
      'docId': order.docId,
      'userId': userId,
      'displayId': order.id,
      'total': order.total,
      'status': order.status.name,
      'placedAt': order.placedAt.toUtc().millisecondsSinceEpoch,
      'items': jsonEncode([
        for (final item in order.items)
          {
            'name': item.name,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
          },
      ]),
    };
  }

  Order _orderFromRow(Map<String, Object?> row) {
    final items = <OrderItem>[];
    final raw = row['items'];
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final entry in decoded) {
          if (entry is! Map) continue;
          items.add(
            OrderItem(
              name: entry['name']?.toString() ?? '',
              quantity: _asInt(entry['quantity']),
              unitPrice: _asInt(entry['unitPrice']),
            ),
          );
        }
      }
    }

    final docId = row['docId']?.toString();
    return Order(
      id: row['displayId']?.toString() ?? docId ?? '',
      docId: docId,
      items: items,
      total: _asInt(row['total']),
      placedAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(row['placedAt']),
        isUtc: true,
      ).toLocal(),
      status: Order.statusFromName(row['status']?.toString()),
    );
  }
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
