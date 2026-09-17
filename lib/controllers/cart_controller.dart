import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  int get subtotal => _items.fold(0, (sum, i) => sum + i.total);

  int get total => subtotal;

  void add(MenuItem item, {int quantity = 1}) {
    final existing =
        _items.where((c) => c.item.name == item.name).firstOrNull;
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items.add(CartItem(item: item, quantity: quantity));
    }
    notifyListeners();
  }

  void increment(MenuItem item) => add(item);

  void decrement(MenuItem item) {
    final existing =
        _items.where((c) => c.item.name == item.name).firstOrNull;
    if (existing == null) return;
    existing.quantity -= 1;
    if (existing.quantity <= 0) {
      _items.remove(existing);
    }
    notifyListeners();
  }

  void removeItem(MenuItem item) {
    _items.removeWhere((c) => c.item.name == item.name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}