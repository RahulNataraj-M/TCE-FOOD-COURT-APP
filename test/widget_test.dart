import 'package:flutter_test/flutter_test.dart';

import 'package:tce_foodcourt_app/controllers/cart_controller.dart';
import 'package:tce_foodcourt_app/main.dart';
import 'package:tce_foodcourt_app/models/menu_item.dart';

void main() {
  setUp(() {
    CartController.instance.clear();
  });

  testWidgets('Full ordering flow works end to end', (tester) async {
    await tester.pumpWidget(const TceFoodCourtApp());

    // Login screen
    expect(find.text('TCE Food Court'), findsOneWidget);

    // Continue with Google -> Home
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('What are you hungry for?'), findsOneWidget);
    expect(find.text('Most Ordered'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    // Go to the menu (Order Food)
    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();

    expect(find.text('Search food...'), findsOneWidget);
    expect(find.text('Chicken Biriyani'), findsOneWidget);

    // Add Chicken Biriyani to cart
    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();

    expect(CartController.instance.itemCount, 1);

    // Open cart via the floating bar
    await tester.tap(find.text('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Your Cart'), findsOneWidget);
    expect(find.text('Chicken Biriyani'), findsOneWidget);
    expect(find.text('₹150'), findsWidgets);

    // Proceed to payment
    await tester.tap(find.text('Proceed to Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Methods'), findsOneWidget);

    // Complete payment
    await tester.tap(find.text('Pay ₹150'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Successful'), findsOneWidget);
    expect(find.text('#TCE1024'), findsOneWidget);

    // Cart should be cleared after successful payment
    expect(CartController.instance.itemCount, 0);

    // View Order -> Orders tab
    await tester.tap(find.text('View Order'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Active Order'), findsOneWidget);
  });

  test('Cart item totals are computed correctly', () {
    const item = MenuItem(
      name: 'Test',
      description: '',
      price: 100,
      imageAsset: '',
      category: '',
    );
    final cartItem = CartItem(item: item, quantity: 3);
    expect(cartItem.total, 300);
  });
}