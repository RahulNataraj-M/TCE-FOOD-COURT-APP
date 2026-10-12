// `Order` from Cloud Firestore clashes with the app's `Order` model.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../config/app_config.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/local_database.dart';

/// Reads and writes the signed-in user's orders in Cloud Firestore, backed by a
/// local SQLite cache.
///
/// Orders are stored per user at `users/{uid}/orders/{docId}` so a user can
/// never read another student's orders, even before rules are in place. The
/// cache mirrors the last successful read so orders stay visible offline.
class OrderRepository {
  OrderRepository({this._firestore, this._authService, this._localDatabase});

  final FirebaseFirestore? _firestore;
  final AuthService? _authService;
  final LocalDatabase? _localDatabase;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String? get _uid => _authService?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _orders {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .collection(AppConfig.ordersCollection);
  }

  /// Stores [order] and returns it with its Firestore document id attached.
  ///
  /// The saved order is also written to the local cache. Throws [StateError]
  /// when there is no signed-in user and [FirebaseException] when the write
  /// fails.
  Future<Order> createOrder(Order order) async {
    final orders = _orders;
    final uid = _uid;
    if (orders == null || uid == null) {
      throw StateError('Cannot save an order without a signed-in user.');
    }

    final data = order.toMap();
    data['placedAt'] = Timestamp.fromDate(order.placedAt.toUtc());
    final doc = await orders.add(data);
    final saved = order.copyWith(docId: doc.id);
    await _localDatabase?.cacheOrder(saved, userId: uid);
    return saved;
  }

  /// Loads the user's orders, newest first. Returns an empty list when signed
  /// out.
  ///
  /// Falls back to the cached orders when the Firestore read fails; throws a
  /// [FirebaseException] only when there is no cache either.
  Future<List<Order>> fetchOrders() async {
    final orders = _orders;
    final uid = _uid;
    if (orders == null || uid == null) return const [];

    try {
      final snapshot = await orders.orderBy('placedAt', descending: true).get();
      final result = <Order>[];
      for (final doc in snapshot.docs) {
        final order = _fromDoc(doc);
        if (order != null) result.add(order);
      }
      await _localDatabase?.cacheOrders(result, userId: uid);
      return result;
    } on Object {
      final cached = await _localDatabase?.readOrders(uid) ?? const <Order>[];
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Updates the status of a persisted order, e.g. when it is cancelled.
  Future<Order> updateStatus(Order order, OrderStatus status) async {
    final orders = _orders;
    final docId = order.docId;
    if (orders == null || docId == null) {
      throw StateError('Cannot update an order that is not persisted.');
    }
    await orders.doc(docId).update({'status': status.name});
    await _localDatabase?.updateOrderStatus(docId, status);
    return order.copyWith(status: status);
  }

  Order? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final placedAt = _asDate(data['placedAt']) ?? DateTime.now();
    final total = _asInt(data['total']);
    final items = <OrderItem>[];
    final rawItems = data['items'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        items.add(
          OrderItem(
            name: map['name']?.toString() ?? '',
            quantity: _asInt(map['quantity']),
            unitPrice: _asInt(map['unitPrice']),
          ),
        );
      }
    }

    return Order(
      id: data['displayId']?.toString() ?? doc.id,
      docId: doc.id,
      items: items,
      total: total,
      placedAt: placedAt,
      status: Order.statusFromName(data['status']?.toString()),
    );
  }
}

DateTime? _asDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}