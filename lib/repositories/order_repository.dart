// `Order` from Cloud Firestore clashes with the app's `Order` model.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../config/app_config.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/local_database.dart';

/// Reads and writes orders in Cloud Firestore, backed by a local SQLite cache.
///
/// Orders live in a single top-level `orders` collection with a `userId` field
/// so food-court staff can query every order across all students. Students
/// only see their own orders (filtered by `userId`); staff see everything.
///
/// The cache mirrors the last successful read so orders stay visible offline.
class OrderRepository {
  OrderRepository({this._firestore, this._authService, this._localDatabase});

  final FirebaseFirestore? _firestore;
  final AuthService? _authService;
  final LocalDatabase? _localDatabase;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String? get _uid => _authService?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConfig.ordersCollection);

  /// Stores [order] and returns it with its Firestore document id attached.
  ///
  /// The signed-in user's uid and email are stamped onto the document so
  /// staff can identify who placed each order. Throws [StateError] when there
  /// is no signed-in user and [FirebaseException] when the write fails.
  Future<Order> createOrder(Order order) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot save an order without a signed-in user.');
    }
    final email = _authService?.currentUser?.email;

    final data = order.toMap();
    data['userId'] = uid;
    if (email != null) data['userEmail'] = email;
    data['placedAt'] = Timestamp.fromDate(order.placedAt.toUtc());
    final doc = await _orders.add(data);
    final saved = order.copyWith(
      docId: doc.id,
      userId: uid,
      userEmail: email,
    );
    await _localDatabase?.cacheOrder(saved, userId: uid);
    return saved;
  }

  /// Loads the signed-in user's orders, newest first. Returns an empty list
  /// when signed out.
  ///
  /// Falls back to the cached orders when the Firestore read fails; throws a
  /// [FirebaseException] only when there is no cache either.
  Future<List<Order>> fetchOrders() async {
    final uid = _uid;
    if (uid == null) return const [];

    try {
      final snapshot = await _orders
          .where('userId', isEqualTo: uid)
          .orderBy('placedAt', descending: true)
          .get();
      final result = _ordersFromSnapshot(snapshot);
      await _localDatabase?.cacheOrders(result, userId: uid);
      return result;
    } on Object {
      final cached = await _localDatabase?.readOrders(uid) ?? const <Order>[];
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Streams the signed-in user's orders, newest first, re-emitting whenever
  /// the `orders` collection changes. Emits an empty list when signed out.
  Stream<List<Order>> watchOrders() {
    final uid = _uid;
    if (uid == null) return Stream<List<Order>>.value(const []);
    return _orders
        .where('userId', isEqualTo: uid)
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map(_ordersFromSnapshot);
  }

  /// Loads every order across all users, newest first.
  ///
  /// Used by the staff dashboard to show the incoming-order queue. Throws a
  /// [FirebaseException] if the read fails.
  Future<List<Order>> fetchAllOrders() async {
    final snapshot = await _orders.orderBy('placedAt', descending: true).get();
    return _ordersFromSnapshot(snapshot);
  }

  /// Streams every order across all users, newest first, so the staff
  /// dashboard reflects newly placed orders in real time.
  Stream<List<Order>> watchAllOrders() {
    return _orders
        .orderBy('placedAt', descending: true)
        .snapshots()
        .map(_ordersFromSnapshot);
  }

  List<Order> _ordersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final result = <Order>[];
    for (final doc in snapshot.docs) {
      final order = _fromDoc(doc);
      if (order != null) result.add(order);
    }
    return result;
  }

  /// Updates the status of a persisted order, e.g. when it is cancelled.
  Future<Order> updateStatus(Order order, OrderStatus status) async {
    final docId = order.docId;
    if (docId == null) {
      throw StateError('Cannot update an order that is not persisted.');
    }
    await _orders.doc(docId).update({'status': status.name});
    final uid = order.userId ?? _uid;
    if (uid != null) {
      await _localDatabase?.updateOrderStatus(docId, status);
    }
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
      userId: data['userId']?.toString(),
      userEmail: data['userEmail']?.toString(),
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
