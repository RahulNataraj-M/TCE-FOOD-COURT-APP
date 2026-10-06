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

  List<Order> get orders => List.unmodifiable(_orders);

  bool get isLoading => _isLoading;

  /// True while the bundled sample orders are being shown.
  bool get isUsingSamples => _isUsingSamples;

  Object? get lastError => _lastError;

  /// The order the kitchen is currently working on, if any.
  Order? get activeOrder {
    for (final order in _orders) {
      if (order.isActive) return order;
    }
    return _isUsingSamples ? SampleOrders.activeOrder : null;
  }

  /// Completed and cancelled orders, newest first.
  List<Order> get history {
    final closed = _orders.where((order) => !order.isActive).toList();
    if (closed.isEmpty && _isUsingSamples) return SampleOrders.history;
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

  /// Cancels a stored order.
  Future<void> cancelOrder(Order order) async {
    await _repository.updateStatus(order, OrderStatus.cancelled);
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