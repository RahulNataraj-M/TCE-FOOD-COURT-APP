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

  /// Firestore document id, or null for orders that are not persisted yet.
  final String? docId;
  final List<OrderItem> items;
  final int total;
  final DateTime placedAt;
  final OrderStatus status;

  /// The uid of the student who placed the order.
  final String? userId;

  /// The email of the student who placed the order.
  final String? userEmail;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.placedAt,
    this.status = OrderStatus.placed,
    this.docId,
    this.userId,
    this.userEmail,
  });

  int get itemSummary => items.fold(0, (sum, i) => sum + i.quantity);

  /// Whether the order is still being worked on by the kitchen.
  bool get isActive =>
      status == OrderStatus.placed ||
      status == OrderStatus.preparing ||
      status == OrderStatus.ready;

  Order copyWith({
    OrderStatus? status,
    String? docId,
    String? userId,
    String? userEmail,
  }) {
    return Order(
      id: id,
      items: items,
      total: total,
      placedAt: placedAt,
      status: status ?? this.status,
      docId: docId ?? this.docId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  /// Document fields, minus the Firestore specific timestamp conversion that
  /// the repository applies.
  Map<String, dynamic> toMap() {
    return {
      'displayId': id,
      'total': total,
      'status': status.name,
      'placedAt': placedAt.toUtc(),
      if (userId != null) 'userId': userId,
      if (userEmail != null) 'userEmail': userEmail,
      'items': [
        for (final item in items)
          {
            'name': item.name,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
          },
      ],
    };
  }

  /// Generates the customer-facing order number, e.g. `#TCE1042`.
  static String generateDisplayId() {
    final suffix =
        1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    return '#TCE$suffix';
  }

  /// Reads [OrderStatus.name] back, defaulting to [OrderStatus.placed] for
  /// unknown or missing values.
  static OrderStatus statusFromName(String? value) {
    for (final status in OrderStatus.values) {
      if (status.name == value) return status;
    }
    return OrderStatus.placed;
  }
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