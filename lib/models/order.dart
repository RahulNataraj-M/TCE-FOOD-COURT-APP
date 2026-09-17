enum OrderStatus { placed, preparing, ready, completed, cancelled }

class OrderItem {
  final String name;
  final int quantity;
  final int unitPrice;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  int get total => unitPrice * quantity;
}

class Order {
  final String id;
  final List<OrderItem> items;
  final int total;
  final DateTime placedAt;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.placedAt,
    this.status = OrderStatus.placed,
  });

  int get itemSummary => items.fold(0, (sum, i) => sum + i.quantity);
}

class SampleOrders {
  SampleOrders._();

  static final Order activeOrder = Order(
    id: '#TCE1024',
    total: 120,
    placedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    status: OrderStatus.placed,
    items: const [
      OrderItem(name: 'Chicken Biriyani', quantity: 1, unitPrice: 100),
      OrderItem(name: 'Lime Juice', quantity: 1, unitPrice: 20),
    ],
  );

  static final List<Order> history = [
    Order(
      id: '#TCE1021',
      total: 80,
      placedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: OrderStatus.completed,
      items: const [
        OrderItem(name: 'Chicken Rice', quantity: 1, unitPrice: 80),
      ],
    ),
    Order(
      id: '#TCE1017',
      total: 100,
      placedAt: DateTime.now().subtract(const Duration(days: 5)),
      status: OrderStatus.completed,
      items: const [
        OrderItem(name: 'Veg Roll', quantity: 2, unitPrice: 50),
      ],
    ),
  ];
}