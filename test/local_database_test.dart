import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:tce_foodcourt_app/models/menu_item.dart';
import 'package:tce_foodcourt_app/models/order.dart';
import 'package:tce_foodcourt_app/services/local_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  LocalDatabase openDatabase() => LocalDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );

  test('menu cache round-trips items', () async {
    final db = openDatabase();
    addTearDown(db.close);

    await db.cacheMenu(const [
      MenuItem(
        name: 'Vada',
        description: 'Crispy lentil fritter',
        price: 25,
        imageAsset: 'assets/images/veg_rice_bowl.jpg',
        category: 'Snacks',
        rating: 4.4,
        timesOrdered: 12,
      ),
    ]);

    final menu = await db.readMenu();
    expect(menu, hasLength(1));
    expect(menu.single.name, 'Vada');
    expect(menu.single.price, 25);
    expect(menu.single.timesOrdered, 12);
  });

  test('order cache persists items and status updates', () async {
    final db = openDatabase();
    addTearDown(db.close);

    final order = Order(
      id: '#TCE1042',
      docId: 'order-1',
      total: 150,
      placedAt: DateTime.parse('2026-01-02T03:04:05Z'),
      items: const [
        OrderItem(name: 'Chicken Biriyani', quantity: 1, unitPrice: 150),
      ],
    );

    await db.cacheOrder(order, userId: 'uid-1');
    final stored = await db.readOrders('uid-1');
    expect(stored, hasLength(1));
    expect(stored.single.id, '#TCE1042');
    expect(stored.single.total, 150);
    expect(stored.single.items.single.name, 'Chicken Biriyani');
    expect(stored.single.status, OrderStatus.placed);

    await db.updateOrderStatus('order-1', OrderStatus.cancelled);
    final updated = await db.readOrders('uid-1');
    expect(updated.single.status, OrderStatus.cancelled);
  });

  test('orders are stored per user', () async {
    final db = openDatabase();
    addTearDown(db.close);

    final order = Order(
      id: '#TCE1043',
      docId: 'order-2',
      total: 60,
      placedAt: DateTime.now(),
      items: const [OrderItem(name: 'Veg Rice', quantity: 1, unitPrice: 60)],
    );

    await db.cacheOrder(order, userId: 'uid-1');
    expect(await db.readOrders('uid-2'), isEmpty);
    expect(await db.readOrders('uid-1'), hasLength(1));
  });
}
