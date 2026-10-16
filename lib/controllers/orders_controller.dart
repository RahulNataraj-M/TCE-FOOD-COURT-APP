import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../services/auth_service.dart';

/// Holds the signed-in user's orders.
///
/// Falls back to [SampleOrders] while the user has no stored orders so the
/// orders screen keeps its current content. Every Firebase failure is caught and
/// recorded in [lastError] rather than thrown, except [placeOrder], which lets
/// the caller react to a failed checkout.
class OrdersController extends ChangeNotifier {
  OrdersController({
    required this._repository,
    required this._authService,
  }) {
    _authSubscription = _authService.authStateChanges.listen((_) {
      unawaited(load());
    });
  }

  final OrderRepository _repository;
  final AuthService _authService;
  /// Assigned in the constructor body, which `final` fields do not allow.
  late final StreamSubscription<User?> _authSubscription;
  List<Order> _orders = const [];
  bool _isLoading = false;
  bool _isUsingSamples = true;
  Object? _lastError;

  /// Orders cancelled on this device that were never persisted (the bundled
  /// sample order). Lets a cancellation stick even without a Firestore record.
  final Set<String> _cancelledIds = <String>{};

  List<Order> get orders => List.unmodifiable(_orders);

  bool get isLoading => _isLoading;

  /// True while the bundled sample orders are being shown.
  bool get isUsingSamples => _isUsingSamples;

  Object? get lastError => _lastError;

  /// The order the kitchen is currently working on, if any.
  Order? get activeOrder {
    for (final order in _orders) {
      if (order.isActive && !_cancelledIds.contains(order.id)) return order;
    }
    if (!_isUsingSamples) return null;
    final sample = SampleOrders.activeOrder;
    if (_cancelledIds.contains(sample.id)) return null;
    return sample;
  }

  /// Completed and cancelled orders, newest first.
  List<Order> get history {
    final closed = _orders.where((order) => !order.isActive).toList();
    if (closed.isEmpty && _isUsingSamples) {
      return [
        if (_cancelledIds.contains(SampleOrders.activeOrder.id))
          SampleOrders.activeOrder.copyWith(status: OrderStatus.cancelled),
        ...SampleOrders.history,
      ];
    }
    return closed;
  }

  /// Saves [order] to Firestore and refreshes the list.
  ///
  /// Rethrows whatever the repository throws so the checkout flow can tell the
  /// user that the order was not saved.
  Future<Order> placeOrder(Order order) async {
    final saved = await _repository.createOrder(order);
    await load();
    return saved;
  }

  /// Cancels an order.
  ///
  /// Persisted orders are marked [OrderStatus.cancelled] in Firestore and the
  /// cached list is refreshed. Orders without a document id (the bundled
  /// sample order shown while the account has no stored orders) are cancelled
  /// in memory so they disappear from the active order immediately.
  ///
  /// Rethrows any persistence failure so the caller can tell the user, undoing
  /// the in-memory cancellation so the order stays visible.
  Future<void> cancelOrder(Order order) async {
    _cancelledIds.add(order.id);
    if (order.docId == null) {
      notifyListeners();
      return;
    }
    try {
      await _repository.updateStatus(order, OrderStatus.cancelled);
    } on Object {
      _cancelledIds.remove(order.id);
      rethrow;
    }
    await load();
  }

  /// Reloads the user's orders from Firestore.
  Future<void> load() async {
    if (_authService.currentUser == null) {
      _orders = const [];
      _isUsingSamples = true;
      _lastError = null;
      notifyListeners();
      return;
    }

    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await _repository.fetchOrders();
      _orders = remote;
      _isUsingSamples = remote.isEmpty;
      _lastError = null;
    } on Object catch (error) {
      _lastError = error;
      _orders = const [];
      _isUsingSamples = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}